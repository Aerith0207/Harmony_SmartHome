// frontend/entry/src/main/ets/pages/Login.ets
import router from '@ohos.router';

@Entry
@Component
struct Login {
  @State isInitializing: boolean = true;
  @State initProgress: number = 0;
  @State terminalLog: string = 'SYSTEM: Booting kernel components...';

  aboutToAppear() {
    // 恢复华丽的科技感加载动画
    let intervalId = setInterval(() => {
      this.initProgress += 4;
      if (this.initProgress === 20) {
        this.terminalLog = 'SECURE: Injecting HUKS Hardware Keys...';
      } else if (this.initProgress === 60) {
        this.terminalLog = 'NETWORK: Establishing Quantum-Safe TLS 1.3 Tunnel...';
      } else if (this.initProgress === 88) {
        this.terminalLog = 'AI CORE: Mapping Neural Scene Rules...';
      } else if (this.initProgress >= 100) {
        clearInterval(intervalId);
        this.terminalLog = 'CONSOLE READY. STANDBY FOR AGENT OAUTH.';
        setTimeout(() => { this.isInitializing = false; }, 600);
      }
    }, 100);

    // 注意：MQTT的初始化我们暂时先放着，等UI彻底跑通再加回去
  }

  build() {
    // 🌟 彻底抛弃 Navigation，直接用纯粹的容器渲染
    Stack() {
      Column().width('100%').height('100%').backgroundColor('#07090C')

      if (this.isInitializing) {
        Column() {
          Blank()
          Text('OPENHARMONY NEXT').fontSize(14).fontWeight(FontWeight.Bold).fontColor('#00E5FF').letterSpacing(6).margin({ bottom: 10 })
          Text('INTELLIGENT SCENE COMMAND CENTER').fontSize(24).fontWeight(FontWeight.Bold).fontColor('#FFFFFF').margin({ bottom: 30 })
          Progress({ value: this.initProgress, total: 100, type: ProgressType.Ring })
            .width(120).height(120).color('#00E5FF').style({ strokeWidth: 4 }).margin({ bottom: 40 })
          Text(this.terminalLog).fontSize(12).fontFamily('monospace').fontColor('rgba(255,255,255,0.4)').margin({ bottom: 20 })
          Text(`LOADING ${this.initProgress}%`).fontSize(11).fontColor('#1976D2').fontWeight(FontWeight.Bold)
          Blank()
        }.width('100%').height('100%')
      } else {
        Column() {
          Text('SECURITY AUTHENTICATION').fontSize(12).fontColor('#00E5FF').letterSpacing(4).margin({ bottom: 8 })
          Text('控制台安全访问鉴权').fontSize(24).fontWeight(FontWeight.Bold).fontColor('#FFF').margin({ bottom: 40 })
          Button('INITIALIZE CONSOLE')
            .width(320).height(54).backgroundColor('#1976D2')
            .shadow({ radius: 20, color: 'rgba(25, 118, 210, 0.3)' })
            .borderRadius(12)
            .onClick(() => {
              // 🌟 使用最稳健的基础路由跳转，绝对不会白屏
              router.replaceUrl({ url: 'pages/MainLayout' });
            })
        }
        .padding(40).backgroundColor('rgba(25, 28, 36, 0.3)').borderRadius(20).border({ width: 1, color: 'rgba(255,255,255,0.05)' })
      }
    }
    .width('100%')
    .height('100%')
  }
}