// frontend/entry/src/main/ets/pages/Login.ets
import router from '@ohos.router';
import { MqttBusService } from '../network/mqtt'; // 🌟 引入通信服务
import hilog from '@ohos.hilog'; // 🌟 新增：引入日志模块

@Entry
@Component
struct Login {
  @State isInitializing: boolean = true;
  @State initProgress: number = 0;
  @State terminalLog: string = 'SYSTEM: Booting kernel components...';

  // 👇👇👇 新增：插入首屏渲染探针 👇👇👇
  onPageShow() {
    let renderTime = Date.now();
    hilog.info(0x0000, 'PERF_TEST', `✅ [首屏渲染终点] 登录页 UI 呈现完毕！当前时间戳: ${renderTime}`);
  }
  // 👆👆👆 探针结束 👆👆👆

  aboutToAppear() {
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

        // 🌟 核心点火指令！在加载到100%时启动底层通信总线
        MqttBusService.getInstance().init(() => {
          console.info('MQTT_BUS', '全屋生态总线已成功挂载，准备接收硬件流');
        });
      }
    }, 100);
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