@Component
export struct ControlPage {
  @State targetTemp: number = 24;
  @State isAcOn: boolean = true;

  build() {
    Column({ space: 24 }) {
      Text('分布式硬件指令中枢').fontSize(24).fontWeight(FontWeight.Bold).fontColor('#FFF').alignSelf(ItemAlign.Start)

      Row({ space: 24 }) {
        // 空调全息控制环
        Column() {
          Text('Climate Control').fontSize(12).fontColor('#00E5FF').letterSpacing(2).margin({ bottom: 20 })
          Stack() {
            // 外圈发光环
            Circle({ width: 220, height: 220 }).fill('transparent').stroke('rgba(0, 229, 255, 0.2)').strokeWidth(2)
            Circle({ width: 200, height: 200 }).fill('rgba(0,0,0,0.5)').shadow({ radius: 30, color: this.isAcOn ? 'rgba(0, 229, 255, 0.2)' : 'transparent' })

            Column() {
              Text('TARGET TEMP').fontSize(10).fontColor('#666')
              Text(`${this.targetTemp}℃`).fontSize(48).fontWeight(FontWeight.Bolder).fontColor(this.isAcOn ? '#00E5FF' : '#555').margin({ top: 8, bottom: 8 })
              Text(this.isAcOn ? 'COOLING ACTIVE' : 'OFFLINE').fontSize(10).fontColor(this.isAcOn ? '#00FF00' : '#FF1744')
            }
          }.margin({ bottom: 30 })

          Row({ space: 20 }) {
            Button('-').width(60).height(60).fontSize(24).backgroundColor('rgba(255,255,255,0.05)').fontColor('#FFF')
              .onClick(() => { if(this.isAcOn) this.targetTemp -= 1; })
            Button(this.isAcOn ? 'POWER OFF' : 'POWER ON').width(120).height(60).backgroundColor(this.isAcOn ? '#FF1744' : '#1976D2')
              .onClick(() => { this.isAcOn = !this.isAcOn; })
            Button('+').width(60).height(60).fontSize(24).backgroundColor('rgba(255,255,255,0.05)').fontColor('#FFF')
              .onClick(() => { if(this.isAcOn) this.targetTemp += 1; })
          }
        }
        .width('40%').height(450).padding(30).backgroundColor('rgba(255,255,255,0.02)')
        .borderRadius(20).border({ width: 1, color: 'rgba(255,255,255,0.05)' })

        // 快速场景卡片
        Column({ space: 16 }) {
          this.SceneCard('回家模式', '自动开启客厅灯光与空调', '#00E5FF', true)
          this.SceneCard('离家模式', '切断非必要电源，启动布防', '#FF9100', false)
          this.SceneCard('睡眠模式', '灯光调暗，空调切至静音', '#7B61FF', false)
        }.layoutWeight(1).height(450)
      }.width('100%')
    }.width('100%').height('100%').padding(24)
  }

  @Builder SceneCard(title: string, desc: string, glowColor: string, active: boolean) {
    Row() {
      Column() {
        Text(title).fontSize(18).fontWeight(FontWeight.Bold).fontColor('#FFF')
        Text(desc).fontSize(12).fontColor('#8899AA').margin({ top: 6 })
      }.alignItems(HorizontalAlign.Start)
      Blank()
      Toggle({ type: ToggleType.Switch, isOn: active }).selectedColor(glowColor)
    }
    .width('100%').padding(24).backgroundColor('rgba(255,255,255,0.02)')
    .borderRadius(16).border({ width: 1, color: active ? glowColor : 'rgba(255,255,255,0.05)' })
    .shadow({ radius: active ? 15 : 0, color: glowColor })
  }
}