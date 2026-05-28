// frontend/entry/src/main/ets/features/climate/ControlPage.ets
import hilog from '@ohos.hilog';

// ==========================================
// 架构层：设备控制抽象与工厂模式
// ==========================================
interface IAirConditioner {
  getPowerCommand(isOn: boolean): string;
  getTempCommand(temp: number): string;
}

class MideaAC implements IAirConditioner {
  getPowerCommand(isOn: boolean) { return `{"brand":"midea", "cmd":"power", "val": ${isOn ? 1 : 0}}`; }
  getTempCommand(temp: number) { return `{"brand":"midea", "cmd":"temp", "val": ${temp}}`; }
}
class GreeAC implements IAirConditioner {
  getPowerCommand(isOn: boolean) { return `{"brand":"gree", "cmd":"power", "val": ${isOn ? 1 : 0}}`; }
  getTempCommand(temp: number) { return `{"brand":"gree", "cmd":"temp", "val": ${temp}}`; }
}
class HaierAC implements IAirConditioner {
  getPowerCommand(isOn: boolean) { return `{"brand":"haier", "cmd":"power", "val": ${isOn ? 1 : 0}}`; }
  getTempCommand(temp: number) { return `{"brand":"haier", "cmd":"temp", "val": ${temp}}`; }
}

class ACFactory {
  static getAC(brand: string): IAirConditioner {
    if (brand === '格力') return new GreeAC();
    if (brand === '海尔') return new HaierAC();
    return new MideaAC();
  }
}

// ==========================================
// 提取出的独立响应式组件 (彻底解决高亮卡死问题)
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
      .animation({ duration: 300, curve: Curve.EaseInOut }) // 动画加持
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
  @State currentBrand: string = '美的';
  @State acMode: string = 'COOL';
  @State fanSpeed: string = 'AUTO';

  @State activeScene: string = '回家模式';
  @State isMainLightOn: boolean = false;
  @State isCurtainOpen: boolean = true;
  @State isPurifierOn: boolean = true;

  sendCommand(payload: string) {
    hilog.info(0x0000, 'SmartHome', `[MQTT Mock] 发送硬件指令: ${payload}`);
  }

  build() {
    Column() {
      Blank()

      Column({ space: 24 }) {
        // --- 标题与协议选择区 ---
        Row() {
          Text('分布式硬件指令中枢').fontSize(24).fontWeight(FontWeight.Bold).fontColor('#FFF')
          Blank()
          Row({ space: 8 }) {
            Text('接入协议:').fontColor('#A0AAB5').fontSize(12)
            Select([{ value: '美的' }, { value: '格力' }, { value: '海尔' }])
              .selected(0)
              .value(this.currentBrand)
              .font({ size: 14, weight: 500 })
              .fontColor('#00E5FF')
              .backgroundColor('rgba(255,255,255,0.05)')
              .onSelect((index: number, value: string) => {
                this.currentBrand = value;
                hilog.info(0x0000, 'SmartHome', `切换至 ${value} 空调控制协议`);
              })
          }
        }.width('100%')

        // --- 核心控制交互区 ---
        Row({ space: 24 }) {

          // 区域 1：深度定制的暖通空调面板
          Column() {
            Text('HVAC Climate Control').fontSize(12).fontColor('#00E5FF').letterSpacing(2).margin({ bottom: 20 })

            // 温度设定圆环 (增强光晕)
            Stack() {
              Circle({ width: 200, height: 200 }).fill('transparent').stroke('rgba(0, 229, 255, 0.1)').strokeWidth(1)
              Circle({ width: 180, height: 180 }).fill('rgba(0,0,0,0.6)')
              // 增强点：阴影发光半径提升至80，颜色更浓
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

            // 环境反馈比对 (保持不变)
            Row({ space: 24 }) {
              Column({ space: 4 }) { Text('CURRENT').fontSize(10).fontColor('#666'); Text(`${this.currentTemp}℃`).fontSize(16).fontColor('#FFF').fontWeight(FontWeight.Bold) }.alignItems(HorizontalAlign.Center)
              Column({ space: 4 }) { Text('HUMIDITY').fontSize(10).fontColor('#666'); Text('45%').fontSize(16).fontColor('#FFF').fontWeight(FontWeight.Bold) }.alignItems(HorizontalAlign.Center)
            }.margin({ bottom: 24 })

            // 温度加减与电源控制 (增强切换动效)
            Row({ space: 16 }) {
              Button('-').width(50).height(50).fontSize(20).backgroundColor('rgba(255,255,255,0.05)').fontColor('#FFF')
                .onClick(() => {
                  if(this.isAcOn) {
                    animateTo({ duration: 300, curve: Curve.EaseInOut }, () => { this.targetTemp -= 1; });
                    this.sendCommand(ACFactory.getAC(this.currentBrand).getTempCommand(this.targetTemp));
                  }
                })
              Button(this.isAcOn ? 'POWER OFF' : 'POWER ON').width(110).height(50).fontSize(14).fontWeight(FontWeight.Bold)
                .backgroundColor(this.isAcOn ? '#FF1744' : '#1976D2')
                // 增强点：电源按钮颜色的过渡时间延长
                .animation({ duration: 600, curve: Curve.EaseOut })
                .onClick(() => {
                  animateTo({ duration: 600, curve: Curve.FastOutSlowIn }, () => {
                    this.isAcOn = !this.isAcOn;
                  });
                  let cmd = ACFactory.getAC(this.currentBrand).getPowerCommand(this.isAcOn);
                  this.sendCommand(cmd);
                })
              Button('+').width(50).height(50).fontSize(20).backgroundColor('rgba(255,255,255,0.05)').fontColor('#FFF')
                .onClick(() => {
                  if(this.isAcOn) {
                    animateTo({ duration: 300, curve: Curve.EaseInOut }, () => { this.targetTemp += 1; });
                    this.sendCommand(ACFactory.getAC(this.currentBrand).getTempCommand(this.targetTemp));
                  }
                })
            }.margin({ bottom: 20 })

            // 🌟 修正：现在调用的是独立的 @Component
            Row({ space: 12 }) {
              SubControlBtn({ label: 'COOL', isActive: this.acMode === 'COOL' && this.isAcOn, activeColor: '#00E5FF', onClickAction: () => { animateTo({duration:300}, () => this.acMode = 'COOL') } })
              SubControlBtn({ label: 'HEAT', isActive: this.acMode === 'HEAT' && this.isAcOn, activeColor: '#FF9100', onClickAction: () => { animateTo({duration:300}, () => this.acMode = 'HEAT') } })
              SubControlBtn({ label: 'DRY', isActive: this.acMode === 'DRY' && this.isAcOn, activeColor: '#7B61FF', onClickAction: () => { animateTo({duration:300}, () => this.acMode = 'DRY') } })
              Text('|').fontColor('rgba(255,255,255,0.2)').margin({ left: 4, right: 4 })
              SubControlBtn({ label: 'FAN: ' + this.fanSpeed, isActive: this.isAcOn, activeColor: '#FFF', onClickAction: () => {
                animateTo({duration:300}, () => {
                  this.fanSpeed = this.fanSpeed === 'AUTO' ? 'LOW' : (this.fanSpeed === 'LOW' ? 'HIGH' : 'AUTO');
                })
              }})
            }.width('100%').justifyContent(FlexAlign.Center)

          }
          .layoutWeight(45).height('100%').padding(24).backgroundColor('rgba(255,255,255,0.02)')
          .borderRadius(20).border({ width: 1, color: 'rgba(255,255,255,0.05)' })

          // 区域 2：场景矩阵与设备群控
          Column({ space: 24 }) {

            Column({ space: 12 }) {
              Text('Smart Scenes').fontSize(12).fontColor('#00E5FF').letterSpacing(2).alignSelf(ItemAlign.Start)
              Row({ space: 12 }) {
                SceneCard({ title: '回家模式', desc: '联动灯光/空调', glowColor: '#00E5FF', active: this.activeScene === '回家模式', onClickAction: () => { animateTo({ duration: 300, curve: Curve.EaseInOut }, () => { this.activeScene = '回家模式'; }) } })
                SceneCard({ title: '离家模式', desc: '断电/开启安防', glowColor: '#FF1744', active: this.activeScene === '离家模式', onClickAction: () => { animateTo({ duration: 300, curve: Curve.EaseInOut }, () => { this.activeScene = '离家模式'; }) } })
              }.width('100%')
              Row({ space: 12 }) {
                SceneCard({ title: '睡眠模式', desc: '熄灯/空调静音', glowColor: '#7B61FF', active: this.activeScene === '睡眠模式', onClickAction: () => { animateTo({ duration: 300, curve: Curve.EaseInOut }, () => { this.activeScene = '睡眠模式'; }) } })
                SceneCard({ title: '观影模式', desc: '氛围灯/关窗帘', glowColor: '#FF9100', active: this.activeScene === '观影模式', onClickAction: () => { animateTo({ duration: 300, curve: Curve.EaseInOut }, () => { this.activeScene = '观影模式'; }) } })
              }.width('100%')
            }

            Blank()

            Column({ space: 12 }) {
              Text('End-Nodes Direct Link').fontSize(12).fontColor('#00E5FF').letterSpacing(2).alignSelf(ItemAlign.Start)

              Column({ space: 8 }) {
                DeviceToggle({ name: '客厅主灯', desc: '全彩吸顶灯/继电器', isOn: this.isMainLightOn, color: '#00FF00', toggleAction: (val) => {
                  this.isMainLightOn = val; this.sendCommand(`{"device":"light", "cmd":"power", "val": ${val ? 1 : 0}}`);
                }})
                DeviceToggle({ name: '智能窗帘', desc: '超静音开合帘电机', isOn: this.isCurtainOpen, color: '#00E5FF', toggleAction: (val) => {
                  this.isCurtainOpen = val; this.sendCommand(`{"device":"curtain", "cmd":"open", "val": ${val ? 1 : 0}}`);
                }})
                DeviceToggle({ name: '空气净化器', desc: 'HEPA 滤网/负离子', isOn: this.isPurifierOn, color: '#7B61FF', toggleAction: (val) => {
                  this.isPurifierOn = val; this.sendCommand(`{"device":"purifier", "cmd":"power", "val": ${val ? 1 : 0}}`);
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