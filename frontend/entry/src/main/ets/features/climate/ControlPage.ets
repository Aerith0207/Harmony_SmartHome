// frontend/entry/src/main/ets/features/climate/ControlPage.ets
import hilog from '@ohos.hilog';
import { MqttBusService } from '../../network/mqtt';

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

// ==========================================
// 主页面容器
// ==========================================

@Component
export struct ControlPage {
  @State targetTemp: number = 24;
  @State currentTemp: number = 26;
  @State isAcOn: boolean = true;
  @State acMode: string = 'COOL';
  @State fanSpeed: string = 'AUTO';

  @State activeScene: string = '回家模式';
  @State isMainLightOn: boolean = false;
  @State isDoorOpen: boolean = false; // 对应硬件协议的 door
  @State isAutoAcOn: boolean = false; // 对应硬件协议的 auto_ac

  // 🌟 修改发送方法的接收类型，直接处理对象
  sendCommand(payloadObj: Record<string, string | number>) {
    hilog.info(0x0000, 'SmartHome', `[MQTT] 准备下发指令: ${JSON.stringify(payloadObj)}`);
    try {
      MqttBusService.getInstance().publishCommand(payloadObj);
    } catch (e) {
      hilog.error(0x0000, 'SmartHome', '指令下发异常');
    }
  }

  build() {
    Column() {
      Blank()

      Column({ space: 24 }) {
        // --- 标题 ---
        Row() {
          Text('分布式硬件指令中枢').fontSize(24).fontWeight(FontWeight.Bold).fontColor('#FFF')
          Blank()
          Text('Protocol: hi3861_v1').fontColor('#A0AAB5').fontSize(12).fontFamily('monospace')
        }.width('100%')

        // --- 核心控制交互区 ---
        Row({ space: 24 }) {

          // 区域 1：暖通空调面板
          Column() {
            Text('HVAC Climate Control').fontSize(12).fontColor('#00E5FF').letterSpacing(2).margin({ bottom: 20 })

            Stack() {
              Circle({ width: 200, height: 200 }).fill('transparent').stroke('rgba(0, 229, 255, 0.1)').strokeWidth(1)
              Circle({ width: 180, height: 180 }).fill('rgba(0,0,0,0.6)')
                .shadow({ radius: this.isAcOn ? 80 : 0, color: this.isAcOn ? 'rgba(0, 229, 255, 0.4)' : 'transparent' })
                .animation({ duration: 600, curve: Curve.FastOutSlowIn })

              Column() {
                Text('TARGET').fontSize(10).fontColor('#666')
                Text(`${this.targetTemp}℃`).fontSize(48).fontWeight(FontWeight.Bolder).fontColor(this.isAcOn ? '#00E5FF' : '#555').margin({ top: 4, bottom: 4 })
                  .animation({ duration: 400, curve: Curve.EaseInOut })
                Text(this.isAcOn ? `MODE: ${this.acMode}` : 'OFFLINE').fontSize(10).fontColor(this.isAcOn ? '#00FF00' : '#FF1744')
                  .animation({ duration: 400 })
              }
            }.margin({ bottom: 20 })

            Row({ space: 24 }) {
              Column({ space: 4 }) { Text('CURRENT').fontSize(10).fontColor('#666'); Text(`${this.currentTemp}℃`).fontSize(16).fontColor('#FFF').fontWeight(FontWeight.Bold) }.alignItems(HorizontalAlign.Center)
              Column({ space: 4 }) { Text('HUMIDITY').fontSize(10).fontColor('#666'); Text('45%').fontSize(16).fontColor('#FFF').fontWeight(FontWeight.Bold) }.alignItems(HorizontalAlign.Center)
            }.margin({ bottom: 24 })

            Row({ space: 16 }) {
              Button('-').width(50).height(50).fontSize(20).backgroundColor('rgba(255,255,255,0.05)').fontColor('#FFF')
                .onClick(() => {
                  if(this.isAcOn) {
                    animateTo({ duration: 300, curve: Curve.EaseInOut }, () => { this.targetTemp -= 1; });
                    // 🌟 硬件指令：设定温度
                    this.sendCommand({ "cmd": "ac_set", "value": this.targetTemp });
                  }
                })
              Button(this.isAcOn ? 'POWER OFF' : 'POWER ON').width(110).height(50).fontSize(14).fontWeight(FontWeight.Bold)
                .backgroundColor(this.isAcOn ? '#FF1744' : '#1976D2')
                .animation({ duration: 600, curve: Curve.EaseOut })
                .onClick(() => {
                  animateTo({ duration: 600, curve: Curve.FastOutSlowIn }, () => { this.isAcOn = !this.isAcOn; });
                  // 🌟 硬件指令：空调开关
                  this.sendCommand({ "cmd": this.isAcOn ? "ac_on" : "ac_off", "value": 0 });
                })
              Button('+').width(50).height(50).fontSize(20).backgroundColor('rgba(255,255,255,0.05)').fontColor('#FFF')
                .onClick(() => {
                  if(this.isAcOn) {
                    animateTo({ duration: 300, curve: Curve.EaseInOut }, () => { this.targetTemp += 1; });
                    // 🌟 硬件指令：设定温度
                    this.sendCommand({ "cmd": "ac_set", "value": this.targetTemp });
                  }
                })
            }.margin({ bottom: 20 })

            Row({ space: 12 }) {
              SubControlBtn({ label: 'COOL', isActive: this.acMode === 'COOL' && this.isAcOn, activeColor: '#00E5FF', onClickAction: () => { animateTo({duration:300}, () => this.acMode = 'COOL') } })
              SubControlBtn({ label: 'HEAT', isActive: this.acMode === 'HEAT' && this.isAcOn, activeColor: '#FF9100', onClickAction: () => { animateTo({duration:300}, () => this.acMode = 'HEAT') } })
              SubControlBtn({ label: 'DRY', isActive: this.acMode === 'DRY' && this.isAcOn, activeColor: '#7B61FF', onClickAction: () => { animateTo({duration:300}, () => this.acMode = 'DRY') } })
            }.width('100%').justifyContent(FlexAlign.Center)

          }
          .layoutWeight(45).height('100%').padding(24).backgroundColor('rgba(255,255,255,0.02)')
          .borderRadius(20).border({ width: 1, color: 'rgba(255,255,255,0.05)' })

          // 区域 2：场景矩阵与设备群控
          Column({ space: 24 }) {

            Column({ space: 12 }) {
              Text('Smart Scenes').fontSize(12).fontColor('#00E5FF').letterSpacing(2).alignSelf(ItemAlign.Start)
              Row({ space: 12 }) {
                SceneCard({ title: '回家模式', desc: '自动感光与温控', glowColor: '#00E5FF', active: this.activeScene === '回家模式', onClickAction: () => {
                  animateTo({ duration: 300, curve: Curve.EaseInOut }, () => { this.activeScene = '回家模式'; });
                  // 示例联动：打开自动灯光和自动空调
                  this.sendCommand({ "cmd": "auto_light_on", "value": 0 });
                  this.sendCommand({ "cmd": "auto_ac_on", "value": 0 });
                }})
                SceneCard({ title: '离家模式', desc: '断电/开启安防', glowColor: '#FF1744', active: this.activeScene === '离家模式', onClickAction: () => {
                  animateTo({ duration: 300, curve: Curve.EaseInOut }, () => { this.activeScene = '离家模式'; });
                  // 示例联动：关闭所有设备
                  this.sendCommand({ "cmd": "light_off", "value": 0 });
                  this.sendCommand({ "cmd": "ac_off", "value": 0 });
                  this.sendCommand({ "cmd": "door_close", "value": 0 });
                }})
              }.width('100%')
              Row({ space: 12 }) {
                SceneCard({ title: '睡眠模式', desc: '熄灯/恒温', glowColor: '#7B61FF', active: this.activeScene === '睡眠模式', onClickAction: () => { animateTo({ duration: 300, curve: Curve.EaseInOut }, () => { this.activeScene = '睡眠模式'; }) } })
                SceneCard({ title: '观影模式', desc: '环境灯/静音', glowColor: '#FF9100', active: this.activeScene === '观影模式', onClickAction: () => { animateTo({ duration: 300, curve: Curve.EaseInOut }, () => { this.activeScene = '观影模式'; }) } })
              }.width('100%')
            }

            Blank()

            Column({ space: 12 }) {
              Text('End-Nodes Direct Link').fontSize(12).fontColor('#00E5FF').letterSpacing(2).alignSelf(ItemAlign.Start)

              Column({ space: 8 }) {
                DeviceToggle({ name: '客厅主灯', desc: '全彩吸顶灯/继电器', isOn: this.isMainLightOn, color: '#00FF00', toggleAction: (val) => {
                  this.isMainLightOn = val;
                  // 🌟 硬件指令：开灯/关灯
                  this.sendCommand({ "cmd": val ? "light_on" : "light_off", "value": 0 });
                }})
                DeviceToggle({ name: '智能门锁', desc: '入户门禁控制', isOn: this.isDoorOpen, color: '#00E5FF', toggleAction: (val) => {
                  this.isDoorOpen = val;
                  // 🌟 硬件指令：开门/关门
                  this.sendCommand({ "cmd": val ? "door_open" : "door_close", "value": 0 });
                }})
                DeviceToggle({ name: '自动温控', desc: 'AI环境感知调节', isOn: this.isAutoAcOn, color: '#7B61FF', toggleAction: (val) => {
                  this.isAutoAcOn = val;
                  // 🌟 硬件指令：自动空调模式
                  this.sendCommand({ "cmd": val ? "auto_ac_on" : "auto_ac_off", "value": 0 });
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