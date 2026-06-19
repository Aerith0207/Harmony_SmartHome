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
  @Prop isNightMode: boolean;
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
      .fontColor(this.isActive ? this.activeColor : (this.isNightMode ? '#B0BEC5' : '#666'))
      .padding({ top: 6, bottom: 6, left: 12, right: 12 })
      .backgroundColor(this.isActive ? `rgba(${this.hexToRgb(this.activeColor)}, 0.15)` : (this.isNightMode ? 'rgba(128,128,128,0.1)' : 'rgba(0,0,0,0.05)'))
      .borderRadius(16).border({ width: 1, color: this.isActive ? this.activeColor : 'rgba(128,128,128,0.1)' })
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
  @Prop isNightMode: boolean;
  onClickAction: () => void = () => {};

  build() {
    Row() {
      Column() {
        Text(this.title).fontSize(15).fontWeight(FontWeight.Bold).fontColor(this.active ? this.glowColor : (this.isNightMode ? '#FFF' : '#333'))
          .animation({ duration: 300 })
        Text(this.desc).fontSize(10).fontColor(this.isNightMode ? '#A0AAB5' : '#556677').margin({ top: 4 })
      }.alignItems(HorizontalAlign.Start).layoutWeight(1)

      Toggle({ type: ToggleType.Switch, isOn: this.active })
        .selectedColor(this.glowColor)
        .hitTestBehavior(HitTestMode.Block)
    }
    .layoutWeight(1).padding(16).backgroundColor(this.isNightMode ? 'rgba(128,128,128,0.05)' : 'rgba(255,255,255,0.7)')
    .borderRadius(16).border({ width: 1, color: this.active ? this.glowColor : (this.isNightMode ? 'rgba(128,128,128,0.1)' : 'rgba(0,0,0,0.05)') })
    .animation({ duration: 300, curve: Curve.EaseInOut })
    .onClick(() => this.onClickAction())
  }
}

// 🌟 全新的方形图标按钮组件
@Component
struct DeviceIconButton {
  @Prop icon: string;
  @Prop name: string;
  @Prop stateText: string;
  @Prop isOn: boolean;
  @Prop activeColor: string;
  @Prop isNightMode: boolean;
  toggleAction: (val: boolean) => void = () => {};

  build() {
    Column() {
      // 顶部：图标与状态小圆点
      Row() {
        Text(this.icon).fontSize(26).opacity(this.isOn ? 1 : 0.5)
        Blank()
        Circle({ width: 8, height: 8 }).fill(this.isOn ? '#FFF' : 'transparent')
      }.width('100%').margin({ bottom: 16 })

      // 底部：设备名与状态描述
      Column() {
        Text(this.name).fontSize(14).fontWeight(FontWeight.Bold)
          .fontColor(this.isOn ? '#FFF' : (this.isNightMode ? '#FFF' : '#1A1A1A'))
        Text(this.stateText).fontSize(10)
          .fontColor(this.isOn ? 'rgba(255,255,255,0.8)' : (this.isNightMode ? '#A0AAB5' : '#8899AA'))
          .margin({ top: 4 })
      }.alignItems(HorizontalAlign.Start).width('100%')
    }
    .layoutWeight(1) // 自动均分宽度
    .padding(16)
    .backgroundColor(this.isOn ? this.activeColor : (this.isNightMode ? 'rgba(128,128,128,0.05)' : 'rgba(0,0,0,0.03)'))
    .borderRadius(20)
    .border({ width: 1, color: this.isOn ? this.activeColor : (this.isNightMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.05)') })
    .shadow(this.isOn ? { radius: 15, color: this.activeColor + '80', offsetY: 5 } : { radius: 0 }) // 激活时发光
    .animation({ duration: 300, curve: Curve.FastOutSlowIn })
    .onClick(() => this.toggleAction(!this.isOn))
  }
}

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
    .padding(24).backgroundColor(Color.White).borderRadius(24)
  }
}

// ==========================================
// 主页面容器
// ==========================================
@Component
export struct ControlPage {
  @Prop isNightMode: boolean;

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

  @State currentAiStrategy: AiCommand[] = [];
  @State isAiLoading: boolean = false;
  @State userInputIntent: string = '';
  @State currentAcBrand: number = 0;

  @State showTimePicker: boolean = false;
  @State isListening: boolean = false;

  // 👇 新增这两个变量
  @State timerMessage: string = '🕒 设定定时关机';
  @State acTimerId: number = -1;

  dialogController: CustomDialogController = new CustomDialogController({
    builder: AiConfirmDialog({
      strategyList: this.currentAiStrategy,
      onConfirm: () => {
        this.currentAiStrategy.forEach((strategy: AiCommand) => {
          let cmd = new DeviceCommand(strategy.device as DeviceType, strategy.action as DeviceAction, strategy.value);
          DeviceManager.getInstance().sendCommand(cmd);

          let act = strategy.action.toLowerCase();
          let val = strategy.value;
          let isTurnOn = (val === true || val === 'true' || val === 1 || val === 'on');

          if(strategy.device === 'ac') {
            if(act === 'power' || act === 'switch') this.isAcOn = isTurnOn;
            if(act === 'temperature' || act === 'temp') this.targetTemp = Number(val);
          }
          if(strategy.device === 'light') {
            if(act === 'power' || act === 'switch') this.isMainLightOn = isTurnOn;
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
          Text('控制中心').fontSize(28).fontWeight(FontWeight.Bold).fontColor(this.isNightMode ? '#FFF' : '#1A1A1A')
          Blank()
          Text('Protocol: Universal_V2').fontColor(this.isNightMode ? '#B0BEC5' : '#8899AA').fontSize(12).fontFamily('monospace')
        }.width('100%')

        Row({ space: 24 }) {
          // 左侧：空调控制面板
          Column() {
            Row() {
              Text('HVAC Climate Control').fontSize(12).fontColor(this.isNightMode ? '#00E5FF' : '#007799').letterSpacing(2)
              Blank()
              Select([{ value: '默认通用' }, { value: '海尔' }, { value: '格力' }, { value: '美的' }])
                .selected(this.currentAcBrand)
                .value('品牌:默认')
                .font({ size: 12, weight: 500 })
                .fontColor(this.isNightMode ? '#00E5FF' : '#007799')
                .selectedOptionFont({ size: 12, weight: 400 })
                .optionFont({ size: 12, weight: 400 })
                .backgroundColor(this.isNightMode ? 'rgba(0, 229, 255, 0.1)' : 'rgba(0, 119, 153, 0.1)')
                .borderRadius(8)
                .onSelect((index: number, value: string) => {
                  this.currentAcBrand = index;
                  DeviceManager.getInstance().sendCommand(new DeviceCommand(DeviceType.AC, 'brand' as DeviceAction, index));
                })
            }.width('100%').margin({ bottom: 20 })

            Stack() {
              Circle({ width: 200, height: 200 }).fill('transparent').stroke(this.isNightMode ? 'rgba(0, 229, 255, 0.2)' : 'rgba(0, 119, 153, 0.2)').strokeWidth(1)
              Circle({ width: 180, height: 180 }).fill(this.isNightMode ? 'rgba(0,0,0,0.5)' : 'rgba(255,255,255,0.9)')
                .shadow({ radius: this.isAcOn ? 60 : 0, color: this.isAcOn ? (this.isNightMode ? 'rgba(0, 229, 255, 0.4)' : 'rgba(0, 119, 153, 0.3)') : 'transparent' })
                .animation({ duration: 600, curve: Curve.FastOutSlowIn })

              Column() {
                Text('TARGET').fontSize(10).fontColor(this.isNightMode ? '#A0AAB5' : '#888')
                Text(`${this.targetTemp}℃`).fontSize(48).fontWeight(FontWeight.Bolder).fontColor(this.isAcOn ? (this.isNightMode ? '#00E5FF' : '#007799') : (this.isNightMode ? '#8899AA' : '#888')).margin({ top: 4, bottom: 4 })
                  .animation({ duration: 400, curve: Curve.EaseInOut })
                Text(this.isAcOn ? `MODE: ${this.acMode === 0 ? 'COOL' : this.acMode === 1 ? 'HEAT' : 'DRY'}` : 'OFFLINE').fontSize(10).fontColor(this.isAcOn ? '#00FF00' : '#FF1744')
                  .animation({ duration: 400 })
              }
            }.margin({ bottom: 20 })

            Row({ space: 24 }) {
              Column({ space: 4 }) { Text('CURRENT').fontSize(10).fontColor(this.isNightMode ? '#A0AAB5' : '#888'); Text(`${this.currentTemp}℃`).fontSize(16).fontColor(this.isNightMode ? '#FFF' : '#333').fontWeight(FontWeight.Bold) }.alignItems(HorizontalAlign.Center)
              Column({ space: 4 }) { Text('HUMIDITY').fontSize(10).fontColor(this.isNightMode ? '#A0AAB5' : '#888'); Text(`${this.currentHum}%`).fontSize(16).fontColor(this.isNightMode ? '#FFF' : '#333').fontWeight(FontWeight.Bold) }.alignItems(HorizontalAlign.Center)
            }.margin({ bottom: 24 })

            Row({ space: 16 }) {
              Button('-').width(50).height(50).fontSize(24).backgroundColor(this.isNightMode ? 'rgba(128,128,128,0.1)' : 'rgba(0,0,0,0.05)').fontColor(this.isNightMode ? '#FFF' : '#333').borderRadius(25)
                .onClick(() => {
                  if(this.isAcOn) {
                    animateTo({ duration: 300, curve: Curve.EaseInOut }, () => { this.targetTemp -= 1; });
                    DeviceManager.getInstance().sendCommand(new DeviceCommand(DeviceType.AC, DeviceAction.TEMPERATURE, this.targetTemp));
                  }
                })
              Button(this.isAcOn ? '关 闭' : '开 启').width(110).height(50).fontSize(16).fontWeight(FontWeight.Bold)
                .backgroundColor(this.isAcOn ? '#FF1744' : '#1976D2').borderRadius(25)
                .animation({ duration: 600, curve: Curve.EaseOut })
                .onClick(() => {
                  animateTo({ duration: 600, curve: Curve.FastOutSlowIn }, () => { this.isAcOn = !this.isAcOn; });
                  DeviceManager.getInstance().sendCommand(new DeviceCommand(DeviceType.AC, DeviceAction.POWER, this.isAcOn));
                })
              Button('+').width(50).height(50).fontSize(24).backgroundColor(this.isNightMode ? 'rgba(128,128,128,0.1)' : 'rgba(0,0,0,0.05)').fontColor(this.isNightMode ? '#FFF' : '#333').borderRadius(25)
                .onClick(() => {
                  if(this.isAcOn) {
                    animateTo({ duration: 300, curve: Curve.EaseInOut }, () => { this.targetTemp += 1; });
                    DeviceManager.getInstance().sendCommand(new DeviceCommand(DeviceType.AC, DeviceAction.TEMPERATURE, this.targetTemp));
                  }
                })
            }.margin({ bottom: 20 })

            Row({ space: 12 }) {
              SubControlBtn({ label: 'COOL', isActive: this.acMode === 0 && this.isAcOn, activeColor: this.isNightMode ? '#00E5FF' : '#007799', isNightMode: this.isNightMode, onClickAction: () => {
                if(this.isAcOn) { animateTo({duration:300}, () => this.acMode = 0); DeviceManager.getInstance().sendCommand(new DeviceCommand(DeviceType.AC, DeviceAction.MODE, 0)); }
              }})
              SubControlBtn({ label: 'HEAT', isActive: this.acMode === 1 && this.isAcOn, activeColor: '#FF9100', isNightMode: this.isNightMode, onClickAction: () => {
                if(this.isAcOn) { animateTo({duration:300}, () => this.acMode = 1); DeviceManager.getInstance().sendCommand(new DeviceCommand(DeviceType.AC, DeviceAction.MODE, 1)); }
              }})
              SubControlBtn({ label: 'DRY', isActive: this.acMode === 2 && this.isAcOn, activeColor: '#7B61FF', isNightMode: this.isNightMode, onClickAction: () => {
                if(this.isAcOn) { animateTo({duration:300}, () => this.acMode = 2); DeviceManager.getInstance().sendCommand(new DeviceCommand(DeviceType.AC, DeviceAction.MODE, 2)); }
              }})
            }.width('100%').justifyContent(FlexAlign.Center)

            Button(this.timerMessage).width('80%').height(40).margin({top: 20})
              .backgroundColor(this.isNightMode ? 'rgba(0, 229, 255, 0.1)' : 'rgba(0, 119, 153, 0.1)')
              .fontColor(this.isNightMode ? '#00E5FF' : '#007799').borderRadius(20)
              .onClick(() => {
                // 如果已经设定了定时，再次点击就是取消定时
                if (this.acTimerId !== -1) {
                  clearTimeout(this.acTimerId);
                  this.acTimerId = -1;
                  this.timerMessage = '🕒 设定定时关机';
                  return;
                }

                // 调用鸿蒙原生的时间选择器弹窗
                TimePickerDialog.show({
                  useMilitaryTime: true, // 使用 24 小时制
                  onAccept: (value: TimePickerResult) => {
                    let targetHour = value.hour;
                    let targetMinute = value.minute;

                    // 更新按钮的文字提示
                    this.timerMessage = `🕒 已定时 ${targetHour.toString().padStart(2, '0')}:${targetMinute.toString().padStart(2, '0')} 关机 (点击取消)`;

                    // 获取当前时间，计算还要多久关机
                    let now = new Date();
                    let targetTime = new Date();
                    targetTime.setHours(targetHour, targetMinute, 0, 0);

                    // 如果设定的时间比当前早，说明是第二天的这个时间
                    if (targetTime.getTime() <= now.getTime()) {
                      targetTime.setDate(targetTime.getDate() + 1);
                    }

                    let delayMs = targetTime.getTime() - now.getTime();

                    // 设定延时任务，时间到了自动关机
                    this.acTimerId = setTimeout(() => {
                      this.isAcOn = false;
                      this.timerMessage = '🕒 设定定时关机';
                      this.acTimerId = -1;
                      // 发送 MQTT 关机指令
                      DeviceManager.getInstance().sendCommand(new DeviceCommand(DeviceType.AC, DeviceAction.POWER, false));
                    }, delayMs);
                  }
                })
              })

          }
          .layoutWeight(45).height('100%').padding(24)
          .backgroundColor(this.isNightMode ? 'rgba(255,255,255,0.05)' : 'rgba(255,255,255,0.85)')
          .borderRadius(24).border({ width: 1, color: this.isNightMode ? 'rgba(255,255,255,0.2)' : 'rgba(0,0,0,0.05)' })

          // 右侧：AI 辅助与设备列表
          Column({ space: 24 }) {
            Column({ space: 12 }) {
              Text('Smart Scenes & AI语音交互').fontSize(12).fontColor(this.isNightMode ? '#00E5FF' : '#007799').letterSpacing(2).alignSelf(ItemAlign.Start)

              Row({ space: 8 }) {
                TextInput({ placeholder: '在此输入或点击右侧语音...', text: this.userInputIntent })
                  .layoutWeight(1).height(48).borderRadius(24)
                  .backgroundColor(this.isNightMode ? 'rgba(128,128,128,0.1)' : 'rgba(255,255,255,0.7)')
                  .fontColor(this.isNightMode ? '#FFF' : '#333')
                  .placeholderColor(this.isNightMode ? '#A0AAB5' : '#888')
                  .onChange((val) => this.userInputIntent = val)
                  .onSubmit(() => {
                    if(this.userInputIntent.trim() !== '') this.triggerAiAssistant(this.userInputIntent);
                  })

                Button('🎤').width(48).height(48).borderRadius(24).fontSize(20)
                  .backgroundColor(this.isListening ? '#FF1744' : (this.isNightMode ? 'rgba(0, 229, 255, 0.2)' : 'rgba(0, 119, 153, 0.2)'))
                  .fontColor(this.isListening ? '#FFF' : (this.isNightMode ? '#00E5FF' : '#007799'))
                  .animation({duration: 300})
                  .onClick(() => {
                    this.isListening = !this.isListening;
                    if(this.isListening) {
                      setTimeout(()=>{
                        this.userInputIntent = "太热了，帮我把空调调到22度并开灯";
                        this.isListening = false;
                        this.triggerAiAssistant(this.userInputIntent);
                      }, 2000);
                    }
                  })
              }.width('100%')

              Row({ space: 12 }) {
                SceneCard({ title: '回家模式', desc: '自动感光与温控', glowColor: this.isNightMode ? '#00E5FF' : '#007799', active: this.activeScene === '回家模式', isNightMode: this.isNightMode, onClickAction: () => {
                  animateTo({ duration: 300, curve: Curve.EaseInOut }, () => { this.activeScene = '回家模式'; this.isMainLightOn = true; this.isAcOn = true; });
                  DeviceManager.getInstance().sendCommand(new DeviceCommand(DeviceType.LIGHT, DeviceAction.POWER, true));
                  DeviceManager.getInstance().sendCommand(new DeviceCommand(DeviceType.AC, DeviceAction.POWER, true));
                }})
                SceneCard({ title: '离家模式', desc: '断电/开启安防', glowColor: '#FF1744', active: this.activeScene === '离家模式', isNightMode: this.isNightMode, onClickAction: () => {
                  animateTo({ duration: 300, curve: Curve.EaseInOut }, () => { this.activeScene = '离家模式'; this.isMainLightOn = false; this.isAcOn = false; this.isDoorLocked = true; this.isAutoAcOn = false; });
                  DeviceManager.getInstance().sendCommand(new DeviceCommand(DeviceType.LIGHT, DeviceAction.POWER, false));
                  DeviceManager.getInstance().sendCommand(new DeviceCommand(DeviceType.AC, DeviceAction.POWER, false));
                  DeviceManager.getInstance().sendCommand(new DeviceCommand(DeviceType.DOOR, DeviceAction.LOCK, true));
                  DeviceManager.getInstance().sendCommand(new DeviceCommand(DeviceType.AC, DeviceAction.AUTO, false));
                }})
              }.width('100%').margin({top: 10})
            }

            Blank()

            Column({ space: 12 }) {
              Text('快捷设备').fontSize(12).fontColor(this.isNightMode ? '#00E5FF' : '#007799').letterSpacing(2).alignSelf(ItemAlign.Start)

              // 🌟 全新布局：横向排列的图标卡片按钮
              Row({ space: 12 }) {
                DeviceIconButton({
                  icon: '💡', name: '客厅主灯', stateText: this.isMainLightOn ? '已点亮' : '已关闭',
                  isOn: this.isMainLightOn, activeColor: '#00FF00', isNightMode: this.isNightMode,
                  toggleAction: (val) => {
                    this.isMainLightOn = val;
                    DeviceManager.getInstance().sendCommand(new DeviceCommand(DeviceType.LIGHT, DeviceAction.POWER, val));
                  }
                })

                DeviceIconButton({
                  icon: '🔓', name: '智能门锁', stateText: !this.isDoorLocked ? '已解锁' : '设防中',
                  isOn: !this.isDoorLocked, activeColor: '#00E5FF', isNightMode: this.isNightMode,
                  toggleAction: (val) => {
                    this.isDoorLocked = !val;
                    DeviceManager.getInstance().sendCommand(new DeviceCommand(DeviceType.DOOR, DeviceAction.LOCK, !val));
                  }
                })

                DeviceIconButton({
                  icon: '🌡️', name: '自动温控', stateText: this.isAutoAcOn ? 'AI托管中' : '手动模式',
                  isOn: this.isAutoAcOn, activeColor: '#7B61FF', isNightMode: this.isNightMode,
                  toggleAction: (val) => {
                    this.isAutoAcOn = val;
                    DeviceManager.getInstance().sendCommand(new DeviceCommand(DeviceType.AC, DeviceAction.AUTO, val));
                  }
                })
              }.width('100%')
            }

          }.layoutWeight(55).height('100%')

        }.width('100%').height(540)
      }.width('100%')

      Blank()
    }.width('100%').height('100%').padding(32)
  }
}