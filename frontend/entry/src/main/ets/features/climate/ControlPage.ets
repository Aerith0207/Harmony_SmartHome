import hilog from '@ohos.hilog';
import promptAction from '@ohos.promptAction';
// 🌟 新增的权限申请与音频控制导入
import abilityAccessCtrl from '@ohos.abilityAccessCtrl';
import common from '@ohos.app.ability.common';
import { AsrService } from '../../network/AsrService';
import { AudioCaptureUtil } from '../../core/utils/AudioCaptureUtil';

import { DeviceManager } from '../../core/DeviceManager';
import { DeviceType, DeviceAction } from '../../core/adapter/DeviceConstants';
import { DeviceCommand } from '../../core/adapter/CommandModel';
import { AiDecisionEngine, AiCommand } from '../ai/AiDecisionEngine';
import { CryptoUtil } from '../../core/utils/CryptoUtil';
import { MqttBusService } from '../../network/mqtt';

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
      Row() {
        Text(this.icon).fontSize(26).opacity(this.isOn ? 1 : 0.5)
        Blank()
        Circle({ width: 8, height: 8 }).fill(this.isOn ? '#FFF' : 'transparent')
      }.width('100%').margin({ bottom: 16 })

      Column() {
        Text(this.name).fontSize(14).fontWeight(FontWeight.Bold)
          .fontColor(this.isOn ? '#FFF' : (this.isNightMode ? '#FFF' : '#1A1A1A'))
        Text(this.stateText).fontSize(10)
          .fontColor(this.isOn ? 'rgba(255,255,255,0.8)' : (this.isNightMode ? '#A0AAB5' : '#8899AA'))
          .margin({ top: 4 })
      }.alignItems(HorizontalAlign.Start).width('100%')
    }
    .layoutWeight(1)
    .padding(16)
    .backgroundColor(this.isOn ? this.activeColor : (this.isNightMode ? 'rgba(128,128,128,0.05)' : 'rgba(0,0,0,0.03)'))
    .borderRadius(20)
    .border({ width: 1, color: this.isOn ? this.activeColor : (this.isNightMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.05)') })
    .shadow(this.isOn ? { radius: 15, color: this.activeColor + '80', offsetY: 5 } : { radius: 0 })
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
      Text('🧠 AI智能场景决策')
        .fontSize(20).fontWeight(FontWeight.Bold).fontColor('#333').margin({ bottom: 15 })

      ForEach(this.strategyList, (item: AiCommand) => {
        Row() {
          Text(`设备:${item.device} `).fontColor('#666').fontSize(16)
          Text(`动作:${item.action}->${item.value}`).fontColor('#00E5FF').fontSize(16).fontWeight(FontWeight.Medium)
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

// 将此组件添加到 ControlPage.ets 顶部的组件区
@CustomDialog
export struct DoorAuthDialog {
  controller: CustomDialogController;
  @State inputPwd: string = '';
  onAuthSuccess: () => void = () => {};
  isNightMode: boolean = false;

  build() {
    Column({ space: 20 }) {
      Text('🛡️ 门禁安全验证').fontSize(20).fontWeight(FontWeight.Bold).fontColor(this.isNightMode ? '#FFF' : '#1A1A1A')

      TextInput({ placeholder: '请输入6位安全密码 (演示: 123456)', text: this.inputPwd })
        .type(InputType.Password)
        .onChange((val) => this.inputPwd = val)
        .height(48).borderRadius(12)
        .backgroundColor(this.isNightMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.05)')
        .fontColor(this.isNightMode ? '#FFF' : '#333')

      Row({ space: 16 }) {
        Button('取消').layoutWeight(1).backgroundColor(this.isNightMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.1)').fontColor(this.isNightMode ? '#FFF' : '#333')
          .onClick(() => this.controller.close())
        Button('验证并开锁').layoutWeight(1).backgroundColor('#FF1744').fontColor('#FFF')
          .onClick(() => {
            if (this.inputPwd === '123456') {
              this.onAuthSuccess();
              this.controller.close();
            } else {
              promptAction.showToast({ message: '❌ 密码错误，拒绝访问' });
            }
          })
      }.width('100%')
    }
    .padding(24).backgroundColor(this.isNightMode ? '#1E1E1E' : '#FFFFFF').borderRadius(24)
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

  doorAuthController: CustomDialogController = new CustomDialogController({
    builder: DoorAuthDialog({
      isNightMode: this.isNightMode,
      onAuthSuccess: () => {
        // 密码正确后，才真正执行开门指令
        this.isDoorLocked = false;
        DeviceManager.getInstance().sendCommand(new DeviceCommand(DeviceType.DOOR, DeviceAction.LOCK, false));
        promptAction.showToast({ message: '✅ 身份验证通过，门锁已开启' });
      }
    }),
    alignment: DialogAlignment.Center,
    autoCancel: true,
    customStyle: true
  });

  // 🌟 动态申请麦克风权限
  aboutToAppear() {
    let atManager = abilityAccessCtrl.createAtManager();
    let context = getContext(this) as common.UIAbilityContext;
    atManager.requestPermissionsFromUser(context, ['ohos.permission.MICROPHONE']).then((data) => {
      hilog.info(0x0000, 'PERM', '麦克风权限申请结果:' + data.authResults[0]);
    });
  }

  async triggerAiAssistant(intent: string) {
    this.isAiLoading = true;
    let temp = parseFloat(this.currentTemp);
    let hum = parseFloat(this.currentHum);

    // 🌟 接收全新的复合结果
    let result = await AiDecisionEngine.requestStrategy(intent, temp, hum);
    this.isAiLoading = false;

    // 🌟 分流处理逻辑
    if (result.type === 'CONTROL' && result.commands.length > 0) {
      // 1. 如果是控制指令，且解析出了实际动作，弹出熟悉的授权执行框
      this.currentAiStrategy = result.commands;
      this.dialogController.open();
    } else {
      // 2. 如果是 ADVICE (建议) 或 NONE (闲聊/越权)，直接用极其优雅的原生对话框与用户交流
      AlertDialog.show({
        title: result.type === 'ADVICE' ? '💡 AI 管家建议' : '🤖 AI 智能回复',
        message: result.message, // 展示大模型想对用户说的话
        autoCancel: true,
        alignment: DialogAlignment.Center,
        confirm: {
          value: '明白了',
          fontColor: this.isNightMode ? '#00E5FF' : '#007799',
          action: () => {}
        }
      });
    }
  }

  build() {
    Column() {
      Blank()

      Column({ space: 24 }) {
        Row() {
          Text('控制中心').fontSize(28).fontWeight(FontWeight.Bold).fontColor(this.isNightMode ? '#FFF' : '#1A1A1A')
          Blank()
          Text('Protocol:Universal_V2').fontColor(this.isNightMode ? '#B0BEC5' : '#8899AA').fontSize(12).fontFamily('monospace')
        }.width('100%')

        Row({ space: 24 }) {
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
                Text(this.isAcOn ? `MODE:${this.acMode === 0 ? 'COOL' : this.acMode === 1 ? 'HEAT' : 'DRY'}` : 'OFFLINE').fontSize(10).fontColor(this.isAcOn ? '#00FF00' : '#FF1744')
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
              Button(this.isAcOn ? '关闭' : '开启').width(110).height(50).fontSize(16).fontWeight(FontWeight.Bold)
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
                if (this.acTimerId !== -1) {
                  clearTimeout(this.acTimerId);
                  this.acTimerId = -1;
                  this.timerMessage = '🕒 设定定时关机';
                  return;
                }

                TimePickerDialog.show({
                  useMilitaryTime: true,
                  onAccept: (value: TimePickerResult) => {
                    let targetHour = value.hour;
                    let targetMinute = value.minute;
                    this.timerMessage = `🕒 已定时 ${targetHour.toString().padStart(2, '0')}:${targetMinute.toString().padStart(2, '0')} 关机(点击取消)`;

                    let now = new Date();
                    let targetTime = new Date();
                    targetTime.setHours(targetHour, targetMinute, 0, 0);

                    if (targetTime.getTime() <= now.getTime()) {
                      targetTime.setDate(targetTime.getDate() + 1);
                    }

                    let delayMs = targetTime.getTime() - now.getTime();

                    this.acTimerId = setTimeout(() => {
                      this.isAcOn = false;
                      this.timerMessage = '🕒 设定定时关机';
                      this.acTimerId = -1;
                      DeviceManager.getInstance().sendCommand(new DeviceCommand(DeviceType.AC, DeviceAction.POWER, false));
                    }, delayMs);
                  }
                })
              })

          }
          .layoutWeight(45).height('100%').padding(24)
          .backgroundColor(this.isNightMode ? 'rgba(255,255,255,0.05)' : 'rgba(255,255,255,0.85)')
          .borderRadius(24).border({ width: 1, color: this.isNightMode ? 'rgba(255,255,255,0.2)' : 'rgba(0,0,0,0.05)' })

          Column({ space: 24 }) {
            Column({ space: 12 }) {
              Text('Smart Scenes & AI语音交互').fontSize(12).fontColor(this.isNightMode ? '#00E5FF' : '#007799').letterSpacing(2).alignSelf(ItemAlign.Start)

              Row({ space: 8 }) {
                TextInput({ placeholder: '在此输入或长按右侧按钮...', text: this.userInputIntent })
                  .layoutWeight(1).height(40).borderRadius(20)
                  .backgroundColor(this.isNightMode ? 'rgba(128,128,128,0.1)' : 'rgba(255,255,255,0.7)')
                  .fontColor(this.isNightMode ? '#FFF' : '#333')
                  .placeholderColor(this.isNightMode ? '#A0AAB5' : '#888')
                  .onChange((val) => this.userInputIntent = val)
                  .onSubmit(() => {
                    if(this.userInputIntent.trim() !== '') this.triggerAiAssistant(this.userInputIntent);
                  })

                // 🌟 纯文本化，固定宽度，加入防崩溃与弹窗提示
                Button(this.isListening ? '倾听中...' : '按住说话')
                  .width(96).height(40).borderRadius(20)
                  .fontSize(14).fontWeight(FontWeight.Bold)
                  .backgroundColor(this.isListening ? '#FF1744' : (this.isNightMode ? 'rgba(0, 229, 255, 0.2)' : 'rgba(0, 119, 153, 0.2)'))
                  .fontColor(this.isListening ? '#FFF' : (this.isNightMode ? '#00E5FF' : '#007799'))
                  .animation({duration: 300})
                  .onTouch(async (event: TouchEvent) => {
                    if (event.type === TouchType.Down) {
                      this.isListening = true;
                      this.userInputIntent = '正在录音...';
                      AudioCaptureUtil.startRecording();
                    } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                      this.isListening = false;
                      this.isAiLoading = true;
                      this.userInputIntent = '正在处理...';

                      // 1. 获取录音数据
                      let audioData = await AudioCaptureUtil.stopRecording();

                      // 🌟 诊断点 1：如果录音是空的，直接弹窗拦截
                      if (!audioData || audioData.byteLength === 0) {
                        this.isAiLoading = false;
                        this.userInputIntent = '';
                        promptAction.showToast({ message: '⚠️ 模拟器未捕获到音频数据，请检查麦克风映射' });
                        return;
                      }

                      // 2. 发送给云端识别
                      let text = await AsrService.recognize(audioData);
                      this.isAiLoading = false;

                      // 🌟 诊断点 2：如果云端返回为空，弹窗提示查日志
                      if (text.trim() !== '') {
                        this.userInputIntent = text.replace(/[。，？！]/g, "");
                        this.triggerAiAssistant(this.userInputIntent);
                      } else {
                        this.userInputIntent = '';
                        promptAction.showToast({ message: '❌ 云端识别失败，请检查 API Key 或查看日志' });
                      }
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
                    // 如果是要开锁，必须弹出密码框拦截
                    if (val === true) {
                      this.doorAuthController.open();
                    } else {
                      // 如果是重新上锁，不需要密码，直接锁
                      this.isDoorLocked = true;
                      DeviceManager.getInstance().sendCommand(new DeviceCommand(DeviceType.DOOR, DeviceAction.LOCK, true));
                    }
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

            Button('⚙️触发本地AES解密回环测试')
              .width('100%').height(45).margin({ top: 20 })
              .backgroundColor('#FF9100')
              .onClick(async () => {
                let mockData: Record<string, number> = { "temp": 26, "humi": 50, "light_sw": 1 };
                let mockStatus = JSON.stringify(mockData);
                let cipherBytes = await CryptoUtil.encrypt(mockStatus);

                let hexString = "";
                for (let i = 0; i < cipherBytes.length; i++) {
                  let hex = cipherBytes[i].toString(16).toUpperCase();
                  hexString += (hex.length === 1 ? "0" + hex : hex);
                }

                MqttBusService.getInstance().client?.publish({
                  topic: 'smart_home/status',
                  payload: hexString,
                  qos: 0
                });
              })

          }.layoutWeight(55).height('100%')

        }.width('100%').height(540)
      }.width('100%')

      Blank()
    }.width('100%').height('100%').padding(32)
  }
}