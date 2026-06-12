// frontend/entry/src/main/ets/features/climate/ControlPage.ets
import hilog from '@ohos.hilog';
import { DeviceManager } from '../../core/DeviceManager';
import { DeviceType, DeviceAction } from '../../core/adapter/DeviceConstants';
import { DeviceCommand } from '../../core/adapter/CommandModel';
import { AiDecisionEngine, AiCommand } from '../ai/AiDecisionEngine';

// ==========================================
// 独立响应式组件区
// ==========================================
@Component
struct SubControlBtn {
  @Prop label: string;
  @Prop isActive: boolean;
  @Prop activeColor: string;
  onClickAction: () => void = () => {};

  hexToRgb(hex: string): string {
    let r = parseInt(hex.slice(1, 3), 16);
    let g = parseInt(hex.slice(3, 5), 16);
    let b = parseInt(hex.slice(5, 7), 16);
    return `${r}, ${g}, ${b}`;
  }

  build() {
    Text(this.label)
      .fontSize(10).fontWeight(FontWeight.Bold)
      .fontColor(this.isActive ? this.activeColor : '#666')
      .padding({ top: 6, bottom: 6, left: 12, right: 12 })
      .backgroundColor(this.isActive ? `rgba(${this.hexToRgb(this.activeColor)}, 0.1)` : 'rgba(255,255,255,0.02)')
      .borderRadius(12).border({ width: 1, color: this.isActive ? this.activeColor : 'rgba(255,255,255,0.05)' })
      .animation({ duration: 300, curve: Curve.EaseInOut })
      .onClick(() => this.onClickAction())
  }
}

@Component
struct SceneCard {
  @Prop title: string;
  @Prop desc: string;
  @Prop glowColor: string;
  @Prop active: boolean;
  onClickAction: () => void = () => {};

  build() {
    Row() {
      Column() {
        Text(this.title).fontSize(15).fontWeight(FontWeight.Bold).fontColor(this.active ? this.glowColor : '#FFF')
          .animation({ duration: 300 })
        Text(this.desc).fontSize(10).fontColor('#8899AA').margin({ top: 4 })
      }.alignItems(HorizontalAlign.Start).layoutWeight(1)

      Toggle({ type: ToggleType.Switch, isOn: this.active })
        .selectedColor(this.glowColor)
        .hitTestBehavior(HitTestMode.Block)
    }
    .layoutWeight(1).padding(16).backgroundColor('rgba(255,255,255,0.02)')
    .borderRadius(12).border({ width: 1, color: this.active ? this.glowColor : 'rgba(255,255,255,0.05)' })
    .animation({ duration: 300, curve: Curve.EaseInOut })
    .onClick(() => this.onClickAction())
  }
}

@Component
struct DeviceToggle {
  @Prop name: string;
  @Prop desc: string;
  @Prop isOn: boolean;
  @Prop color: string;
  toggleAction: (val: boolean) => void = () => {};

  build() {
    Row() {
      Row({ space: 12 }) {
        Circle({ width: 6, height: 6 }).fill(this.isOn ? this.color : '#555').shadow({ radius: this.isOn ? 8 : 0, color: this.color })
          .animation({ duration: 300, curve: Curve.EaseInOut })
        Column() {
          Text(this.name).fontSize(14).fontWeight(FontWeight.Bold).fontColor('#FFF')
          Text(this.desc).fontSize(10).fontColor('#667788').margin({ top: 2 })
        }.alignItems(HorizontalAlign.Start)
      }
      Blank()
      Toggle({ type: ToggleType.Switch, isOn: this.isOn })
        .selectedColor(this.color)
        .onChange((val: boolean) => this.toggleAction(val))
    }.width('100%').padding({ top: 8, bottom: 8 })
  }
}

// 🌟 新增：人机协同授权弹窗
@CustomDialog
export struct AiConfirmDialog {
  controller: CustomDialogController;
  strategyList: AiCommand[] = [];
  onConfirm: () => void = () => {};

  build() {
    Column() {
      Text('🧠 AI 智能场景决策')
        .fontSize(20).fontWeight(FontWeight.Bold).fontColor('#333').margin({ bottom: 15 })

      ForEach(this.strategyList, (item: AiCommand) => {
        Row() {
          Text(`设备: ${item.device} `).fontColor('#666').fontSize(16)
          Text(`动作: ${item.action} -> ${item.value}`).fontColor('#00E5FF').fontSize(16).fontWeight(FontWeight.Medium)
        }.width('100%').margin({ bottom: 10 }).padding({ left: 10, right: 10 })
      }, (item: AiCommand, index: number) => index.toString())

      Row({ space: 20 }) {
        Button('取消忽略')
          .backgroundColor('#F5F5F5').fontColor('#333').layoutWeight(1)
          .onClick(() => { this.controller.close() })

        Button('授权执行')
          .backgroundColor('#00E5FF').fontColor(Color.White).layoutWeight(1)
          .onClick(() => {
            this.onConfirm();
            this.controller.close();
          })
      }.margin({ top: 20 }).width('100%')
    }
    .padding(24).backgroundColor(Color.White).borderRadius(16)
  }
}

// ==========================================
// 主页面容器
// ==========================================
@Component
export struct ControlPage {
  @StorageLink('global_acTemp') targetTemp: number = 24;
  @StorageLink('global_realTemp') currentTemp: string = '26.0';
  @StorageLink('global_realHum') currentHum: string = '45.0';
  @StorageLink('global_isAcOn') isAcOn: boolean = false;
  @StorageLink('global_acMode') acMode: number = 0;
  @State fanSpeed: string = 'AUTO';
  @State activeScene: string = '回家模式';
  @StorageLink('global_isMainLightOn') isMainLightOn: boolean = false;
  @StorageLink('global_isDoorLocked') isDoorLocked: boolean = true;
  @StorageLink('global_isAutoAcOn') isAutoAcOn: boolean = false;

  // 🌟 AI 状态与弹窗控制器
  @State currentAiStrategy: AiCommand[] = [];
  @State isAiLoading: boolean = false;
  // 🌟 新增：绑定用户真实输入的变量
  @State userInputIntent: string = '';
  @State currentAcBrand: number = 0; // 0:通用, 1:海尔, 2:格力, 3:美的

  // 🌟 修改：强化兼容性的UI更新逻辑
  dialogController: CustomDialogController = new CustomDialogController({
    builder: AiConfirmDialog({
      strategyList: this.currentAiStrategy,
      onConfirm: () => {
        this.currentAiStrategy.forEach((strategy: AiCommand) => {
          // 1. 下发给底层设备总线
          let cmd = new DeviceCommand(strategy.device as DeviceType, strategy.action as DeviceAction, strategy.value);
          DeviceManager.getInstance().sendCommand(cmd);

          // 2. 防御性UI状态更新：兼容大模型的各种拼写习惯
          let act = strategy.action.toLowerCase();
          let val = strategy.value;
          let isTurnOn = (val === true || val === 'true' || val === 1 || val === 'on');

          if(strategy.device === 'ac') {
            if(act === 'power' || act === 'switch') {
              this.isAcOn = isTurnOn;
            }
            if(act === 'temperature' || act === 'temp') {
              this.targetTemp = Number(val);
            }
          }
          if(strategy.device === 'light') {
            if(act === 'power' || act === 'switch') {
              this.isMainLightOn = isTurnOn;
            }
          }
        });
      }
    }),
    autoCancel: false,
    alignment: DialogAlignment.Center
  });

  async triggerAiAssistant(intent: string) {
    this.isAiLoading = true;
    let temp = parseFloat(this.currentTemp);
    let hum = parseFloat(this.currentHum);

    let strategy = await AiDecisionEngine.requestStrategy(intent, temp, hum);
    this.isAiLoading = false;

    if (strategy && strategy.length > 0) {
      this.currentAiStrategy = strategy;
      this.dialogController.open();
    }
  }

  build() {
    Column() {
      Blank()

      Column({ space: 24 }) {
        Row() {
          Text('分布式硬件指令中枢').fontSize(24).fontWeight(FontWeight.Bold).fontColor('#FFF')
          Blank()
          Text('Protocol: Universal_V2').fontColor('#A0AAB5').fontSize(12).fontFamily('monospace')
        }.width('100%')

        Row({ space: 24 }) {
          Column() {
            // 🌟核心替换部分：将原本单独的Text替换为包含Select下拉框的Row
            Row() {
              Text('HVAC Climate Control').fontSize(12).fontColor('#00E5FF').letterSpacing(2)
              Blank()
              Select([{ value: '默认通用' }, { value: '海尔' }, { value: '格力' }, { value: '美的' }])
                .selected(this.currentAcBrand)
                .value('品牌:默认')
                .font({ size: 12, weight: 500 })
                .fontColor('#00E5FF')
                .selectedOptionFont({ size: 12, weight: 400 })
                .optionFont({ size: 12, weight: 400 })
                .backgroundColor('rgba(0, 229, 255, 0.1)')
                .borderRadius(8)
                .onSelect((index: number, value: string) => {
                  this.currentAcBrand = index;
                  // 向下层发送解耦的配置指令
                  DeviceManager.getInstance().sendCommand(new DeviceCommand(DeviceType.AC, 'brand' as DeviceAction, index));
                })
            }.width('100%').margin({ bottom: 20 })

            Stack() {
              Circle({ width: 200, height: 200 }).fill('transparent').stroke('rgba(0, 229, 255, 0.1)').strokeWidth(1)
              Circle({ width: 180, height: 180 }).fill('rgba(0,0,0,0.6)')
                .shadow({ radius: this.isAcOn ? 80 : 0, color: this.isAcOn ? 'rgba(0, 229, 255, 0.4)' : 'transparent' })
                .animation({ duration: 600, curve: Curve.FastOutSlowIn })

              Column() {
                Text('TARGET').fontSize(10).fontColor('#666')
                Text(`${this.targetTemp}℃`).fontSize(48).fontWeight(FontWeight.Bolder).fontColor(this.isAcOn ? '#00E5FF' : '#555').margin({ top: 4, bottom: 4 })
                  .animation({ duration: 400, curve: Curve.EaseInOut })
                Text(this.isAcOn ? `MODE: ${this.acMode === 0 ? 'COOL' : this.acMode === 1 ? 'HEAT' : 'DRY'}` : 'OFFLINE').fontSize(10).fontColor(this.isAcOn ? '#00FF00' : '#FF1744')
                  .animation({ duration: 400 })
              }
            }.margin({ bottom: 20 })

            Row({ space: 24 }) {
              Column({ space: 4 }) { Text('CURRENT').fontSize(10).fontColor('#666'); Text(`${this.currentTemp}℃`).fontSize(16).fontColor('#FFF').fontWeight(FontWeight.Bold) }.alignItems(HorizontalAlign.Center)
              Column({ space: 4 }) { Text('HUMIDITY').fontSize(10).fontColor('#666'); Text(`${this.currentHum}%`).fontSize(16).fontColor('#FFF').fontWeight(FontWeight.Bold) }.alignItems(HorizontalAlign.Center)
            }.margin({ bottom: 24 })

            Row({ space: 16 }) {
              Button('-').width(50).height(50).fontSize(20).backgroundColor('rgba(255,255,255,0.05)').fontColor('#FFF')
                .onClick(() => {
                  if(this.isAcOn) {
                    animateTo({ duration: 300, curve: Curve.EaseInOut }, () => { this.targetTemp -= 1; });
                    DeviceManager.getInstance().sendCommand(new DeviceCommand(DeviceType.AC, DeviceAction.TEMPERATURE, this.targetTemp));
                  }
                })
              Button(this.isAcOn ? 'POWER OFF' : 'POWER ON').width(110).height(50).fontSize(14).fontWeight(FontWeight.Bold)
                .backgroundColor(this.isAcOn ? '#FF1744' : '#1976D2')
                .animation({ duration: 600, curve: Curve.EaseOut })
                .onClick(() => {
                  animateTo({ duration: 600, curve: Curve.FastOutSlowIn }, () => { this.isAcOn = !this.isAcOn; });
                  DeviceManager.getInstance().sendCommand(new DeviceCommand(DeviceType.AC, DeviceAction.POWER, this.isAcOn));
                })
              Button('+').width(50).height(50).fontSize(20).backgroundColor('rgba(255,255,255,0.05)').fontColor('#FFF')
                .onClick(() => {
                  if(this.isAcOn) {
                    animateTo({ duration: 300, curve: Curve.EaseInOut }, () => { this.targetTemp += 1; });
                    DeviceManager.getInstance().sendCommand(new DeviceCommand(DeviceType.AC, DeviceAction.TEMPERATURE, this.targetTemp));
                  }
                })
            }.margin({ bottom: 20 })

            Row({ space: 12 }) {
              SubControlBtn({ label: 'COOL', isActive: this.acMode === 0 && this.isAcOn, activeColor: '#00E5FF', onClickAction: () => {
                if(this.isAcOn) { animateTo({duration:300}, () => this.acMode = 0); DeviceManager.getInstance().sendCommand(new DeviceCommand(DeviceType.AC, DeviceAction.MODE, 0)); }
              }})
              SubControlBtn({ label: 'HEAT', isActive: this.acMode === 1 && this.isAcOn, activeColor: '#FF9100', onClickAction: () => {
                if(this.isAcOn) { animateTo({duration:300}, () => this.acMode = 1); DeviceManager.getInstance().sendCommand(new DeviceCommand(DeviceType.AC, DeviceAction.MODE, 1)); }
              }})
              SubControlBtn({ label: 'DRY', isActive: this.acMode === 2 && this.isAcOn, activeColor: '#7B61FF', onClickAction: () => {
                if(this.isAcOn) { animateTo({duration:300}, () => this.acMode = 2); DeviceManager.getInstance().sendCommand(new DeviceCommand(DeviceType.AC, DeviceAction.MODE, 2)); }
              }})
            }.width('100%').justifyContent(FlexAlign.Center)

          }
          .layoutWeight(45).height('100%').padding(24).backgroundColor('rgba(255,255,255,0.02)')
          .borderRadius(20).border({ width: 1, color: 'rgba(255,255,255,0.05)' })

          Column({ space: 24 }) {

            Column({ space: 12 }) {
              Text('Smart Scenes & AI辅助决策系统').fontSize(12).fontColor('#00E5FF').letterSpacing(2).alignSelf(ItemAlign.Start)

              // 🌟 核心替换：把死按钮换成真实的自然语言输入框
              Row({ space: 8 }) {
                TextInput({ placeholder: '请输入需求，如：我有点热', text: this.userInputIntent })
                  .layoutWeight(1)
                  .height(40)
                  .backgroundColor('rgba(255,255,255,0.05)')
                  .fontColor('#FFF')
                  .placeholderColor('#666')
                  .onChange((value: string) => {
                    this.userInputIntent = value;
                  })
                  .onSubmit(() => {
                    if(this.userInputIntent.trim() !== '') {
                      this.triggerAiAssistant(this.userInputIntent);
                    }
                  })

                Button(this.isAiLoading ? '...' : '发送')
                  .height(40)
                  .backgroundColor('#00E5FF')
                  .fontColor(Color.White)
                  .onClick(() => {
                    if(this.userInputIntent.trim() !== '') {
                      this.triggerAiAssistant(this.userInputIntent);
                    }
                  })
              }.width('100%')

              // 下方的回家模式/离家模式 SceneCard 保持不变...
              Row({ space: 12 }) {
                SceneCard({ title: '回家模式', desc: '自动感光与温控', glowColor: '#00E5FF', active: this.activeScene === '回家模式', onClickAction: () => {
                  animateTo({ duration: 300, curve: Curve.EaseInOut }, () => { this.activeScene = '回家模式'; this.isMainLightOn = true; this.isAcOn = true; });
                  DeviceManager.getInstance().sendCommand(new DeviceCommand(DeviceType.LIGHT, DeviceAction.POWER, true));
                  DeviceManager.getInstance().sendCommand(new DeviceCommand(DeviceType.AC, DeviceAction.POWER, true));
                }})
                SceneCard({ title: '离家模式', desc: '断电/开启安防', glowColor: '#FF1744', active: this.activeScene === '离家模式', onClickAction: () => {
                  animateTo({ duration: 300, curve: Curve.EaseInOut }, () => { this.activeScene = '离家模式'; this.isMainLightOn = false; this.isAcOn = false; this.isDoorLocked = true; this.isAutoAcOn = false; });
                  DeviceManager.getInstance().sendCommand(new DeviceCommand(DeviceType.LIGHT, DeviceAction.POWER, false));
                  DeviceManager.getInstance().sendCommand(new DeviceCommand(DeviceType.AC, DeviceAction.POWER, false));
                  DeviceManager.getInstance().sendCommand(new DeviceCommand(DeviceType.DOOR, DeviceAction.LOCK, true));
                  DeviceManager.getInstance().sendCommand(new DeviceCommand(DeviceType.AC, DeviceAction.AUTO, false));
                }})
              }.width('100%')
            }

            Blank()

            Column({ space: 12 }) {
              Text('End-Nodes Direct Link').fontSize(12).fontColor('#00E5FF').letterSpacing(2).alignSelf(ItemAlign.Start)

              Column({ space: 8 }) {
                DeviceToggle({ name: '客厅主灯', desc: '全彩吸顶灯/继电器', isOn: this.isMainLightOn, color: '#00FF00', toggleAction: (val) => {
                  this.isMainLightOn = val;
                  DeviceManager.getInstance().sendCommand(new DeviceCommand(DeviceType.LIGHT, DeviceAction.POWER, val));
                }})
                DeviceToggle({ name: '智能门锁', desc: '入户门禁控制', isOn: !this.isDoorLocked, color: '#00E5FF', toggleAction: (val) => {
                  this.isDoorLocked = !val;
                  DeviceManager.getInstance().sendCommand(new DeviceCommand(DeviceType.DOOR, DeviceAction.LOCK, !val));
                }})
                DeviceToggle({ name: '自动温控', desc: 'AI环境感知调节', isOn: this.isAutoAcOn, color: '#7B61FF', toggleAction: (val) => {
                  this.isAutoAcOn = val;
                  DeviceManager.getInstance().sendCommand(new DeviceCommand(DeviceType.AC, DeviceAction.AUTO, val));
                }})
              }
              .width('100%').padding(16).backgroundColor('rgba(255,255,255,0.02)')
              .borderRadius(16).border({ width: 1, color: 'rgba(255,255,255,0.05)' })
            }

          }.layoutWeight(55).height('100%')

        }.width('100%').height(540)
      }.width('100%')

      Blank()
    }.width('100%').height('100%').padding(32)
  }
}