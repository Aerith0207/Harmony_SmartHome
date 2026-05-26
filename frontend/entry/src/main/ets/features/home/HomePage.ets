
@Component
export struct HomePage {
  @State currentTime: string = '';
  @State cpuLoad: number = 32;
  @State aiLog: string = 'SYSTEM STANDBY';
  @State aiLogColor: string = '#00E5FF';

  aboutToAppear() {
    setInterval(() => {
      let date = new Date();
      this.currentTime = `${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}:${date.getSeconds().toString().padStart(2, '0')}`;
      this.cpuLoad = Math.floor(Math.random() * 20) + 20; // 模拟 CPU 负载动效
    }, 1000);

    // 模拟 AI 联动触发
    setTimeout(() => {
      this.aiLog = '[AI SCENE] 检测到人体活动，已自动开启客厅主灯';
      this.aiLogColor = '#FF1744';
    }, 5000);
  }

  build() {
    Column({ space: 20 }) {
      // 1. 顶部状态栏 (钢铁侠 HUD 风格)
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

      Row({ space: 20 }) {
        // 2. 房屋 2D 全息态势区
        Column() {
          Text('全息空间设备拓扑').fontSize(14).fontColor('#A0AAB5').margin({ bottom: 16 }).alignSelf(ItemAlign.Start)
          Stack() {
            Column() {
              Row() { this.RoomGrid('主卧区', '26℃', '45%'); this.RoomGrid('客厅中枢', '24℃', '55%') }.height('50%')
              Row() { this.RoomGrid('厨房安防', '环境正常', '40%'); this.RoomGrid('玄关门禁', '已设防', '60%') }.height('50%')
            }.width('100%').height(280)
            // 设备动态锚点
            this.DeviceAnchor('美的空调', 20, 20, '#00E5FF', true)
            this.DeviceAnchor('人体感应', 65, 30, '#FF1744', true)
            this.DeviceAnchor('智能锁', 80, 75, '#00FF00', false)
          }.width('100%')
        }
        .width('45%').padding(20).backgroundColor('rgba(255,255,255,0.02)')
        .borderRadius(16).border({ width: 1, color: 'rgba(255,255,255,0.05)' })

        // 3. 数据可视化动态曲线区
        Column() {
          Text('全天候环境态势流').fontSize(14).fontColor('#A0AAB5').margin({ bottom: 16 }).alignSelf(ItemAlign.Start)
          Row({ space: 20 }) {
            Column() {
              Text('温湿度波动指数').fontSize(12).fontColor('#666').margin({ bottom: 8 })
              DataPanel({ values: [65, 35], max: 100, type: DataPanelType.Line }).width(120).height(120).valueColors(['#00E5FF', '#1976D2'])
            }
            Column() {
              Text('端到端加密吞吐率').fontSize(12).fontColor('#666').margin({ bottom: 8 })
              DataPanel({ values: [88, 12], max: 100, type: DataPanelType.Line }).width(120).height(120).valueColors(['#7B61FF', '#333'])
            }
          }.width('100%').justifyContent(FlexAlign.SpaceAround)
        }
        .layoutWeight(1).padding(20).backgroundColor('rgba(255,255,255,0.02)')
        .borderRadius(16).border({ width: 1, color: 'rgba(255,255,255,0.05)' })
      }.width('100%')

      Blank()

      // 4. AI 智能联动触发底栏 (赛博朋克警报风格)
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

  @Builder RoomGrid(name: string, status: string, w: string) {
    Column() {
      Text(name).fontSize(16).fontColor('rgba(255,255,255,0.2)').fontWeight(FontWeight.Bold)
      Text(status).fontSize(12).fontColor('#00E5FF').margin({ top: 8 })
    }
    .width(w).height('100%').border({ width: 1, color: 'rgba(255,255,255,0.03)' }).justifyContent(FlexAlign.Center)
  }

  @Builder DeviceAnchor(name: string, x: number, y: number, color: string, active: boolean) {
    Row({ space: 8 }) {
      Circle({ width: 10, height: 10 }).fill(color).shadow({ radius: active ? 15 : 0, color: color })
      Text(name).fontSize(12).fontWeight(FontWeight.Bold).fontColor('#FFF')
    }
    .position({ x: `${x}%`, y: `${y}%` }).padding({ left: 12, right: 12, top: 6, bottom: 6 })
    .backgroundColor('rgba(0,0,0,0.7)').borderRadius(20).border({ width: 1, color: 'rgba(255,255,255,0.1)' })
    .backdropBlur(10)
  }
}