@Component
export struct ProfilePage {
  build() {
    Column({ space: 24 }) {
      Text('Quantum-Safe 加密通信引擎').fontSize(24).fontWeight(FontWeight.Bold).fontColor('#FFF').alignSelf(ItemAlign.Start)

      Row({ space: 20 }) {
        // 加密态势展示
        Column({ space: 20 }) {
          this.CryptoNode('认证阶段', 'RSA-2048 双向握手', 'VERIFIED', '#00FF00')
          this.CryptoNode('数据通道', 'AES-256-GCM 流加密', 'ACTIVE', '#00E5FF')
          this.CryptoNode('信创合规', '国密 SM4 密码机', 'STANDBY', '#FF9100')
        }.width('40%')

        // 实时密文流瀑布
        Column() {
          Text('REALTIME ENCRYPTED PACKETS (HEX)').fontSize(12).fontColor('#00E5FF').margin({ bottom: 16 }).alignSelf(ItemAlign.Start)
          Column({ space: 8 }) {
            Text('0x [AE 4F 99 21 ...] -> DEVICE_ACK_OK').fontFamily('monospace').fontSize(12).fontColor('rgba(255,255,255,0.6)')
            Text('0x [11 BB CC 4D ...] -> TEMP_SYNC_HASH').fontFamily('monospace').fontSize(12).fontColor('rgba(255,255,255,0.6)')
            Text('0x [FF 00 22 1A ...] -> TIMESTAMP_VALID').fontFamily('monospace').fontSize(12).fontColor('#00FF00')
            Blank()
            Text('ANTI-REPLAY: Sequence matched. No anomaly detected.').fontSize(10).fontColor('#7B61FF')
          }.width('100%').height('100%').alignItems(HorizontalAlign.Start)
        }
        .layoutWeight(1).padding(24).backgroundColor('rgba(0,0,0,0.5)')
        .borderRadius(16).border({ width: 1, color: 'rgba(0, 229, 255, 0.2)' })
      }.height(300).width('100%')
    }.width('100%').height('100%').padding(24)
  }

  @Builder CryptoNode(title: string, algo: string, status: string, color: string) {
    Row() {
      Column() {
        Text(title).fontSize(14).fontColor('#8899AA')
        Text(algo).fontSize(16).fontWeight(FontWeight.Bold).fontColor('#FFF').margin({ top: 6 })
      }.alignItems(HorizontalAlign.Start)
      Blank()
      Text(status).fontSize(12).fontWeight(FontWeight.Bolder).fontColor(color)
        .padding({ top: 4, bottom: 4, left: 12, right: 12 })
        .backgroundColor(`rgba(${color}, 0.1)`).borderRadius(20).border({ width: 1, color: color })
    }
    .width('100%').padding(20).backgroundColor('rgba(255,255,255,0.02)')
    .borderRadius(16).border({ width: 1, color: 'rgba(255,255,255,0.05)' })
  }
}