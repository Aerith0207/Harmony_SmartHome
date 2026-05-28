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

@Component
export struct ControlPage {
  // --- 空调状态 ---
  @State targetTemp: number = 24;
  @State currentTemp: number = 26;
  @State isAcOn: boolean = true;
  @State currentBrand: string = '美的';
  @State acMode: string = 'COOL';
  @State fanSpeed: string = 'AUTO';

  // --- 场景与设备状态 ---
  @State activeScene: string = '回家模式';
  @State isMainLightOn: boolean = false;
  @State isCurtainOpen: boolean = true;
  @State isPurifierOn: boolean = true;

  // 模拟发送底层硬件指令
  sendCommand(payload: string) {
    hilog.info(0x0000, 'SmartHome', `[MQTT Mock] 发送硬件指令: ${payload}`);
  }

  build() {
    Column() {
      Blank() // 顶部动态推挤，实现绝对垂直居中

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

          // ==========================================
          // 区域 1：深度定制的暖通空调面板 (左侧 45%)
          // ==========================================
          Column() {
            Text('HVAC Climate Control').fontSize(12).fontColor('#00E5FF').letterSpacing(2).margin({ bottom: 20 })

            // 温度设定圆环
            Stack() {
              Circle({ width: 200, height: 200 }).fill('transparent').stroke('rgba(0, 229, 255, 0.1)').strokeWidth(1)
              Circle({ width: 180, height: 180 }).fill('rgba(0,0,0,0.6)').shadow({ radius: 30, color: this.isAcOn ? 'rgba(0, 229, 255, 0.15)' : 'transparent' })

              Column() {
                Text('TARGET').fontSize(10).fontColor('#666')
                Text(`${this.targetTemp}℃`).fontSize(48).fontWeight(FontWeight.Bolder).fontColor(this.isAcOn ? '#00E5FF' : '#555').margin({ top: 4, bottom: 4 })
                Text(this.isAcOn ? `MODE: ${this.acMode}` : 'OFFLINE').fontSize(10).fontColor(this.isAcOn ? '#00FF00' : '#FF1744')
              }
            }.margin({ bottom: 20 })

            // 环境反馈比对
            Row({ space: 24 }) {
              Column({ space: 4 }) { Text('CURRENT').fontSize(10).fontColor('#666'); Text(`${this.currentTemp}℃`).fontSize(16).fontColor('#FFF').fontWeight(FontWeight.Bold) }.alignItems(HorizontalAlign.Center)
              Column({ space: 4 }) { Text('HUMIDITY').fontSize(10).fontColor('#666'); Text('45%').fontSize(16).fontColor('#FFF').fontWeight(FontWeight.Bold) }.alignItems(HorizontalAlign.Center)
            }.margin({ bottom: 24 })

            // 温度加减与电源控制
            Row({ space: 16 }) {
              Button('-').width(50).height(50).fontSize(20).backgroundColor('rgba(255,255,255,0.05)').fontColor('#FFF')
                .onClick(() => {
                  if(this.isAcOn) { this.targetTemp -= 1; this.sendCommand(ACFactory.getAC(this.currentBrand).getTempCommand(this.targetTemp)); }
                })
              Button(this.isAcOn ? 'POWER OFF' : 'POWER ON').width(110).height(50).fontSize(14).fontWeight(FontWeight.Bold).backgroundColor(this.isAcOn ? '#FF1744' : '#1976D2')
                .onClick(() => {
                  this.isAcOn = !this.isAcOn; this.sendCommand(ACFactory.getAC(this.currentBrand).getPowerCommand(this.isAcOn));
                })
              Button('+').width(50).height(50).fontSize(20).backgroundColor('rgba(255,255,255,0.05)').fontColor('#FFF')
                .onClick(() => {
                  if(this.isAcOn) { this.targetTemp += 1; this.sendCommand(ACFactory.getAC(this.currentBrand).getTempCommand(this.targetTemp)); }
                })
            }.margin({ bottom: 20 })

            // 风速与模式切换器
            Row({ space: 12 }) {
              this.SubControlBtn('COOL', this.acMode === 'COOL' && this.isAcOn, '#00E5FF', () => this.acMode = 'COOL')
              this.SubControlBtn('HEAT', this.acMode === 'HEAT' && this.isAcOn, '#FF9100', () => this.acMode = 'HEAT')
              this.SubControlBtn('DRY', this.acMode === 'DRY' && this.isAcOn, '#7B61FF', () => this.acMode = 'DRY')
              Text('|').fontColor('rgba(255,255,255,0.2)').margin({ left: 4, right: 4 })
              this.SubControlBtn('FAN: ' + this.fanSpeed, this.isAcOn, '#FFF', () => {
                this.fanSpeed = this.fanSpeed === 'AUTO' ? 'LOW' : (this.fanSpeed === 'LOW' ? 'HIGH' : 'AUTO');
              })
            }.width('100%').justifyContent(FlexAlign.Center)

          }
          .layoutWeight(45).height('100%').padding(24).backgroundColor('rgba(255,255,255,0.02)')
          .borderRadius(20).border({ width: 1, color: 'rgba(255,255,255,0.05)' })

          // ==========================================
          // 区域 2：场景矩阵与设备群控 (右侧 55%)
          // ==========================================
          Column({ space: 24 }) {

            // --- 2x2 场景网格 ---
            Column({ space: 12 }) {
              Text('Smart Scenes').fontSize(12).fontColor('#00E5FF').letterSpacing(2).alignSelf(ItemAlign.Start)
              Row({ space: 12 }) {
                this.SceneCard('回家模式', '联动灯光/空调', '#00E5FF', this.activeScene === '回家模式', () => this.activeScene = '回家模式')
                this.SceneCard('离家模式', '断电/开启安防', '#FF1744', this.activeScene === '离家模式', () => this.activeScene = '离家模式')
              }.width('100%')
              Row({ space: 12 }) {
                this.SceneCard('睡眠模式', '熄灯/空调静音', '#7B61FF', this.activeScene === '睡眠模式', () => this.activeScene = '睡眠模式')
                this.SceneCard('观影模式', '氛围灯/关窗帘', '#FF9100', this.activeScene === '观影模式', () => this.activeScene = '观影模式')
              }.width('100%')
            }

            Blank() // 弹性推挤

            // --- 独立设备群控列表 ---
            Column({ space: 12 }) {
              Text('End-Nodes Direct Link').fontSize(12).fontColor('#00E5FF').letterSpacing(2).alignSelf(ItemAlign.Start)

              Column({ space: 8 }) {
                this.DeviceToggle('客厅主灯', '全彩吸顶灯/继电器', this.isMainLightOn, '#00FF00', (val) => {
                  this.isMainLightOn = val; this.sendCommand(`{"device":"light", "cmd":"power", "val": ${val ? 1 : 0}}`);
                })
                this.DeviceToggle('智能窗帘', '超静音开合帘电机', this.isCurtainOpen, '#00E5FF', (val) => {
                  this.isCurtainOpen = val; this.sendCommand(`{"device":"curtain", "cmd":"open", "val": ${val ? 1 : 0}}`);
                })
                this.DeviceToggle('空气净化器', 'HEPA 滤网/负离子', this.isPurifierOn, '#7B61FF', (val) => {
                  this.isPurifierOn = val; this.sendCommand(`{"device":"purifier", "cmd":"power", "val": ${val ? 1 : 0}}`);
                })
              }
              .width('100%').padding(16).backgroundColor('rgba(255,255,255,0.02)')
              .borderRadius(16).border({ width: 1, color: 'rgba(255,255,255,0.05)' })
            }

          }.layoutWeight(55).height('100%')

        }.width('100%').height(540)
      }.width('100%')

      Blank() // 底部动态推挤
    }.width('100%').height('100%').padding(32)
  }

  // ==========================================
  // 组件库 (Builders)
  // ==========================================

  // 空调面板底部的小控制按钮
  @Builder SubControlBtn(label: string, isActive: boolean, activeColor: string, onClickAction: () => void) {
    Text(label)
      .fontSize(10).fontWeight(FontWeight.Bold)
      .fontColor(isActive ? activeColor : '#666')
      .padding({ top: 6, bottom: 6, left: 12, right: 12 })
      .backgroundColor(isActive ? `rgba(${this.hexToRgb(activeColor)}, 0.1)` : 'rgba(255,255,255,0.02)')
      .borderRadius(12).border({ width: 1, color: isActive ? activeColor : 'rgba(255,255,255,0.05)' })
      .onClick(onClickAction)
  }

  // 🌟 已修复：场景网格卡片 (恢复 Toggle 且支持全卡片点击互斥)
  @Builder SceneCard(title: string, desc: string, glowColor: string, active: boolean, onClickAction: () => void) {
    Row() {
      Column() {
        Text(title).fontSize(15).fontWeight(FontWeight.Bold).fontColor(active ? glowColor : '#FFF')
        Text(desc).fontSize(10).fontColor('#8899AA').margin({ top: 4 })
      }.alignItems(HorizontalAlign.Start).layoutWeight(1)

      // 使用 Toggle 恢复开关视觉，并通过 HitTestMode.Block 将点击事件全部交给外层 Row 接管
      Toggle({ type: ToggleType.Switch, isOn: active })
        .selectedColor(glowColor)
        .hitTestBehavior(HitTestMode.Block)
    }
    .layoutWeight(1).padding(16).backgroundColor('rgba(255,255,255,0.02)')
    .borderRadius(12).border({ width: 1, color: active ? glowColor : 'rgba(255,255,255,0.05)' })
    .onClick(() => {
      onClickAction();
    })
  }

  // 独立设备控制条
  @Builder DeviceToggle(name: string, desc: string, isOn: boolean, color: string, toggleAction: (val: boolean) => void) {
    Row() {
      Row({ space: 12 }) {
        Circle({ width: 6, height: 6 }).fill(isOn ? color : '#555').shadow({ radius: isOn ? 8 : 0, color: color })
        Column() {
          Text(name).fontSize(14).fontWeight(FontWeight.Bold).fontColor('#FFF')
          Text(desc).fontSize(10).fontColor('#667788').margin({ top: 2 })
        }.alignItems(HorizontalAlign.Start)
      }
      Blank()
      Toggle({ type: ToggleType.Switch, isOn: isOn }).selectedColor(color).onChange(toggleAction)
    }.width('100%').padding({ top: 8, bottom: 8 })
  }

  // 辅助函数：将 Hex 转为 RGB 方便设置透明度
  hexToRgb(hex: string): string {
    let r = parseInt(hex.slice(1, 3), 16);
    let g = parseInt(hex.slice(3, 5), 16);
    let b = parseInt(hex.slice(5, 7), 16);
    return `${r}, ${g}, ${b}`;
  }
}