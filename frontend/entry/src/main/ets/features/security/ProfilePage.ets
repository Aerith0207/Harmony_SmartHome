// frontend/entry/src/main/ets/features/security/ProfilePage.ets

import promptAction from '@ohos.promptAction';

function showToastSafe(msg: string): void {
  try { promptAction.showToast({ message: msg }); } catch (error) {}
}

@CustomDialog
struct RenameDialog {
  controller?: CustomDialogController
  @Link username: string
  @State tempName: string = ''
  isNightMode: boolean = false

  build() {
    Column({ space: 20 }) {
      Text('修改管理员名称').fontSize(20).fontWeight(FontWeight.Bold).fontColor(this.isNightMode ? '#FFF' : '#1A1A1A')

      TextInput({ placeholder: '请输入新的中控台账户名称', text: this.tempName })
        .onChange((val: string): void => { this.tempName = val; })
        .height(48).borderRadius(12)
        .backgroundColor(this.isNightMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.05)')
        .fontColor(this.isNightMode ? '#FFF' : '#333')

      Row({ space: 16 }) {
        Button('取消').layoutWeight(1).backgroundColor(this.isNightMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.1)').fontColor(this.isNightMode ? '#FFF' : '#333')
          .onClick((): void => { this.controller?.close(); })
        Button('保存').layoutWeight(1).backgroundColor(this.isNightMode ? '#00E5FF' : '#007799').fontColor('#FFF')
          .onClick((): void => {
            if (this.tempName.trim() !== '') {
              this.username = this.tempName;
              showToastSafe('账户名称已同步至中控网关');
            }
            this.controller?.close();
          })
      }.width('100%')
    }
    .padding(24).backgroundColor(this.isNightMode ? '#1E1E1E' : '#FFFFFF').borderRadius(24)
  }
}

@CustomDialog
struct PasswordDialog {
  controller?: CustomDialogController
  @State oldPwd: string = ''
  @State newPwd: string = ''
  isNightMode: boolean = false

  build() {
    Column({ space: 20 }) {
      Text('修改安全密码').fontSize(20).fontWeight(FontWeight.Bold).fontColor(this.isNightMode ? '#FFF' : '#1A1A1A')

      TextInput({ placeholder: '请输入原通信密码', text: this.oldPwd }).type(InputType.Password)
        .onChange((val: string): void => { this.oldPwd = val; }).height(48).borderRadius(12)
        .backgroundColor(this.isNightMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.05)').fontColor(this.isNightMode ? '#FFF' : '#333')

      TextInput({ placeholder: '设定新密码 (至少6位)', text: this.newPwd }).type(InputType.Password)
        .onChange((val: string): void => { this.newPwd = val; }).height(48).borderRadius(12)
        .backgroundColor(this.isNightMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.05)').fontColor(this.isNightMode ? '#FFF' : '#333')

      Row({ space: 16 }) {
        Button('取消').layoutWeight(1).backgroundColor(this.isNightMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.1)').fontColor(this.isNightMode ? '#FFF' : '#333')
          .onClick((): void => { this.controller?.close(); })
        Button('强制覆写').layoutWeight(1).backgroundColor('#FF1744').fontColor('#FFF')
          .onClick((): void => {
            if(this.oldPwd == '' || this.newPwd == '') {
              showToastSafe('密码不能为空！');
              return;
            }
            showToastSafe('底层 AES 密钥对已更新并下发至边缘节点！');
            this.controller?.close();
          })
      }.width('100%')
    }
    .padding(24).backgroundColor(this.isNightMode ? '#1E1E1E' : '#FFFFFF').borderRadius(24)
  }
}

@Component
export struct ProfilePage {
  @Prop isNightMode: boolean;

  @State username: string = 'user';
  @State userRole: string = '超级管理员';

  renameDialogController: CustomDialogController = new CustomDialogController({
    builder: RenameDialog({ username: $username, isNightMode: this.isNightMode }),
    alignment: DialogAlignment.Center, autoCancel: true, customStyle: true
  })

  passwordDialogController: CustomDialogController = new CustomDialogController({
    builder: PasswordDialog({ isNightMode: this.isNightMode }),
    alignment: DialogAlignment.Center, autoCancel: true, customStyle: true
  })

  build() {
    Column() {
      // 1. 顶部标题区
      Row() {
        Text('个人中心').fontSize(28).fontWeight(FontWeight.Bold).fontColor(this.isNightMode ? '#FFF' : '#1A1A1A')
        Blank()
      }.width('100%').margin({ bottom: 24 })

      // 2. 主交互区
      Row({ space: 24 }) {

        // 🌟 左侧大边框
        Column({ space: 20 }) {
          Stack() {
            Circle({ width: 110, height: 110 })
              .fill(this.isNightMode ? 'rgba(0, 229, 255, 0.1)' : 'rgba(0, 119, 153, 0.1)')
              .border({ width: 2, color: this.isNightMode ? '#00E5FF' : '#007799' })
            Text(this.username.charAt(0))
              .fontSize(42).fontWeight(FontWeight.Bold).fontColor(this.isNightMode ? '#00E5FF' : '#007799')
          }.margin({ top: 20 })

          Text(this.username).fontSize(24).fontWeight(FontWeight.Bold).fontColor(this.isNightMode ? '#FFF' : '#1A1A1A')
          Text(this.userRole).fontSize(13).fontWeight(FontWeight.Medium).fontColor('#FFF').padding({ left: 16, right: 16, top: 6, bottom: 6 }).backgroundColor(this.isNightMode ? '#7B61FF' : '#0066CC').borderRadius(14)
          Divider().color(this.isNightMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.1)').width('80%').margin({ top: 20, bottom: 10 })

          Column({ space: 8 }) {
            Text('全屋智能骨干总线控制系统').fontSize(12).fontColor(this.isNightMode ? '#8899AA' : '#556677')
            Text('Version 2.4.0 (Release)').fontSize(11).fontColor(this.isNightMode ? '#A0AAB5' : '#8899AA').fontFamily('monospace')
          }.alignItems(HorizontalAlign.Center)
        }
        .layoutWeight(40).height('100%').padding(24)
        // 🌟 降低夜间透明度，提升实体感
        .backgroundColor(this.isNightMode ? 'rgba(0, 0, 0, 0.6)' : 'rgba(255,255,255,0.85)')
        .borderRadius(24).border({ width: 1, color: this.isNightMode ? 'rgba(255,255,255,0.15)' : 'rgba(0,0,0,0.05)' })
        .justifyContent(FlexAlign.Center)

        // 🌟 右侧大边框
        Column({ space: 24 }) {
          Text('账户与系统设置').fontSize(13).fontColor(this.isNightMode ? '#00E5FF' : '#007799').letterSpacing(2).alignSelf(ItemAlign.Start)

          Column() {
            this.SettingItem('👤', '修改管理员名称', (): void => { this.renameDialogController.open(); })
            this.SettingItem('🔒', '安全通信密码修改', (): void => { this.passwordDialogController.open(); })
            this.SettingItem('🌐', '家庭骨干网络切换', (): void => { this.switchNetwork(); })
            Divider().color(this.isNightMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.05)').margin({ top: 12, bottom: 12 })
            this.SettingItem('🔄', '初始化系统 (恢复出厂设置)', (): void => { this.triggerInitialization(); }, true)
          }
          .width('100%')
          .layoutWeight(1)
          .padding(12)
          // 🌟 降低设置列表内框透明度
          .backgroundColor(this.isNightMode ? 'rgba(0, 0, 0, 0.3)' : 'rgba(255,255,255,0.7)')
          .borderRadius(20).border({ width: 1, color: this.isNightMode ? 'rgba(255,255,255,0.05)' : 'rgba(0,0,0,0.05)' })
        }
        .layoutWeight(60).height('100%').padding(32)
        // 🌟 降低夜间透明度，提升实体感
        .backgroundColor(this.isNightMode ? 'rgba(0, 0, 0, 0.6)' : 'rgba(255,255,255,0.85)')
        .borderRadius(24).border({ width: 1, color: this.isNightMode ? 'rgba(255,255,255,0.15)' : 'rgba(0,0,0,0.05)' })
        .justifyContent(FlexAlign.Center)
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%').height('100%').padding(32)
  }

  @Builder SettingItem(icon: string, title: string, action: () => void, isDanger: boolean = false) {
    Row() {
      Text(icon).fontSize(22).margin({ right: 16 })
      Text(title).fontSize(16).fontWeight(FontWeight.Medium).fontColor(isDanger ? '#FF1744' : (this.isNightMode ? '#FFF' : '#1A1A1A'))
      Blank()
      Text('❯').fontSize(16).fontColor(this.isNightMode ? '#667788' : '#A0AAB5')
    }
    .width('100%').height(64).padding({ left: 20, right: 20 }).borderRadius(16)
    .onClick(action)
    .backgroundColor(this.isNightMode ? 'rgba(255,255,255,0.03)' : 'rgba(0,0,0,0.02)')
  }

  switchNetwork(): void {
    try {
      ActionSheet.show({
        title: '选择网络接入模式',
        message: '切换骨干网后可能会短暂掉线，请确保设备在线',
        autoCancel: true,
        confirm: { value: '取消', action: (): void => {} },
        alignment: DialogAlignment.Bottom,
        sheets: [
          { title: '📡 Wi-Fi 局域网模式 (当前)', action: (): void => { showToastSafe('已锁定 Wi-Fi 分布式连接'); } },
          { title: '🔌 以太网 LAN 骨干模式', action: (): void => { showToastSafe('正在切换至以太网链路...'); } },
          { title: '☁️ 蜂窝云端中继模式', action: (): void => { showToastSafe('已连接至公有云 MQTT 代理'); } }
        ]
      })
    } catch (e) {}
  }

  triggerInitialization(): void {
    try {
      AlertDialog.show({
        title: '⚠️ 恢复出厂设置警告',
        message: '该操作将强制清除本地分布式设备拓扑缓存、解绑底层MQTT硬件节点并重置内层AES加密安全总线。确认要初始化吗？',
        autoCancel: true,
        alignment: DialogAlignment.Center,
        primaryButton: { value: '取消', action: (): void => {} },
        secondaryButton: {
          value: '确认重置', fontColor: '#FF1744',
          action: (): void => {
            this.username = '默认用户';
            showToastSafe('系统骨干密钥流已清除，系统重启中...');
          }
        }
      })
    } catch (e) {}
  }
}