@Component
export struct ProfilePage {
  // 模拟终端动态滚动的加密日志
  @State encryptedLogs: string[] = [
    '[SYS] QUANTUM-SAFE ENGINE INITIALIZED...',
    '0x [AE 4F 99 21 00 BB] -> DEVICE_ACK_OK',
    '0x [11 BB CC 4D F2 11] -> TEMP_SYNC_HASH',
    '0x [FF 00 22 1A C4 99] -> TIMESTAMP_VALID'
  ];

  // 🌟 新增：动态拦截次数统计
  @State interceptCount: number = 142;

  aboutToAppear() {
    // 动态终端效果：每 1.5 秒插入一条新日志
    setInterval(() => {
      let hex1 = Math.floor(Math.random() * 255).toString(16).toUpperCase().padStart(2, '0');
      let hex2 = Math.floor(Math.random() * 255).toString(16).toUpperCase().padStart(2, '0');
      let hex3 = Math.floor(Math.random() * 255).toString(16).toUpperCase().padStart(2, '0');
      let eventTypes = ['HEARTBEAT_ACK', 'STATE_MUTATION', 'KEY_ROTATION', 'SENSOR_PULL'];
      let event = eventTypes[Math.floor(Math.random() * eventTypes.length)];

      this.encryptedLogs.push(`0x [${hex1} ${hex2} ${hex3} DE AD BE] -> ${event}`);

      // 终端日志行数控制，适配新的高度
      if (this.encryptedLogs.length > 14) {
        this.encryptedLogs.shift();
      }
    }, 1500);

    // 🌟 新增：模拟恶意探针拦截数据的实时增长
    setInterval(() => {
      if (Math.random() > 0.6) {
        this.interceptCount += Math.floor(Math.random() * 3) + 1;
      }
    }, 3500);
  }

  build() {
    Column() {
      // 🌟 顶部自适应空白（将内容往下推）
      Blank()

      // ================= 核心内容区 =================
      Column({ space: 24 }) {
        // 1. 顶部标题区
        Text('Quantum-Safe 加密通信引擎')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFF')
          .alignSelf(ItemAlign.Start)

        // 2. 态势面板与终端 (固定高度，确保上下完美居中对齐)
        Row({ space: 24 }) {

          // --- 左侧：加密态势展示 (占比 40%) ---
          Column({ space: 16 }) {
            this.CryptoNode('认证阶段', 'RSA-2048 双向握手', 'VERIFIED', '#00FF00', true)
            this.CryptoNode('数据通道', 'AES-256-GCM 流加密', 'ACTIVE', '#00E5FF', true)
            this.CryptoNode('信创合规', '国密 SM4 密码机', 'STANDBY', '#FF9100', false)

            // 🌟 扩展的 UI 模块：网络边界防御动态数据
            this.SecurityMetrics()

            Blank() // 在固定高度内，把底部提示语推到边缘

            // 底部安全策略说明
            Row() {
              Text('ℹ 安全策略组: 严格 (STRICT_MODE)\n当前网络环境无异常，协议簇运行平稳。')
                .fontSize(12)
                .fontColor('rgba(255,255,255,0.4)')
                .lineHeight(18)
            }
            .width('100%')
            .padding(16)
            .backgroundColor('rgba(255,255,255,0.01)')
            .borderRadius(8)
          }
          .layoutWeight(4)
          .height('100%')

          // --- 右侧：实时密文流瀑布终端 (占比 60%) ---
          Column() {
            // 终端头部栏
            Row() {
              Text('REALTIME ENCRYPTED PACKETS (HEX)').fontSize(12).fontColor('#00E5FF').fontWeight(FontWeight.Bold)
              Blank()
              Circle({ width: 8, height: 8 }).fill('#00FF00').shadow({ radius: 10, color: '#00FF00' })
            }
            .width('100%')
            .padding({ bottom: 12 })
            .border({ width: { bottom: 1 }, color: 'rgba(0, 229, 255, 0.15)' })

            // 终端滚动区
            List({ space: 8 }) {
              ForEach(this.encryptedLogs, (log: string, index: number) => {
                ListItem() {
                  Text(log)
                    .fontFamily('monospace')
                    .fontSize(13)
                    .fontColor(index === this.encryptedLogs.length - 1 ? '#00FF00' : 'rgba(0, 229, 255, 0.6)')
                }
              })
            }
            .width('100%')
            .layoutWeight(1)
            .margin({ top: 16, bottom: 16 })

            // 终端底部提示
            Row() {
              Text('ANTI-REPLAY: Sequence matched. No anomaly detected.')
                .fontSize(10)
                .fontColor('#7B61FF')
                .fontFamily('monospace')
            }
            .width('100%')
            .padding(12)
            .backgroundColor('rgba(123, 97, 255, 0.1)')
            .borderRadius(6)
            .border({ width: 1, color: 'rgba(123, 97, 255, 0.2)' })

          }
          .layoutWeight(6)
          .height('100%')
          .padding(24)
          .backgroundColor('rgba(0, 0, 0, 0.3)')
          .borderRadius(16)
          .border({ width: 1, color: 'rgba(0, 229, 255, 0.1)' })
          .shadow({ radius: 30, color: 'rgba(0, 229, 255, 0.05)' })
        }
        .width('100%')
        .height(540) // 🌟 核心魔法：固定面板高度！这会让它在屏幕中绝对悬浮居中，不会因为屏幕太大而过度拉伸
      }
      .width('100%')

      // 🌟 底部自适应空白（将内容往上推，与顶部 Blank 配合实现绝对垂直居中）
      Blank()
    }
    .width('100%')
    .height('100%')
    .padding(32)
  }

  // 基础加密协议节点卡片
  @Builder CryptoNode(title: string, algo: string, status: string, color: string, isActive: boolean) {
    Row() {
      Column() {
        Text(title).fontSize(14).fontColor('#8899AA')
        Text(algo).fontSize(16).fontWeight(FontWeight.Bold).fontColor(isActive ? '#FFF' : 'rgba(255,255,255,0.5)').margin({ top: 6 })
      }.alignItems(HorizontalAlign.Start)

      Blank()

      Text(status).fontSize(12).fontWeight(FontWeight.Bolder).fontColor(color)
        .padding({ top: 4, bottom: 4, left: 12, right: 12 })
        .backgroundColor(isActive ? 'transparent' : 'rgba(255, 145, 0, 0.05)')
        .borderRadius(20)
        .border({ width: 1, color: color })
    }
    .width('100%')
    .padding(20)
    .backgroundColor('rgba(255,255,255,0.02)')
    .borderRadius(16)
    .border({ width: 1, color: 'rgba(255,255,255,0.05)' })
  }

  // 🌟 新增：丰富 UI 的安全防御数据监测盘
  @Builder SecurityMetrics() {
    Column({ space: 12 }) {
      Row() {
        Text('网络边界防御').fontSize(12).fontColor('#8899AA')
        Blank()
        Text('SHIELD ON').fontSize(10).fontColor('#00FF00').fontWeight(FontWeight.Bold)
      }.width('100%')

      Row({ space: 16 }) {
        // 数据项 1：拦截统计 (动态增长)
        Column({ space: 4 }) {
          Text('恶意探针拦截').fontSize(11).fontColor('rgba(255,255,255,0.5)')
          Text(`${this.interceptCount} 次`).fontSize(18).fontWeight(FontWeight.Bold).fontColor('#FFF')
        }.alignItems(HorizontalAlign.Start).layoutWeight(1)

        // 数据项 2：密钥状态
        Column({ space: 4 }) {
          Text('动态密钥池余量').fontSize(11).fontColor('rgba(255,255,255,0.5)')
          Text('99.8%').fontSize(18).fontWeight(FontWeight.Bold).fontColor('#00E5FF')
        }.alignItems(HorizontalAlign.Start).layoutWeight(1)
      }.width('100%')
    }
    .width('100%')
    .padding(20)
    .backgroundColor('rgba(255,255,255,0.02)')
    .borderRadius(16)
    .border({ width: 1, color: 'rgba(255,255,255,0.05)' })
  }
}