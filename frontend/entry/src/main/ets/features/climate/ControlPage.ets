// frontend/entry/src/main/ets/features/climate/ControlPage.ets

import hilog from '@ohos.hilog';
import promptAction from '@ohos.promptAction';
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

@Component
struct SubControlBtn {
  @Prop label: string; @Prop isActive: boolean; @Prop activeColor: string; @Prop isNightMode: boolean;
  onClickAction: () => void = () => {};
  hexToRgb(hex: string): string {
    let r = parseInt(hex.slice(1, 3), 16); let g = parseInt(hex.slice(3, 5), 16); let b = parseInt(hex.slice(5, 7), 16);
    return `${r}, ${g}, ${b}`;
  }
  build() {
    Text(this.label).fontSize(12).fontWeight(FontWeight.Bold).fontColor(this.isActive ? this.activeColor : (this.isNightMode ? '#B0BEC5' : '#666'))
      .padding({ top: 10, bottom: 10, left: 14, right: 14 })
      .backgroundColor(this.isActive ? `rgba(${this.hexToRgb(this.activeColor)}, 0.15)` : (this.isNightMode ? '#2A2E35' : '#F5F7FA'))
      .borderRadius(20).border({ width: 1, color: this.isActive ? this.activeColor : (this.isNightMode ? '#3A3F48' : '#E0E4E8') })
      .animation({ duration: 300, curve: Curve.EaseInOut }).onClick(() => this.onClickAction())
  }
}

@CustomDialog
export struct AiConfirmDialog {
  controller: CustomDialogController; strategyList: AiCommand[] = []; onConfirm: () => void = () => {};
  build() {
    Column() {
      Text('🧠 AI智能场景决策').fontSize(20).fontWeight(FontWeight.Bold).fontColor('#333').margin({ bottom: 15 })
      ForEach(this.strategyList, (item: AiCommand) => {
        Row() { Text(`设备:${item.device} `).fontColor('#666').fontSize(16); Text(`动作:${item.action}->${item.value}`).fontColor('#00E5FF').fontSize(16).fontWeight(FontWeight.Medium) }.width('100%').margin({ bottom: 10 }).padding({ left: 10, right: 10 })
      }, (item: AiCommand, index: number) => index.toString())
      Row({ space: 20 }) {
        Button('取消忽略').backgroundColor('#F5F5F5').fontColor('#333').layoutWeight(1).onClick(() => { this.controller.close() })
        Button('授权执行').backgroundColor('#00E5FF').fontColor(Color.White).layoutWeight(1).onClick(() => { this.onConfirm(); this.controller.close(); })
      }.margin({ top: 20 }).width('100%')
    }.padding(24).backgroundColor(Color.White).borderRadius(24)
  }
}

@CustomDialog
export struct DoorAuthDialog {
  controller: CustomDialogController;
  @State inputPwd: string = '';
  @StorageLink('global_doorPwd') globalDoorPwd: string = '123456';
  onAuthSuccess: () => void = () => {};
  isNightMode: boolean = false;

  build() {
    Column({ space: 20 }) {
      Text('🛡️ 门禁安全验证').fontSize(20).fontWeight(FontWeight.Bold).fontColor(this.isNightMode ? '#FFF' : '#1A1A1A')

      TextInput({ placeholder: '请输入6位安全密码', text: this.inputPwd })
        .type(InputType.Password)
        .onChange((val) => this.inputPwd = val)
        .height(48).borderRadius(12)
        .backgroundColor(this.isNightMode ? '#2A2E35' : '#F5F7FA')
        .fontColor(this.isNightMode ? '#FFF' : '#333')
        .placeholderColor(this.isNightMode ? '#8899AA' : '#888')

      Row({ space: 16 }) {
        Button('取消').layoutWeight(1).backgroundColor(this.isNightMode ? '#3A3F48' : '#E0E4E8').fontColor(this.isNightMode ? '#FFF' : '#333').onClick(() => this.controller.close())
        Button('验证并开锁').layoutWeight(1).backgroundColor('#FF1744').fontColor('#FFF').onClick(() => {
          if (this.inputPwd === this.globalDoorPwd) {
            this.onAuthSuccess();
            this.controller.close();
          } else {
            promptAction.showToast({ message: '❌ 密码错误，拒绝访问' });
          }
        })
      }.width('100%')
    }
    .padding(24).backgroundColor(this.isNightMode ? '#1E222B' : '#FFFFFF').borderRadius(24)
  }
}

@Component
struct SceneCard {
  @Prop title: string; @Prop desc: string; @Prop glowColor: string; @Prop active: boolean; @Prop isNightMode: boolean;
  onClickAction: () => void = () => {};
  build() {
    Row() {
      Column() {
        Text(this.title).fontSize(16).fontWeight(FontWeight.Bold).fontColor(this.active ? this.glowColor : (this.isNightMode ? '#FFF' : '#333')).animation({ duration: 300 })
        Text(this.desc).fontSize(12).fontColor(this.isNightMode ? '#A0AAB5' : '#556677').margin({ top: 6 })
      }.alignItems(HorizontalAlign.Start).layoutWeight(1)
      Toggle({ type: ToggleType.Switch, isOn: this.active }).selectedColor(this.glowColor).hitTestBehavior(HitTestMode.Block)
    }
    .layoutWeight(1).height(88).padding(20)
    .backgroundColor(this.isNightMode ? '#2A2E35' : '#F5F7FA')
    .borderRadius(20).border({ width: 1, color: this.active ? this.glowColor : (this.isNightMode ? '#3A3F48' : '#E0E4E8') })
    .animation({ duration: 300, curve: Curve.EaseInOut }).onClick(() => this.onClickAction())
  }
}

@Component
struct DeviceIconButton {
  @Prop icon: string; @Prop name: string; @Prop stateText: string; @Prop isOn: boolean; @Prop activeColor: string; @Prop isNightMode: boolean;
  toggleAction: (val: boolean) => void = () => {};
  build() {
    Column() {
      Row() {
        Text(this.icon).fontSize(26).opacity(this.isOn ? 1 : 0.6)
        Blank()
        Circle({ width: 8, height: 8 }).fill(this.isOn ? '#1A1A1A' : 'transparent')
      }.width('100%').margin({ bottom: 16 })
      Column() {
        Text(this.name).fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.isOn ? '#1A1A1A' : (this.isNightMode ? '#FFF' : '#1A1A1A'))
        Text(this.stateText).fontSize(10).fontColor(this.isOn ? 'rgba(0,0,0,0.6)' : (this.isNightMode ? '#A0AAB5' : '#8899AA')).margin({ top: 4 })
      }.alignItems(HorizontalAlign.Start).width('100%')
    }
    .layoutWeight(1).padding(16)
    .backgroundColor(this.isOn ? this.activeColor : (this.isNightMode ? '#2A2E35' : '#F5F7FA'))
    .borderRadius(20).border({ width: 1, color: this.isOn ? this.activeColor : (this.isNightMode ? '#3A3F48' : '#E0E4E8') })
    .shadow(this.isOn ? { radius: 15, color: this.activeColor + '80', offsetY: 5 } : { radius: 0 })
    .animation({ duration: 300, curve: Curve.FastOutSlowIn }).onClick(() => this.toggleAction(!this.isOn))
  }
}

@Component
export struct ControlPage {
  @Prop isNightMode: boolean;

  @StorageLink('global_acTemp') targetTemp: number = 24;
  @StorageLink('global_realTemp') currentTemp: string = '26.0';
  @StorageLink('global_realHum') currentHum: string = '45.0';
  @StorageLink('global_isAcOn') isAcOn: boolean = false;
  @StorageLink('global_acMode') acMode: number = 0;
  @StorageLink('global_acFan') acFan: number = 0;
  @State activeScene: string = '回家模式';
  @StorageLink('global_isMainLightOn') isMainLightOn: boolean = false;
  @StorageLink('global_isDoorLocked') isDoorLocked: boolean = true;
  @StorageLink('global_isAutoAcOn') isAutoAcOn: boolean = false;

  @State currentAiStrategy: AiCommand[] = [];
  @State isAiLoading: boolean = false;
  @State userInputIntent: string = '';
  @StorageLink('global_acBrand') currentAcBrand: number = 0;
  @State isListening: boolean = false;
  @State timerMessage: string = '🕒 设定定时关机';
  @State acTimerId: number = -1;

  syncAcState() {
    let hwBrand = 0;
    if (this.currentAcBrand === 1) hwBrand = 2;
    else if (this.currentAcBrand === 2) hwBrand = 1;
    else if (this.currentAcBrand === 3) hwBrand = 0;

    let hwMode = 1;
    if (this.acMode === 0) hwMode = 1;
    else if (this.acMode === 1) hwMode = 4;
    else if (this.acMode === 2) hwMode = 2;

    let payload: Record<string, string | number> = {};
    payload['cmd'] = "ac_set";
    payload['brand'] = hwBrand;
    payload['power'] = this.isAcOn ? 1 : 0;
    payload['mode'] = this.acMode;
    payload['temp'] = this.targetTemp;
    payload['fan'] = this.acFan;

    hilog.info(0x0000, 'AC_CTRL', `📤 [准备下发] 组装完成的空调全量状态: ${JSON.stringify(payload)}`);
    MqttBusService.getInstance().publishCommand(payload);
  }

  dialogController: CustomDialogController = new CustomDialogController({
    builder: AiConfirmDialog({
      strategyList: this.currentAiStrategy,
      onConfirm: () => {
        let needAcSync = false;
        this.currentAiStrategy.forEach((strategy: AiCommand) => {
          let act = strategy.action.toLowerCase();
          let val = strategy.value;
          let isTurnOn = (val === true || val === 'true' || val === 1 || val === 'on');

          if(strategy.device === 'ac') {
            needAcSync = true;
            if(act === 'power' || act === 'switch') this.isAcOn = isTurnOn;
            if(act === 'temperature' || act === 'temp') this.targetTemp = Number(val);
            // 🌟 新增：拦截 AI 的模式切换指令
            if(act === 'mode') this.acMode = Number(val);
            // 🌟 新增：拦截 AI 的风速切换指令
            if(act === 'fan') this.acFan = Number(val);
          }
          if(strategy.device === 'light') {
            if(act === 'power' || act === 'switch') this.isMainLightOn = isTurnOn;
            DeviceManager.getInstance().sendCommand(new DeviceCommand(DeviceType.LIGHT, DeviceAction.POWER, isTurnOn));
          }
        });

        if (needAcSync) {
          // AI 策略解析赋值完毕，触发全量状态同步！
          this.syncAcState();
        }
      }
    }), alignment: DialogAlignment.Center, autoCancel: false
  });

  doorAuthController: CustomDialogController = new CustomDialogController({
    builder: DoorAuthDialog({
      isNightMode: this.isNightMode,
      onAuthSuccess: () => { this.isDoorLocked = false; DeviceManager.getInstance().sendCommand(new DeviceCommand(DeviceType.DOOR, DeviceAction.LOCK, false)); promptAction.showToast({ message: '✅ 身份验证通过，门锁已开启' }); }
    }), alignment: DialogAlignment.Center, autoCancel: true, customStyle: true
  });

  aboutToAppear() {
    let atManager = abilityAccessCtrl.createAtManager(); let context = getContext(this) as common.UIAbilityContext;
    atManager.requestPermissionsFromUser(context, ['ohos.permission.MICROPHONE']).then((data) => { hilog.info(0x0000, 'PERM', '麦克风权限申请结果:' + data.authResults[0]); });
  }

  async triggerAiAssistant(intent: string) {
    this.isAiLoading = true;
    // 🌟 传入 this.targetTemp 替代之前的 currentHum
    let result = await AiDecisionEngine.requestStrategy(intent, parseFloat(this.currentTemp), this.targetTemp);
    this.isAiLoading = false;
    if (result.type === 'CONTROL' && result.commands.length > 0) {
      this.currentAiStrategy = result.commands; this.dialogController.open();
    } else {
      AlertDialog.show({ title: result.type === 'ADVICE' ? '💡 AI 管家建议' : '🤖 AI 智能回复', message: result.message, autoCancel: true, alignment: DialogAlignment.Center, confirm: { value: '明白了', fontColor: this.isNightMode ? '#00E5FF' : '#007799', action: () => {} } });
    }
  }

  build() {
    Column() {
      Blank()
      Column({ space: 24 }) {
        Row() {
          Text('控制中心').fontSize(28).fontWeight(FontWeight.Bold).fontColor(this.isNightMode ? '#FFF' : '#1A1A1A')
          Blank()
        }.width('100%')

        Row({ space: 24 }) {
          Column() {
            Row() {
              Text('HVAC Climate Control').fontSize(12).fontColor(this.isNightMode ? '#00E5FF' : '#007799').letterSpacing(2)
              Blank()
              Select([{ value: '默认通用' }, { value: '海尔' }, { value: '格力' }, { value: '美的' }])
                .selected(this.currentAcBrand)
                .value(`品牌:${['默认通用', '海尔', '格力', '美的'][this.currentAcBrand]}`)
                .font({ size: 12, weight: 500 })
                .fontColor(this.isNightMode ? '#00E5FF' : '#007799')
                .selectedOptionFont({ size: 12, weight: 400 })
                .optionFont({ size: 12, weight: 400 })
                .backgroundColor(this.isNightMode ? '#2A2E35' : '#F5F7FA')
                .borderRadius(8)
                .onSelect((index: number) => {
                  this.currentAcBrand = index;
                  this.syncAcState();
                })
            }.width('100%').margin({ bottom: 20 })

            Stack() {
              Circle({ width: 200, height: 200 }).fill('transparent').stroke(this.isNightMode ? 'rgba(0, 229, 255, 0.2)' : 'rgba(0, 119, 153, 0.2)').strokeWidth(1)
              Circle({ width: 180, height: 180 }).fill(this.isNightMode ? '#2A2E35' : '#F5F7FA')
                .shadow({ radius: this.isAcOn ? 60 : 0, color: this.isAcOn ? (this.isNightMode ? 'rgba(0, 229, 255, 0.4)' : 'rgba(0, 119, 153, 0.3)') : 'transparent' }).animation({ duration: 600, curve: Curve.FastOutSlowIn })
              Column() {
                Text('TARGET').fontSize(10).fontColor(this.isNightMode ? '#8899AA' : '#888')

                Text(`${this.targetTemp}℃`).fontSize(48).fontWeight(FontWeight.Bolder).fontColor(this.isAcOn ? (this.isNightMode ? '#00E5FF' : '#007799') : (this.isNightMode ? '#A0AAB5' : '#888')).margin({ top: 4, bottom: 4 }).animation({ duration: 400, curve: Curve.EaseInOut })

                // 🌟 核心修改：字号放大至14，增加字重，颜色改为清晰的深黑/高级灰
                Text(this.isAcOn ?
                  `模式:${this.acMode===0?'自动':this.acMode===1?'制冷':this.acMode===2?'除湿':this.acMode===3?'送风':'制热'} | 风速:${this.acFan===0?'自动':this.acFan===1?'低风':this.acFan===2?'中风':'高风'}`
                  : '离线')
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.isAcOn ? (this.isNightMode ? '#E0E0E0' : '#333333') : '#FF1744')
                  .animation({ duration: 400 })
              }
            }.margin({ bottom: 20 })

            Row({ space: 24 }) {
              Column({ space: 4 }) { Text('CURRENT').fontSize(10).fontColor(this.isNightMode ? '#8899AA' : '#888'); Text(`${this.currentTemp}℃`).fontSize(16).fontColor(this.isNightMode ? '#FFF' : '#333').fontWeight(FontWeight.Bold) }.alignItems(HorizontalAlign.Center)
              Column({ space: 4 }) { Text('HUMIDITY').fontSize(10).fontColor(this.isNightMode ? '#8899AA' : '#888'); Text(`${this.currentHum}%`).fontSize(16).fontColor(this.isNightMode ? '#FFF' : '#333').fontWeight(FontWeight.Bold) }.alignItems(HorizontalAlign.Center)
            }.margin({ bottom: 24 })

            Row({ space: 16 }) {
              Button('-').width(50).height(50).fontSize(24).backgroundColor(this.isNightMode ? '#2A2E35' : '#F5F7FA').fontColor(this.isNightMode ? '#FFF' : '#333').borderRadius(25).onClick(() => { if(this.isAcOn && this.targetTemp > 16) { animateTo({ duration: 300 }, () => { this.targetTemp -= 1; }); this.syncAcState(); } })
              Button(this.isAcOn ? '关闭' : '开启').width(110).height(50).fontSize(16).fontWeight(FontWeight.Bold).backgroundColor(this.isAcOn ? '#FF1744' : '#1976D2').borderRadius(25).animation({ duration: 600 }).onClick(() => { animateTo({ duration: 600 }, () => { this.isAcOn = !this.isAcOn; }); this.syncAcState(); })
              Button('+').width(50).height(50).fontSize(24).backgroundColor(this.isNightMode ? '#2A2E35' : '#F5F7FA').fontColor(this.isNightMode ? '#FFF' : '#333').borderRadius(25).onClick(() => { if(this.isAcOn && this.targetTemp < 30) { animateTo({ duration: 300 }, () => { this.targetTemp += 1; }); this.syncAcState(); } })
            }.margin({ bottom: 20 })

            // 🌟 模式控制行 (全中文标签)
            Row() { Text('模式').fontSize(12).fontWeight(FontWeight.Medium).fontColor(this.isNightMode ? '#8899AA' : '#888').width(40)
              Row({ space: 4 }) {
                SubControlBtn({ label: '自动', isActive: this.acMode === 0 && this.isAcOn, activeColor: '#00E5FF', isNightMode: this.isNightMode, onClickAction: () => { if(this.isAcOn) { animateTo({duration:300}, () => this.acMode = 0); this.syncAcState(); } }})
                SubControlBtn({ label: '制冷', isActive: this.acMode === 1 && this.isAcOn, activeColor: '#1976D2', isNightMode: this.isNightMode, onClickAction: () => { if(this.isAcOn) { animateTo({duration:300}, () => this.acMode = 1); this.syncAcState(); } }})
                SubControlBtn({ label: '除湿', isActive: this.acMode === 2 && this.isAcOn, activeColor: '#7B61FF', isNightMode: this.isNightMode, onClickAction: () => { if(this.isAcOn) { animateTo({duration:300}, () => this.acMode = 2); this.syncAcState(); } }})
                SubControlBtn({ label: '送风', isActive: this.acMode === 3 && this.isAcOn, activeColor: '#00C853', isNightMode: this.isNightMode, onClickAction: () => { if(this.isAcOn) { animateTo({duration:300}, () => this.acMode = 3); this.syncAcState(); } }})
                SubControlBtn({ label: '制热', isActive: this.acMode === 4 && this.isAcOn, activeColor: '#FF9100', isNightMode: this.isNightMode, onClickAction: () => { if(this.isAcOn) { animateTo({duration:300}, () => this.acMode = 4); this.syncAcState(); } }})
              }.layoutWeight(1).justifyContent(FlexAlign.SpaceEvenly)
            }.width('100%').margin({ bottom: 16 })

            // 🌟 风速控制行 (极致简约的箭头与中文风速)
            Row() { Text('风速').fontSize(12).fontWeight(FontWeight.Medium).fontColor(this.isNightMode ? '#8899AA' : '#888').width(40)
              Row({ space: 20 }) {
                Button('<').width(40).height(40).fontSize(16).backgroundColor(this.isNightMode ? 'rgba(255,255,255,0.05)' : 'rgba(0,0,0,0.05)').fontColor(this.isNightMode ? '#FFF' : '#333').borderRadius(20)
                  .onClick(() => { if(this.isAcOn) { animateTo({duration:300}, () => { this.acFan = (this.acFan - 1 + 4) % 4; }); this.syncAcState(); } })

                Text(this.acFan === 0 ? '自动' : this.acFan === 1 ? '低风' : this.acFan === 2 ? '中风' : '高风')
                  .fontSize(16).fontWeight(FontWeight.Bold).fontColor(this.isAcOn ? (this.isNightMode ? '#00E5FF' : '#007799') : '#888')
                  .width(60).textAlign(TextAlign.Center).animation({duration: 300})

                Button('>').width(40).height(40).fontSize(16).backgroundColor(this.isNightMode ? 'rgba(255,255,255,0.05)' : 'rgba(0,0,0,0.05)').fontColor(this.isNightMode ? '#FFF' : '#333').borderRadius(20)
                  .onClick(() => { if(this.isAcOn) { animateTo({duration:300}, () => { this.acFan = (this.acFan + 1) % 4; }); this.syncAcState(); } })
              }.layoutWeight(1).justifyContent(FlexAlign.Center)
            }.width('100%')

          }
          .layoutWeight(45).height('100%').padding(24).backgroundColor(this.isNightMode ? '#1E222B' : '#FFFFFF')
          .borderRadius(24).border({ width: 1, color: this.isNightMode ? '#2A2E35' : '#E0E4E8' })

          Column({ space: 24 }) {
            Column({ space: 12 }) {
              Text('Smart Scenes & AI语音交互').fontSize(12).fontColor(this.isNightMode ? '#00E5FF' : '#007799').letterSpacing(2).alignSelf(ItemAlign.Start)
              Row({ space: 8 }) {
                TextInput({ placeholder: '在此输入或长按右侧按钮...', text: this.userInputIntent }).layoutWeight(1).height(40).borderRadius(20).backgroundColor(this.isNightMode ? '#2A2E35' : '#F5F7FA').fontColor(this.isNightMode ? '#FFF' : '#333').placeholderColor(this.isNightMode ? '#8899AA' : '#888').onChange((val) => this.userInputIntent = val).onSubmit(() => { if(this.userInputIntent.trim() !== '') this.triggerAiAssistant(this.userInputIntent); })
                Button(this.isListening ? '倾听中...' : '按住说话').width(96).height(40).borderRadius(20).fontSize(14).fontWeight(FontWeight.Bold).backgroundColor(this.isListening ? '#FF1744' : (this.isNightMode ? 'rgba(0, 229, 255, 0.2)' : 'rgba(0, 119, 153, 0.2)')).fontColor(this.isListening ? '#FFF' : (this.isNightMode ? '#00E5FF' : '#007799')).animation({duration: 300})
                  .onTouch(async (event: TouchEvent) => {
                    if (event.type === TouchType.Down) { this.isListening = true; this.userInputIntent = '正在录音...'; AudioCaptureUtil.startRecording(); }
                    else if (event.type === TouchType.Up || event.type === TouchType.Cancel) { this.isListening = false; this.isAiLoading = true; this.userInputIntent = '正在处理...'; let audioData = await AudioCaptureUtil.stopRecording(); if (!audioData || audioData.byteLength === 0) { this.isAiLoading = false; this.userInputIntent = ''; promptAction.showToast({ message: '⚠️ 未捕获音频数据' }); return; } let text = await AsrService.recognize(audioData); this.isAiLoading = false; if (text.trim() !== '') { this.userInputIntent = text.replace(/[。，？！]/g, ""); this.triggerAiAssistant(this.userInputIntent); } else { this.userInputIntent = ''; promptAction.showToast({ message: '❌ 识别失败' }); } }
                  })
              }.width('100%')

              Row({ space: 12 }) {
                SceneCard({ title: '回家模式', desc: '自动感光与温控', glowColor: this.isNightMode ? '#00E5FF' : '#007799', active: this.activeScene === '回家模式', isNightMode: this.isNightMode, onClickAction: () => { animateTo({ duration: 300 }, () => { this.activeScene = '回家模式'; this.isMainLightOn = true; this.isAcOn = true; }); DeviceManager.getInstance().sendCommand(new DeviceCommand(DeviceType.LIGHT, DeviceAction.POWER, true)); this.syncAcState(); }})
                SceneCard({ title: '离家模式', desc: '断电/开启安防', glowColor: '#FF1744', active: this.activeScene === '离家模式', isNightMode: this.isNightMode, onClickAction: () => { animateTo({ duration: 300 }, () => { this.activeScene = '离家模式'; this.isMainLightOn = false; this.isAcOn = false; this.isDoorLocked = true; this.isAutoAcOn = false; }); DeviceManager.getInstance().sendCommand(new DeviceCommand(DeviceType.LIGHT, DeviceAction.POWER, false)); DeviceManager.getInstance().sendCommand(new DeviceCommand(DeviceType.DOOR, DeviceAction.LOCK, true)); this.syncAcState(); }})
              }.width('100%').margin({top: 10})
            }

            Blank()

            Column({ space: 12 }) {
              Text('快捷设备').fontSize(12).fontColor(this.isNightMode ? '#00E5FF' : '#007799').letterSpacing(2).alignSelf(ItemAlign.Start)
              Row({ space: 12 }) {
                DeviceIconButton({ icon: '💡', name: '客厅主灯', stateText: this.isMainLightOn ? '已点亮' : '已关闭', isOn: this.isMainLightOn, activeColor: '#00FF00', isNightMode: this.isNightMode, toggleAction: (val) => { this.isMainLightOn = val; DeviceManager.getInstance().sendCommand(new DeviceCommand(DeviceType.LIGHT, DeviceAction.POWER, val)); } })
                DeviceIconButton({ icon: '🔓', name: '智能门锁', stateText: !this.isDoorLocked ? '已解锁' : '设防中', isOn: !this.isDoorLocked, activeColor: '#00E5FF', isNightMode: this.isNightMode, toggleAction: (val) => { if (val === true) { this.doorAuthController.open(); } else { this.isDoorLocked = true; DeviceManager.getInstance().sendCommand(new DeviceCommand(DeviceType.DOOR, DeviceAction.LOCK, true)); } } })
                DeviceIconButton({ icon: '🌡️', name: '自动温控', stateText: this.isAutoAcOn ? 'AI托管中' : '手动模式', isOn: this.isAutoAcOn, activeColor: '#7B61FF', isNightMode: this.isNightMode, toggleAction: (val) => { this.isAutoAcOn = val; DeviceManager.getInstance().sendCommand(new DeviceCommand(DeviceType.AC, DeviceAction.AUTO, val)); } })
              }.width('100%')
            }

            Button('⚙️ 模拟硬件JSON数据流转测试').width('100%').height(45).margin({ top: 20 }).backgroundColor('#7B61FF')
              .onClick(async () => {
                try {
                  let payload: Record<string, number> = {};
                  payload['temperature'] = 26.5;
                  payload['humidity'] = 55.0;
                  payload['light_mode'] = 1;

                  let mockJsonString = JSON.stringify(payload);
                  let cipherBytes = await CryptoUtil.encrypt(mockJsonString);
                  let decryptedText = await CryptoUtil.decrypt(cipherBytes);

                  let parsedData = JSON.parse(decryptedText) as Record<string, number>;
                  let temp = parsedData['temperature'];
                  let humi = parsedData['humidity'];
                  let light = parsedData['light_mode'] === 1 ? '已开启' : '已关闭';
                  promptAction.showToast({ message: `✅ JSON流转成功！\n温度:${temp}℃ 湿度:${humi}%\n客厅主灯:${light}`, duration: 3500 });
                } catch (e) {
                  promptAction.showToast({ message: '❌ JSON解析或解密失败，请检查数据格式！' });
                }
              })
          }
          .layoutWeight(55).height('100%').padding(24).backgroundColor(this.isNightMode ? '#1E222B' : '#FFFFFF')
          .borderRadius(24).border({ width: 1, color: this.isNightMode ? '#2A2E35' : '#E0E4E8' })

        }.width('100%').height(540)
      }.width('100%')
      Blank()
    }.width('100%').height('100%').padding(32)
  }
}