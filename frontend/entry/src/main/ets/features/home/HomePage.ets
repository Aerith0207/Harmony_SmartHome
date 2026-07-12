// frontend/entry/src/main/ets/features/home/HomePage.ets

import promptAction from '@ohos.promptAction';
import { MqttBusService } from '../../network/mqtt';
import { SensorDataModel } from '../../models/DeviceModels';
import { DeviceManager } from '../../core/DeviceManager';
import { DeviceType, DeviceAction } from '../../core/adapter/DeviceConstants';
import { DeviceCommand } from '../../core/adapter/CommandModel';

@CustomDialog
export struct DoorAuthDialog {
  controller: CustomDialogController;
  @State inputPwd: string = '';
  onAuthSuccess: () => void = () => {};
  isNightMode: boolean = false;

  build() {
    Column({ space: 20 }) {
      Text('🛡️ 门禁安全验证').fontSize(20).fontWeight(FontWeight.Bold).fontColor(this.isNightMode ? '#FFF' : '#1A1A1A')

      TextInput({ placeholder: '请输入6位安全密码', text: this.inputPwd })
        .type(InputType.Password)
        .onChange((val) => this.inputPwd = val)
        .height(48).borderRadius(12)
        .backgroundColor(this.isNightMode ? '#2A2E35' : '#F5F7FA')
        .fontColor(this.isNightMode ? '#FFF' : '#333')
        .placeholderColor(this.isNightMode ? '#8899AA' : '#888')

      Row({ space: 16 }) {
        Button('取消').layoutWeight(1).backgroundColor(this.isNightMode ? '#3A3F48' : '#E0E4E8').fontColor(this.isNightMode ? '#FFF' : '#333').onClick(() => this.controller.close())
        Button('验证并开锁').layoutWeight(1).backgroundColor('#FF1744').fontColor('#FFF').onClick(() => { if (this.inputPwd === '123456') { this.onAuthSuccess(); this.controller.close(); } else { promptAction.showToast({ message: '❌ 密码错误，拒绝访问' }); } })
      }.width('100%')
    }
    .padding(24).backgroundColor(this.isNightMode ? '#1E222B' : '#FFFFFF').borderRadius(24)
  }
}

@Component
struct MiniBarChart {
  @Prop title: string;
  @Prop dataArray: number[];
  @Prop color: string;
  @Prop isNightMode: boolean;

  build() {
    Column({ space: 12 }) {
      Row() {
        Text(this.title).fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.isNightMode ? '#FFFFFF' : '#556677')
        Blank()
        Row({ space: 4 }) {
          Circle({ width: 6, height: 6 }).fill(this.color)
          Text('LIVE').fontSize(12).fontColor(this.color).fontWeight(FontWeight.Bold)
        }
      }.width('100%')

      Row({ space: 6 }) {
        ForEach(this.dataArray, (val: number, idx: number) => {
          Column()
            .width(8)
            .height(`${val}%`)
            .backgroundColor(this.color)
            .borderRadius({ topLeft: 2, topRight: 2 })
            .opacity(this.isNightMode ? 0.5 + (idx / this.dataArray.length) * 0.5 : 0.2 + (idx / this.dataArray.length) * 0.8)
            .animation({ duration: 300, curve: Curve.EaseInOut })
        }, (val: number, idx: number) => idx.toString() + '_' + val.toString())
      }
      .width('100%')
      .height(60)
      .alignItems(VerticalAlign.Bottom)
      .border({ width: { bottom: 1 }, color: this.isNightMode ? 'rgba(255,255,255,0.2)' : 'rgba(0,0,0,0.1)' })
    }
    .layoutWeight(1).height('100%').padding(20)
    .backgroundColor(this.isNightMode ? 'rgba(255,255,255,0.05)' : 'rgba(255,255,255,0.4)')
    .borderRadius(20).border({ width: 1, color: this.isNightMode ? 'rgba(255,255,255,0.15)' : 'rgba(0,0,0,0.05)' })
  }
}

@Component
export struct HomePage {
  @Prop isNightMode: boolean;

  @State currentTime: string = '';
  @State greeting: string = '你好';
  @State cpuLoad: number = 32;
  @State aiLog: string = 'SYSTEM STANDBY';
  @State aiLogColor: string = '#00E5FF';

  @StorageLink('global_realTemp') realTemp: string = '26.0';
  @StorageLink('global_realHum') realHum: string = '45.0';
  @StorageLink('global_isDoorLocked') isDoorLocked: boolean = true;
  @StorageLink('global_isMainLightOn') isMainLightOn: boolean = false;
  @StorageLink('global_isAcOn') isAcOn: boolean = false;

  @StorageLink('global_tempTrend') tempTrendData: number[] = [45, 50, 48, 55, 60, 58, 65, 60, 70, 68, 75, 70, 65, 60, 55, 58, 62, 65, 60, 55];

  doorAuthController: CustomDialogController = new CustomDialogController({
    builder: DoorAuthDialog({
      isNightMode: this.isNightMode,
      onAuthSuccess: () => {
        animateTo({ duration: 400, curve: Curve.EaseInOut }, () => {
          this.isDoorLocked = false;
          DeviceManager.getInstance().sendCommand(new DeviceCommand(DeviceType.DOOR, DeviceAction.LOCK, false));
          this.aiLog = `[DOOR ACCESS] 门禁系统已远程解锁`;
          this.aiLogColor = '#FF9100';
          promptAction.showToast({ message: '身份验证通过，门锁已开启' });
        });
      }
    }),
    alignment: DialogAlignment.Center, autoCancel: true, customStyle: true
  });

  aboutToAppear() {
    MqttBusService.getInstance().registerSensorListener((data: SensorDataModel) => {
      animateTo({ duration: 500, curve: Curve.EaseInOut }, () => {
        this.realTemp = data.temperature.toFixed(1);
        this.realHum = data.humidity.toFixed(1);
        this.isDoorLocked = !data.doorOpen;
        this.isMainLightOn = data.lightStatus;
        this.isAcOn = data.acStatus;
        let newTempChart = [...this.tempTrendData]; newTempChart.shift(); newTempChart.push(data.temperature);
        this.tempTrendData = newTempChart;
      });
    });

    setInterval(() => {
      let date = new Date(); let hour = date.getHours();
      this.currentTime = `${hour.toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}`;
      if(hour >= 6 && hour < 12) this.greeting = '早上好'; else if(hour >= 12 && hour < 18) this.greeting = '下午好'; else this.greeting = '晚上好';
      this.cpuLoad = Math.floor(Math.random() * 20) + 20;
    }, 1000);
  }

  @Builder QuickControlButton(icon: string, name: string, active: boolean, color: string, action: () => void) {
    Row({ space: 8 }) {
      Text(icon).fontSize(20)
      Text(name).fontSize(16).fontWeight(FontWeight.Bold).fontColor(active ? '#FFF' : (this.isNightMode ? '#E0E0E0' : '#333'))
    }
    .padding({ left: 24, right: 24, top: 14, bottom: 14 })
    .backgroundColor(active ? color : (this.isNightMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.05)'))
    .borderRadius(16)
    .border({ width: 1, color: active ? color : (this.isNightMode ? 'rgba(255,255,255,0.1)' : 'transparent') })
    .shadow(active ? { radius: 15, color: color + '66' } : { radius: 0 })
    .onClick(action).animation({ duration: 300, curve: Curve.FastOutSlowIn })
  }

  build() {
    Column({ space: 20 }) {
      Row() {
        Column() {
          Text(`${this.greeting}，主人。欢迎回家！`).fontSize(32).fontWeight(FontWeight.Bolder).fontColor(this.isNightMode ? '#FFF' : '#1A1A1A')
          Text('舒适度：极佳 | 空气质量：优 | 网络：加密稳定').fontSize(14).fontColor(this.isNightMode ? '#00E5FF' : '#007799').margin({ top: 8 })
        }.alignItems(HorizontalAlign.Start)
        Blank()
        Row({ space: 24 }) {
          this.StatusIndicator('GATEWAY', 'ONLINE 🟢', '#00FF00')
          this.StatusIndicator('SECURITY', 'AES-256 🔒', '#7B61FF')
          this.StatusIndicator('CPU LOAD', `${this.cpuLoad}% ⚡`, '#FF9100')
          Text(this.currentTime).fontFamily('monospace').fontSize(36).fontColor(this.isNightMode ? '#FFF' : '#1A1A1A').fontWeight(FontWeight.Bold)
        }
      }.width('100%').padding({ bottom: 20 }).border({ width: { bottom: 1 }, color: this.isNightMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.1)' })

      Row({ space: 32 }) {
        // 左侧气候区
        Column({ space: 40 }) {
          Row({ space: 8 }) {
            Rect().width(6).height(24).fill(this.isNightMode ? '#00E5FF' : '#007799').radius(3)
            Text('室内气候中枢').fontSize(24).fontColor(this.isNightMode ? '#FFF' : '#1A1A1A').fontWeight(FontWeight.Bolder).letterSpacing(2)
          }.alignItems(VerticalAlign.Center).width('100%')

          Row() {
            Column({ space: 8 }) {
              Row({ space: 4 }) {
                Text(this.realTemp).fontSize(72).fontWeight(FontWeight.Bolder).fontColor(this.isNightMode ? '#FFF' : '#1A1A1A')
                  .textShadow(this.isNightMode ? { radius: 4, color: 'rgba(0,0,0,0.8)', offsetX: 1, offsetY: 2 } : { radius: 0 })
                Text('℃').fontSize(24).fontColor(this.isNightMode ? '#00E5FF' : '#007799').margin({ bottom: 12 })
              }.alignItems(VerticalAlign.Bottom)
              Text('当前室内温度').fontSize(16).fontColor(this.isNightMode ? '#A0AAB5' : '#888')
            }.layoutWeight(1).alignItems(HorizontalAlign.Center)

            Divider().vertical(true).height(80).color(this.isNightMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.1)')

            Column({ space: 8 }) {
              Row({ space: 4 }) {
                Text(this.realHum).fontSize(72).fontWeight(FontWeight.Bolder).fontColor(this.isNightMode ? '#FFF' : '#1A1A1A')
                  .textShadow(this.isNightMode ? { radius: 4, color: 'rgba(0,0,0,0.8)', offsetX: 1, offsetY: 2 } : { radius: 0 })
                Text('%').fontSize(24).fontColor(this.isNightMode ? '#00E5FF' : '#007799').margin({ bottom: 12 })
              }.alignItems(VerticalAlign.Bottom)
              Text('室内相对湿度').fontSize(16).fontColor(this.isNightMode ? '#A0AAB5' : '#888')
            }.layoutWeight(1).alignItems(HorizontalAlign.Center)
          }.width('100%').justifyContent(FlexAlign.SpaceEvenly)

          Row({ space: 24 }) {
            this.QuickControlButton('💡', '客厅主灯', this.isMainLightOn, '#00FF00', () => {
              this.isMainLightOn = !this.isMainLightOn;
              DeviceManager.getInstance().sendCommand(new DeviceCommand(DeviceType.LIGHT, DeviceAction.POWER, this.isMainLightOn));
            })
            this.QuickControlButton('❄️', '全屋空调', this.isAcOn, '#00E5FF', () => {
              this.isAcOn = !this.isAcOn;
              DeviceManager.getInstance().sendCommand(new DeviceCommand(DeviceType.AC, DeviceAction.POWER, this.isAcOn));
            })
          }.width('100%').justifyContent(FlexAlign.Center)
        }
        .layoutWeight(1).height('100%').padding(32)
        .backgroundColor(this.isNightMode ? 'rgba(255,255,255,0.05)' : 'rgba(255,255,255,0.4)')
        .borderRadius(32).border({ width: 1, color: this.isNightMode ? 'rgba(255,255,255,0.15)' : 'rgba(0,0,0,0.05)' })

        // 右侧安防区
        Column({ space: 40 }) {
          Row({ space: 8 }) {
            Rect().width(6).height(24).fill(this.isNightMode ? '#00E5FF' : '#007799').radius(3)
            Text('玄关安防总线').fontSize(24).fontColor(this.isNightMode ? '#FFF' : '#1A1A1A').fontWeight(FontWeight.Bolder).letterSpacing(2)
          }.alignItems(VerticalAlign.Center).width('100%')

          Column({ space: 16 }) {
            Text(this.isDoorLocked ? '设防中' : '已解锁')
              .fontSize(64).fontWeight(FontWeight.Bolder)
              .fontColor(this.isDoorLocked ? (this.isNightMode ? '#00E5FF' : '#007799') : '#FF1744')
              .textShadow(this.isNightMode ? { radius: 4, color: 'rgba(0,0,0,0.8)', offsetX: 1, offsetY: 2 } : { radius: 0 })
            Text(this.isDoorLocked ? '🔒 外部访问已锁定，系统严密监控中' : '🔓 门禁已开启，请注意居室安全')
              .fontSize(16).fontColor(this.isNightMode ? '#A0AAB5' : '#888')
          }.alignItems(HorizontalAlign.Center).layoutWeight(1).justifyContent(FlexAlign.Center)

          Row({ space: 48 }) {
            Column({ space: 8 }) { Text('门锁剩余电量').fontSize(14).fontColor(this.isNightMode ? '#A0AAB5' : '#888'); Text('85%').fontSize(20).fontWeight(FontWeight.Bold).fontColor(this.isNightMode ? '#E0E0E0' : '#444') }.alignItems(HorizontalAlign.Center)
            Column({ space: 8 }) { Text('物理门磁状态').fontSize(14).fontColor(this.isNightMode ? '#A0AAB5' : '#888'); Text(this.isDoorLocked ? '紧闭' : '脱开').fontSize(20).fontWeight(FontWeight.Bold).fontColor(this.isNightMode ? '#E0E0E0' : '#444') }.alignItems(HorizontalAlign.Center)
          }.width('100%').justifyContent(FlexAlign.Center)
        }
        .layoutWeight(1).height('100%').padding(32)
        .backgroundColor(this.isNightMode ? 'rgba(255,255,255,0.05)' : 'rgba(255,255,255,0.4)')
        .borderRadius(32).border({ width: 1, color: this.isNightMode ? 'rgba(255,255,255,0.15)' : 'rgba(0,0,0,0.05)' })
        .onClick(() => {
          if (this.isDoorLocked) this.doorAuthController.open();
          else animateTo({ duration: 400, curve: Curve.EaseInOut }, () => {
            this.isDoorLocked = true; DeviceManager.getInstance().sendCommand(new DeviceCommand(DeviceType.DOOR, DeviceAction.LOCK, true));
            this.aiLog = `[DOOR ACCESS] 门禁系统已设防`; this.aiLogColor = '#00E5FF';
          });
        })
      }.width('85%').height(360)

      // 🌟 核心：用 Blank 彻底撑开中间留白，把底部卡片压下去
      Blank()

      // ================= 3. 底部次级卡片区 (紧凑高度 140) =================
      Row({ space: 32 }) {
        MiniBarChart({ title: '全屋温湿度波动指数 (24H)', dataArray: this.tempTrendData, color: this.isNightMode ? '#00E5FF' : '#007799', isNightMode: this.isNightMode })

        // 🌟 智能管家机器人面板
        Column() {
          Row() {
            Text('智能管家机器人 (AI Agent)').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.isNightMode ? '#FFFFFF' : '#556677')
            Blank()
            Row({ space: 4 }) {
              Circle({ width: 6, height: 6 }).fill('#00FF00').shadow({ radius: 4, color: '#00FF00' })
              Text('ACTIVE').fontSize(12).fontColor('#00FF00').fontWeight(FontWeight.Bold)
            }
          }.width('100%')

          Row({ space: 16 }) {
            // 🤖 动态判断昼夜，调用不同的头像
            Image(this.isNightMode ? $r('app.media.robot_avatar_night') : $r('app.media.robot_avatar_day'))
              .width(64)
              .height(64)
              .borderRadius(32)
              .objectFit(ImageFit.Cover)
              .backgroundColor(this.isNightMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.05)')
              .border({ width: 2, color: this.isNightMode ? '#FFFFFF' : '#007799' })

            Column({ space: 6 }) {
              Text('System Online').fontSize(16).fontWeight(FontWeight.Bolder).fontColor(this.isNightMode ? '#FFFFFF' : '#007799')
              Text('全环境感知中枢已接管，正在默默守护您的居住健康。').fontSize(11).fontColor(this.isNightMode ? '#FFFFFF' : '#666').lineHeight(16).opacity(this.isNightMode ? 0.9 : 1)

              Row() {
                Text('⚡ 满电').fontSize(10).fontColor('#00FF00')
                Blank()
                Text('🧠 大模型已挂载').fontSize(10).fontColor(this.isNightMode ? '#FFFFFF' : '#888').opacity(this.isNightMode ? 0.8 : 1)
              }.width('100%').margin({ top: 4 })
            }.layoutWeight(1).alignItems(HorizontalAlign.Start).justifyContent(FlexAlign.Center)
          }.width('100%').margin({ top: 12 }) // 控制头像和标题的紧凑距离
        }
        .layoutWeight(1).height('100%').padding(20)
        .backgroundColor(this.isNightMode ? 'rgba(255,255,255,0.05)' : 'rgba(255,255,255,0.4)')
        .borderRadius(20).border({ width: 1, color: this.isNightMode ? 'rgba(255,255,255,0.15)' : 'rgba(0,0,0,0.05)' })

      }.width('85%').height(140).justifyContent(FlexAlign.SpaceBetween)

      // ================= 4. 底部 AI 跑马灯日志区 =================
      Row() {
        Text('⚡ AI ENGINE EVENT:').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.aiLogColor).margin({ right: 12 })
        Text(this.aiLog).fontSize(14).fontColor(this.isNightMode ? '#FFF' : '#1A1A1A').fontFamily('monospace')
      }
      .width('100%').height(48).padding({ left: 24 }).backgroundColor(this.isNightMode ? 'rgba(0,0,0,0.5)' : 'rgba(255,255,255,0.4)')
      .borderRadius(24).border({ width: 1, color: this.isNightMode ? 'rgba(0, 229, 255, 0.3)' : 'rgba(0, 119, 153, 0.3)' })
    }
    .width('100%').height('100%').padding(32)
  }

  @Builder StatusIndicator(lbl: string, val: string, clr: string) {
    Column() {
      Text(lbl).fontSize(10).fontColor(this.isNightMode ? '#A0AAB5' : '#888').margin({ bottom: 4 })
      Text(val).fontSize(12).fontWeight(FontWeight.Bold).fontColor(clr)
    }.alignItems(HorizontalAlign.End)
  }
}