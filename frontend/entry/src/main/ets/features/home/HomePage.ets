// frontend/entry/src/main/ets/features/home/HomePage.ets
@Component
export struct HomePage {
  @State currentTime: string = '';
  @State cpuLoad: number = 32;
  @State aiLog: string = 'SYSTEM STANDBY';
  @State aiLogColor: string = '#00E5FF';

  // 门禁状态管控
  @State isDoorLocked: boolean = true;

  // 2D 图表的实时数据流数组
  @State tempTrendData: number[] = [45, 50, 48, 55, 60, 58, 65, 60, 70, 68, 75, 70, 65, 60, 55, 58, 62, 65, 60, 55];
  @State cryptoTrafficData: number[] = [20, 80, 35, 90, 15, 60, 45, 75, 25, 85, 55, 40, 70, 30, 65, 20, 80, 40, 95, 30];

  aboutToAppear() {
    setInterval(() => {
      let date = new Date();
      this.currentTime = `${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}:${date.getSeconds().toString().padStart(2, '0')}`;
      this.cpuLoad = Math.floor(Math.random() * 20) + 20;

      // 图表数据动态滚动逻辑
      this.cryptoTrafficData.shift();
      this.cryptoTrafficData.push(Math.floor(Math.random() * 80) + 20);

      if (Math.random() > 0.3) {
        this.tempTrendData.shift();
        this.tempTrendData.push(Math.floor(Math.random() * 30) + 45);
      }
    }, 1000);

    setTimeout(() => {
      this.aiLog = '[AI SCENE] 检测到人体活动，已自动开启客厅主灯';
      this.aiLogColor = '#FF1744';
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
        // 2. 房屋 2D 全息态势区
        Column() {
          Text('全息空间设备拓扑').fontSize(14).fontColor('#A0AAB5').margin({ bottom: 16 }).alignSelf(ItemAlign.Start)

          Column() {
            Row() {
              this.RoomGrid('主卧区', '26', '℃', '相对湿度', '45%', '空气质量', '优', '美的空调', '#00E5FF', true, '智能窗帘', '#7B61FF', false)
              this.RoomGrid('客厅中枢', '24', '℃', 'PM 2.5', '12', '当前功耗', '120W', '人体感应', '#FF1744', true, '氛围灯带', '#00FF00', true)
            }.width('100%').layoutWeight(1)

            Row() {
              this.RoomGrid('厨房安防', '正常', 'ENV', '燃气浓度', '0%', '烟雾探测', '正常', '烟雾报警', '#FF1744', true, '智能插座', '#00E5FF', true)

              Column({ space: 12 }) {
                // 🌟 优化：玄关门禁的标题，加入指示竖条，提高亮度
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
                  this.DeviceTag('智能锁', this.isDoorLocked ? '#00FF00' : '#FF1744', !this.isDoorLocked)
                  this.DeviceTag('安防微波', '#FF9100', this.isDoorLocked)
                }
              }
              .layoutWeight(1).height('100%').border({ width: 1, color: 'rgba(255,255,255,0.03)' })
              .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
              .onClick(() => {
                this.isDoorLocked = !this.isDoorLocked;
                this.aiLog = `[DOOR ACCESS] 门禁系统已${this.isDoorLocked ? '设防' : '远程解锁'}`;
                this.aiLogColor = this.isDoorLocked ? '#00E5FF' : '#FF9100';
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
          this.MiniBarChart('温湿度波动指数 (24H)', this.tempTrendData, '#00E5FF')
          this.MiniBarChart('端到端加密吞吐率 (实时)', this.cryptoTrafficData, '#7B61FF')
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

  // 🌟 优化：高密度房间数据组件 (更新了标题样式)
  @Builder RoomGrid(
    name: string, mainVal: string, mainUnit: string,
    sub1Lbl: string, sub1Val: string, sub2Lbl: string, sub2Val: string,
    dev1Name: string, dev1Color: string, dev1Active: boolean,
    dev2Name?: string, dev2Color?: string, dev2Active?: boolean
  ) {
    Column({ space: 12 }) {
      Column({ space: 8 }) { // 间距微调
        // 🌟 这是修改的核心：加入左侧科技感发光竖条，字体加粗变白
        Row({ space: 8 }) {
          Rect().width(4).height(16).fill('#00E5FF').radius(2)
          Text(name).fontSize(18).fontColor('#FFF').fontWeight(FontWeight.Bolder).letterSpacing(1)
        }.alignItems(VerticalAlign.Center)

        Row({ space: 4 }) {
          Text(mainVal).fontSize(26).fontWeight(FontWeight.Bolder).fontColor('#FFF')
          Text(mainUnit).fontSize(12).fontColor('#00E5FF').margin({ bottom: 4 })
        }.alignItems(VerticalAlign.Bottom)
      }.alignItems(HorizontalAlign.Center)

      Row({ space: 24 }) {
        Column({ space: 4 }) { Text(sub1Lbl).fontSize(10).fontColor('#667788'); Text(sub1Val).fontSize(12).fontWeight(FontWeight.Bold).fontColor('#A0AAB5') }.alignItems(HorizontalAlign.Center)
        Column({ space: 4 }) { Text(sub2Lbl).fontSize(10).fontColor('#667788'); Text(sub2Val).fontSize(12).fontWeight(FontWeight.Bold).fontColor('#A0AAB5') }.alignItems(HorizontalAlign.Center)
      }.justifyContent(FlexAlign.Center)

      Divider().color('rgba(255,255,255,0.05)').width('40%')

      Row({ space: 12 }) {
        this.DeviceTag(dev1Name, dev1Color, dev1Active)
        if (dev2Name && dev2Color !== undefined && dev2Active !== undefined) {
          this.DeviceTag(dev2Name, dev2Color, dev2Active)
        }
      }
    }
    .layoutWeight(1)
    .height('100%')
    .border({ width: 1, color: 'rgba(255,255,255,0.03)' })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder DeviceTag(name: string, color: string, active: boolean) {
    Row({ space: 6 }) {
      Circle({ width: 6, height: 6 }).fill(color).shadow({ radius: active ? 10 : 0, color: color })
      Text(name).fontSize(11).fontWeight(FontWeight.Bold).fontColor(active ? '#FFF' : 'rgba(255,255,255,0.4)')
    }
    .padding({ left: 10, right: 10, top: 4, bottom: 4 })
    .backgroundColor('rgba(0,0,0,0.4)')
    .borderRadius(12)
    .border({ width: 1, color: active ? 'rgba(255,255,255,0.1)' : 'rgba(255,255,255,0.02)' })
  }

  @Builder MiniBarChart(title: string, dataArray: number[], color: string) {
    Column({ space: 12 }) {
      Row() {
        Text(title).fontSize(12).fontColor('#8899AA')
        Blank()
        Row({ space: 4 }) {
          Circle({ width: 4, height: 4 }).fill(color)
          Text('LIVE').fontSize(10).fontColor(color).fontWeight(FontWeight.Bold)
        }
      }.width('100%')

      Row({ space: 6 }) {
        ForEach(dataArray, (val: number, idx: number) => {
          Column()
            .width(8)
            .height(`${val}%`)
            .backgroundColor(color)
            .borderRadius({ topLeft: 2, topRight: 2 })
            .opacity(0.2 + (idx / dataArray.length) * 0.8)
        })
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