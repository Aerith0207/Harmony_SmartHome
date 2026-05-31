// frontend/entry/src/main/ets/features/home/HomePage.ets

import { MqttBusService } from '../../network/mqtt';
import { SensorDataModel } from '../../models/DeviceModels';

// ==========================================
// 独立响应式组件区 (解决数据无法更新的问题)
// ==========================================
@Component
struct MiniBarChart {
  @Prop title: string;
  @Prop dataArray: number[];
  @Prop color: string;

  build() {
    Column({ space: 12 }) {
      Row() {
        Text(this.title).fontSize(12).fontColor('#8899AA')
        Blank()
        Row({ space: 4 }) {
          Circle({ width: 4, height: 4 }).fill(this.color)
          Text('LIVE').fontSize(10).fontColor(this.color).fontWeight(FontWeight.Bold)
        }
      }.width('100%')

      Row({ space: 6 }) {
        ForEach(this.dataArray, (val: number, idx: number) => {
          Column()
            .width(8)
            .height(`${val}%`)
            .backgroundColor(this.color)
            .borderRadius({ topLeft: 2, topRight: 2 })
            .opacity(0.2 + (idx / this.dataArray.length) * 0.8)
            .animation({ duration: 300, curve: Curve.EaseInOut })
        }, (val: number, idx: number) => idx.toString() + '_' + val.toString())
      }
      .width('100%')
      .height(48)
      .alignItems(VerticalAlign.Bottom)
      .border({ width: { bottom: 1 }, color: 'rgba(255,255,255,0.1)' })
    }
    .layoutWeight(1)
    .padding(16)
    .backgroundColor('rgba(255,255,255,0.01)')
    .borderRadius(12)
    .border({ width: 1, color: 'rgba(255,255,255,0.03)' })
  }
}

@Component
struct DeviceTag {
  @Prop name: string;
  @Prop color: string;
  @Prop active: boolean;

  build() {
    Row({ space: 6 }) {
      Circle({ width: 6, height: 6 }).fill(this.color).shadow({ radius: this.active ? 10 : 0, color: this.color })
        .animation({ duration: 300, curve: Curve.EaseInOut })
      Text(this.name).fontSize(11).fontWeight(FontWeight.Bold).fontColor(this.active ? '#FFF' : 'rgba(255,255,255,0.4)')
        .animation({ duration: 300 })
    }
    .padding({ left: 10, right: 10, top: 4, bottom: 4 })
    .backgroundColor('rgba(0,0,0,0.4)')
    .borderRadius(12)
    .border({ width: 1, color: this.active ? 'rgba(255,255,255,0.1)' : 'rgba(255,255,255,0.02)' })
  }
}

@Component
struct RoomGrid {
  @Prop name: string;
  @Prop mainVal: string;
  @Prop mainUnit: string;
  @Prop sub1Lbl: string;
  @Prop sub1Val: string;
  @Prop sub2Lbl: string;
  @Prop sub2Val: string;
  @Prop dev1Name: string;
  @Prop dev1Color: string;
  @Prop dev1Active: boolean;
  @Prop dev2Name: string = '';
  @Prop dev2Color: string = '';
  @Prop dev2Active: boolean = false;

  build() {
    Column({ space: 12 }) {
      Column({ space: 8 }) {
        Row({ space: 8 }) {
          Rect().width(4).height(16).fill('#00E5FF').radius(2)
          Text(this.name).fontSize(18).fontColor('#FFF').fontWeight(FontWeight.Bolder).letterSpacing(1)
        }.alignItems(VerticalAlign.Center)

        Row({ space: 4 }) {
          Text(this.mainVal).fontSize(26).fontWeight(FontWeight.Bolder).fontColor('#FFF')
            .animation({ duration: 500, curve: Curve.FastOutSlowIn })
          Text(this.mainUnit).fontSize(12).fontColor('#00E5FF').margin({ bottom: 4 })
        }.alignItems(VerticalAlign.Bottom)
      }.alignItems(HorizontalAlign.Center)

      Row({ space: 24 }) {
        Column({ space: 4 }) { Text(this.sub1Lbl).fontSize(10).fontColor('#667788'); Text(this.sub1Val).fontSize(12).fontWeight(FontWeight.Bold).fontColor('#A0AAB5') }.alignItems(HorizontalAlign.Center)
        Column({ space: 4 }) { Text(this.sub2Lbl).fontSize(10).fontColor('#667788'); Text(this.sub2Val).fontSize(12).fontWeight(FontWeight.Bold).fontColor('#A0AAB5') }.alignItems(HorizontalAlign.Center)
      }.justifyContent(FlexAlign.Center)

      Divider().color('rgba(255,255,255,0.05)').width('40%')

      Row({ space: 12 }) {
        DeviceTag({ name: this.dev1Name, color: this.dev1Color, active: this.dev1Active })
        if (this.dev2Name !== '') {
          DeviceTag({ name: this.dev2Name, color: this.dev2Color, active: this.dev2Active })
        }
      }
    }
    .layoutWeight(1).height('100%').border({ width: 1, color: 'rgba(255,255,255,0.03)' })
    .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
  }
}

// ==========================================
// 主页面容器
// ==========================================

@Component
export struct HomePage {
  @State currentTime: string = '';
  @State cpuLoad: number = 32;
  @State aiLog: string = 'SYSTEM STANDBY';
  @State aiLogColor: string = '#00E5FF';

  // 🌟 将所有硬件状态接入全局总线
  @StorageLink('global_realTemp') realTemp: string = '26.0';
  @StorageLink('global_realHum') realHum: string = '45.0';
  @StorageLink('global_isDoorLocked') isDoorLocked: boolean = true;
  @StorageLink('global_isMainLightOn') isMainLightOn: boolean = false;
  @StorageLink('global_isAcOn') isAcOn: boolean = false;
  @StorageLink('global_acTemp') acTemp: number = 26;
  @StorageLink('global_isAutoAcOn') isAutoAcOn: boolean = false;

  @StorageLink('global_tempTrend') tempTrendData: number[] = [45, 50, 48, 55, 60, 58, 65, 60, 70, 68, 75, 70, 65, 60, 55, 58, 62, 65, 60, 55];
  @StorageLink('global_cryptoTraffic') cryptoTrafficData: number[] = [20, 80, 35, 90, 15, 60, 45, 75, 25, 85, 55, 40, 70, 30, 65, 20, 80, 40, 95, 30];

  aboutToAppear() {
    MqttBusService.getInstance().registerSensorListener((data: SensorDataModel) => {
      animateTo({ duration: 500, curve: Curve.EaseInOut }, () => {
        // 🌟 将解析好的模型数据强行覆盖给 UI
        this.realTemp = data.temperature.toFixed(1);
        this.realHum = data.humidity.toFixed(1);
        this.isDoorLocked = !data.doorOpen;
        this.isMainLightOn = data.lightStatus;
        this.isAcOn = data.acStatus;
        this.acTemp = data.acTemp;
        this.isAutoAcOn = data.autoAc;

        let newTempChart = [...this.tempTrendData];
        newTempChart.shift();
        newTempChart.push(data.temperature);
        this.tempTrendData = newTempChart;
      });
    });

    setInterval(() => {
      let date = new Date();
      this.currentTime = `${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}:${date.getSeconds().toString().padStart(2, '0')}`;
      this.cpuLoad = Math.floor(Math.random() * 20) + 20;

      animateTo({ duration: 800, curve: Curve.Linear }, () => {
        let newCryptoChart = [...this.cryptoTrafficData];
        newCryptoChart.shift();
        newCryptoChart.push(Math.floor(Math.random() * 80) + 20);
        this.cryptoTrafficData = newCryptoChart;
      });
    }, 1000);

    setTimeout(() => {
      animateTo({ duration: 500, curve: Curve.EaseInOut }, () => {
        this.aiLog = '[AI SCENE] 边缘网关态势感知网络已就绪';
        this.aiLogColor = '#00FF00';
      });
    }, 5000);
  }

  build() {
    Column({ space: 20 }) {
      // 1. 顶部状态栏
      Row() {
        Column() {
          Text('全屋生态态势感知中枢').fontSize(24).fontWeight(FontWeight.Bold).fontColor('#FFF')
          Text('AI ECOSYSTEM OPERATION MONITOR').fontSize(10).fontColor('#00E5FF').letterSpacing(2).margin({ top: 4 })
        }.alignItems(HorizontalAlign.Start)
        Blank()
        Row({ space: 24 }) {
          this.StatusIndicator('GATEWAY', 'ONLINE 🟢', '#00FF00')
          this.StatusIndicator('SECURITY', 'AES-256 🔒', '#7B61FF')
          this.StatusIndicator('CPU LOAD', `${this.cpuLoad}% ⚡`, '#FF9100')
          Text(this.currentTime).fontFamily('monospace').fontSize(28).fontColor('#FFF').fontWeight(FontWeight.Bold)
        }
      }
      .width('100%').padding({ bottom: 20 }).border({ width: { bottom: 1 }, color: 'rgba(255,255,255,0.08)' })

      Column({ space: 30 }) {
        Column() {
          Text('全息空间设备拓扑').fontSize(14).fontColor('#A0AAB5').margin({ bottom: 16 }).alignSelf(ItemAlign.Start)

          Column() {
            Row() {
              RoomGrid({
                name: '主卧区', mainVal: this.realTemp, mainUnit: '℃',
                sub1Lbl: '相对湿度', sub1Val: `${this.realHum}%`, sub2Lbl: '空气质量', sub2Val: '优',
                dev1Name: '美的空调', dev1Color: '#00E5FF', dev1Active: this.isAcOn,
                dev2Name: '智能窗帘', dev2Color: '#7B61FF', dev2Active: false
              })
              RoomGrid({
                name: '客厅中枢', mainVal: '24.5', mainUnit: '℃',
                sub1Lbl: 'PM 2.5', sub1Val: '12', sub2Lbl: '当前功耗', sub2Val: '120W',
                dev1Name: '人体感应', dev1Color: '#FF1744', dev1Active: true,
                dev2Name: '主灯群组', dev2Color: '#00FF00', dev2Active: this.isMainLightOn
              })
            }.width('100%').layoutWeight(1)

            Row() {
              RoomGrid({
                name: '厨房安防', mainVal: '正常', mainUnit: 'ENV',
                sub1Lbl: '燃气浓度', sub1Val: '0%', sub2Lbl: '烟雾探测', sub2Val: '正常',
                dev1Name: '烟雾报警', dev1Color: '#FF1744', dev1Active: true,
                dev2Name: '智能插座', dev2Color: '#00E5FF', dev2Active: true
              })

              Column({ space: 12 }) {
                Column({ space: 8 }) {
                  Row({ space: 8 }) {
                    Rect().width(4).height(16).fill('#00E5FF').radius(2)
                    Text('玄关门禁').fontSize(18).fontColor('#FFF').fontWeight(FontWeight.Bolder).letterSpacing(1)
                  }.alignItems(VerticalAlign.Center)

                  Row({ space: 4 }) {
                    Text(this.isDoorLocked ? '设防中' : '已解锁').fontSize(26).fontWeight(FontWeight.Bolder).fontColor(this.isDoorLocked ? '#00E5FF' : '#FF1744')
                    Text('STATUS').fontSize(10).fontColor('#667788').margin({ bottom: 4 })
                  }.alignItems(VerticalAlign.Bottom)
                }.alignItems(HorizontalAlign.Center)

                Row({ space: 24 }) {
                  Column({ space: 4 }) { Text('门锁电量').fontSize(10).fontColor('#667788'); Text('85%').fontSize(12).fontWeight(FontWeight.Bold).fontColor('#A0AAB5') }.alignItems(HorizontalAlign.Center)
                  Column({ space: 4 }) { Text('门磁状态').fontSize(10).fontColor('#667788'); Text(this.isDoorLocked ? '闭合' : '开启').fontSize(12).fontWeight(FontWeight.Bold).fontColor('#A0AAB5') }.alignItems(HorizontalAlign.Center)
                }.justifyContent(FlexAlign.Center)

                Divider().color('rgba(255,255,255,0.05)').width('40%')

                Row({ space: 12 }) {
                  DeviceTag({ name: '智能锁', color: this.isDoorLocked ? '#00FF00' : '#FF1744', active: !this.isDoorLocked })
                  DeviceTag({ name: '安防微波', color: '#FF9100', active: this.isDoorLocked })
                }
              }
              .layoutWeight(1).height('100%').border({ width: 1, color: 'rgba(255,255,255,0.03)' })
              .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
              .onClick(() => {
                animateTo({ duration: 400, curve: Curve.EaseInOut }, () => {
                  this.isDoorLocked = !this.isDoorLocked;
                  // 🌟 不仅改动画，还要给硬件发号施令
                  MqttBusService.getInstance().publishCommand({ "cmd": this.isDoorLocked ? "door_close" : "door_open", "value": 0 });
                  this.aiLog = `[DOOR ACCESS] 门禁系统已${this.isDoorLocked ? '设防' : '远程解锁'}`;
                  this.aiLogColor = this.isDoorLocked ? '#00E5FF' : '#FF9100';
                });
              })
            }.width('100%').layoutWeight(1)
          }
          .width('100%').height(380)

        }
        .width('85%').padding(24).backgroundColor('rgba(255,255,255,0.02)')
        .borderRadius(16).border({ width: 1, color: 'rgba(255,255,255,0.05)' })
        .shadow({ radius: 40, color: 'rgba(0,0,0,0.2)' })

        // 3. 数据可视化区
        Row({ space: 24 }) {
          MiniBarChart({ title: '温湿度波动指数 (24H)', dataArray: this.tempTrendData, color: '#00E5FF' })
          MiniBarChart({ title: '端到端加密吞吐率 (实时)', dataArray: this.cryptoTrafficData, color: '#7B61FF' })
        }
        .width('85%')
        .justifyContent(FlexAlign.SpaceBetween)

      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)

      // 4. AI 智能联动触发底栏
      Row() {
        Text('⚡ AI ENGINE EVENT:').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.aiLogColor).margin({ right: 12 })
          .animation({ duration: 300 })
        Text(this.aiLog).fontSize(14).fontColor('#FFF').fontFamily('monospace')
      }
      .width('100%').height(48).padding({ left: 20 }).backgroundColor('rgba(0,0,0,0.5)')
      .borderRadius(8).border({ width: 1, color: 'rgba(0, 229, 255, 0.2)' })
      .shadow({ radius: 20, color: 'rgba(0, 229, 255, 0.1)' })
    }
    .width('100%').height('100%').padding(24)
  }

  @Builder StatusIndicator(lbl: string, val: string, clr: string) {
    Column() {
      Text(lbl).fontSize(10).fontColor('#667788').margin({ bottom: 4 })
      Text(val).fontSize(12).fontWeight(FontWeight.Bold).fontColor(clr)
    }.alignItems(HorizontalAlign.End)
  }

}