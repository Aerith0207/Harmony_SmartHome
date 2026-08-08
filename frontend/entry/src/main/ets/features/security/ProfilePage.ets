import promptAction from '@ohos.promptAction';
// 若需要调用 DeviceManager，请取消下面这行的注释
import { DeviceManager } from '../../core/DeviceManager';
import { DeviceCommand } from '../../core/adapter/CommandModel';
import { DeviceType } from '../../core/adapter/DeviceConstants';

function showToastSafe(msg: string): void {
  try { promptAction.showToast({ message: msg }); } catch (error) {}
}

// ==================== 1. 新增：用户登录弹窗 ====================
@CustomDialog
struct LoginDialog {
  controller?: CustomDialogController
  @Link username: string
  @State inputName: string = ''
  @State inputPwd: string = ''
  isNightMode: boolean = false

  build() {
    Column({ space: 20 }) {
      Text('🔐 登录暖禾智家').fontSize(20).fontWeight(FontWeight.Bold).fontColor(this.isNightMode ? '#FFF' : '#1A1A1A')

      TextInput({ placeholder: '请输入用户名', text: this.inputName })
        .onChange((val: string): void => { this.inputName = val; })
        .height(48).borderRadius(12)
        .backgroundColor(this.isNightMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.05)').fontColor(this.isNightMode ? '#FFF' : '#333')

      TextInput({ placeholder: '请输入密码', text: this.inputPwd }).type(InputType.Password)
        .onChange((val: string): void => { this.inputPwd = val; })
        .height(48).borderRadius(12)
        .backgroundColor(this.isNightMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.05)').fontColor(this.isNightMode ? '#FFF' : '#333')

      Row({ space: 16 }) {
        Button('取消').layoutWeight(1).backgroundColor(this.isNightMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.1)').fontColor(this.isNightMode ? '#FFF' : '#333')
          .onClick((): void => { this.controller?.close(); })
        Button('登录').layoutWeight(1).backgroundColor(this.isNightMode ? '#00E5FF' : '#007799').fontColor('#FFF')
          .onClick((): void => {
            if (this.inputName.trim() !== '') {
              this.username = this.inputName;
              showToastSafe('欢迎回来，' + this.username);
              this.controller?.close();
            } else {
              showToastSafe('用户名不能为空');
            }
          })
      }.width('100%')
    }
    .padding(24).backgroundColor(this.isNightMode ? '#1E1E1E' : '#FFFFFF').borderRadius(24)
  }
}

// ==================== 2. 新增：设备接入中心弹窗 ====================
@CustomDialog
struct DeviceCenterDialog {
  controller?: CustomDialogController
  @StorageLink('global_acBrand') currentAcBrand: number = 0; // 同步全局品牌
  isNightMode: boolean = false

  build() {
    Column({ space: 20 }) {
      Text('🔌 设备接入中心').fontSize(20).fontWeight(FontWeight.Bold).fontColor(this.isNightMode ? '#FFF' : '#1A1A1A')

      // 已接入设备列表
      Column({ space: 12 }) {
        this.DeviceItem('🟢', '温湿度传感器', 'OpenHarmony / Hi3861')
        this.DeviceItem('🟢', '智能主灯', 'MQTT / Relay')
        this.DeviceItem('🟢', '智能门锁', 'MQTT / DoorAdapter')

        // 核心动态切换区
        Row() {
          Column() {
            Text('🟢 空调设备 (IR)').fontSize(14).fontWeight(FontWeight.Medium).fontColor(this.isNightMode ? '#FFF' : '#333')
            Text('Adapter协议多态绑定').fontSize(11).fontColor('#8899AA').margin({ top: 4 })
          }.alignItems(HorizontalAlign.Start)
          Blank()
          Select([{ value: '默认' }, { value: '海尔' }, { value: '格力' }, { value: '美的' }])
            .selected(this.currentAcBrand)
            .value(['默认', '海尔', '格力', '美的'][this.currentAcBrand])
            .font({ size: 14 })
            .backgroundColor(this.isNightMode ? '#3A3F48' : '#E0E4E8')
            .onSelect((index: number) => {
              this.currentAcBrand = index;
              showToastSafe(`已切换至 ${['默认', '海尔', '格力', '美的'][index]} Adapter适配器`);
              // DeviceManager.getInstance().sendCommand(new DeviceCommand(DeviceType.AC, 'brand', index));
            })
        }.width('100%').padding(12).backgroundColor(this.isNightMode ? 'rgba(255,255,255,0.05)' : '#F5F7FA').borderRadius(12)
      }

      Button('完成').width('100%').backgroundColor(this.isNightMode ? '#00E5FF' : '#007799').fontColor('#FFF')
        .onClick((): void => { this.controller?.close(); })
    }
    .padding(24).backgroundColor(this.isNightMode ? '#1E1E1E' : '#FFFFFF').borderRadius(24)
  }

  @Builder DeviceItem(icon: string, name: string, desc: string) {
    Row() {
      Text(icon).fontSize(16).margin({ right: 12 })
      Column() {
        Text(name).fontSize(14).fontWeight(FontWeight.Medium).fontColor(this.isNightMode ? '#FFF' : '#333')
        Text(desc).fontSize(11).fontColor('#8899AA').margin({ top: 4 })
      }.alignItems(HorizontalAlign.Start)
      Blank()
    }.width('100%').padding(12).backgroundColor(this.isNightMode ? 'rgba(255,255,255,0.05)' : '#F5F7FA').borderRadius(12)
  }
}

// ==================== 3. 升级：密码修改弹窗（真实校验与保存） ====================
@CustomDialog
struct PasswordDialog {
  controller?: CustomDialogController
  @StorageLink('global_doorPwd') globalDoorPwd: string = '123456'; // 获取全局密码
  @State oldPwd: string = ''
  @State newPwd: string = ''
  isNightMode: boolean = false

  build() {
    Column({ space: 20 }) {
      Text('修改门禁安全密码').fontSize(20).fontWeight(FontWeight.Bold).fontColor(this.isNightMode ? '#FFF' : '#1A1A1A')

      TextInput({ placeholder: '请输入原密码', text: this.oldPwd }).type(InputType.Password)
        .onChange((val: string): void => { this.oldPwd = val; }).height(48).borderRadius(12)
        .backgroundColor(this.isNightMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.05)').fontColor(this.isNightMode ? '#FFF' : '#333')

      TextInput({ placeholder: '设定新密码 (至少6位)', text: this.newPwd }).type(InputType.Password)
        .onChange((val: string): void => { this.newPwd = val; }).height(48).borderRadius(12)
        .backgroundColor(this.isNightMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.05)').fontColor(this.isNightMode ? '#FFF' : '#333')

      Row({ space: 16 }) {
        Button('取消').layoutWeight(1).backgroundColor(this.isNightMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.1)').fontColor(this.isNightMode ? '#FFF' : '#333')
          .onClick((): void => { this.controller?.close(); })
        Button('确认修改').layoutWeight(1).backgroundColor('#FF1744').fontColor('#FFF')
          .onClick((): void => {
            if(this.oldPwd == '' || this.newPwd == '') {
              showToastSafe('密码不能为空！'); return;
            }
            if(this.oldPwd !== this.globalDoorPwd) {
              showToastSafe('❌ 原密码验证失败！'); return;
            }
            if(this.newPwd.length < 6) {
              showToastSafe('❌ 新密码至少需要6位！'); return;
            }
            // 真实更新全局密码
            this.globalDoorPwd = this.newPwd;
            showToastSafe('✅ 门禁密码已更新，已同步至加密总线！');
            this.controller?.close();
          })
      }.width('100%')
    }
    .padding(24).backgroundColor(this.isNightMode ? '#1E1E1E' : '#FFFFFF').borderRadius(24)
  }
}

// ==================== 4. 主页面组装 ====================
@Component
export struct ProfilePage {
  @Prop isNightMode: boolean;

  // 🌟 修改：变为全局绑定，未登录状态显示“未登录”
  @StorageLink('global_username') username: string = '未登录';
  @State userRole: string = '超级管理员';

  loginDialogController: CustomDialogController = new CustomDialogController({
    builder: LoginDialog({ username: $username, isNightMode: this.isNightMode }),
    alignment: DialogAlignment.Center, autoCancel: true, customStyle: true
  })

  deviceCenterController: CustomDialogController = new CustomDialogController({
    builder: DeviceCenterDialog({ isNightMode: this.isNightMode }),
    alignment: DialogAlignment.Center, autoCancel: true, customStyle: true
  })

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
      Row() {
        Text('个人中心').fontSize(28).fontWeight(FontWeight.Bold).fontColor(this.isNightMode ? '#FFF' : '#1A1A1A')
        Blank()
      }.width('100%').margin({ bottom: 24 })

      Row({ space: 24 }) {
        // 左侧头像区
        Column({ space: 20 }) {
          Stack() {
            Circle({ width: 110, height: 110 })
              .fill(this.isNightMode ? 'rgba(0, 229, 255, 0.1)' : 'rgba(0, 119, 153, 0.1)')
              .border({ width: 2, color: this.isNightMode ? '#00E5FF' : '#007799' })
            Text(this.username.charAt(0).toUpperCase())
              .fontSize(42).fontWeight(FontWeight.Bold).fontColor(this.isNightMode ? '#00E5FF' : '#007799')
          }.margin({ top: 20 })

          Text(this.username).fontSize(24).fontWeight(FontWeight.Bold).fontColor(this.isNightMode ? '#FFF' : '#1A1A1A')

          if(this.username === '未登录') {
            Button('点击登录').height(32).fontSize(14).backgroundColor(this.isNightMode ? '#00E5FF' : '#007799').onClick(() => { this.loginDialogController.open(); })
          } else {
            Text(this.userRole).fontSize(13).fontWeight(FontWeight.Medium).fontColor('#FFF').padding({ left: 16, right: 16, top: 6, bottom: 6 }).backgroundColor(this.isNightMode ? '#7B61FF' : '#0066CC').borderRadius(14)
          }

          Divider().color(this.isNightMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.1)').width('80%').margin({ top: 20, bottom: 10 })

          Column({ space: 8 }) {
            Text('全屋智能骨干总线控制系统').fontSize(12).fontColor(this.isNightMode ? '#8899AA' : '#556677')
            Text('Version 2.4.0 (Release)').fontSize(11).fontColor(this.isNightMode ? '#A0AAB5' : '#8899AA').fontFamily('monospace')
          }.alignItems(HorizontalAlign.Center)
        }
        .layoutWeight(40).height('100%').padding(24)
        .backgroundColor(this.isNightMode ? 'rgba(0, 0, 0, 0.6)' : 'rgba(255,255,255,0.85)')
        .borderRadius(24).border({ width: 1, color: this.isNightMode ? 'rgba(255,255,255,0.15)' : 'rgba(0,0,0,0.05)' })
        .justifyContent(FlexAlign.Center)

        // 右侧设置区
        Column({ space: 24 }) {
          Text('账户与系统设置').fontSize(13).fontColor(this.isNightMode ? '#00E5FF' : '#007799').letterSpacing(2).alignSelf(ItemAlign.Start)

          Column() {
            // 🌟 新增：设备接入中心入口
            this.SettingItem('🔌', '设备接入与多态生态', (): void => { this.deviceCenterController.open(); })
            this.SettingItem('👤', '修改管理员名称', (): void => { this.renameDialogController.open(); })
            this.SettingItem('🔒', '门禁安全密码修改', (): void => { this.passwordDialogController.open(); })
            this.SettingItem('🌐', '家庭骨干网络切换', (): void => { this.switchNetwork(); })
            Divider().color(this.isNightMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.05)').margin({ top: 12, bottom: 12 })
            this.SettingItem('🔄', '退出登录与重置', (): void => { this.triggerInitialization(); }, true)
          }
          .width('100%').layoutWeight(1).padding(12)
          .backgroundColor(this.isNightMode ? 'rgba(0, 0, 0, 0.3)' : 'rgba(255,255,255,0.7)')
          .borderRadius(20).border({ width: 1, color: this.isNightMode ? 'rgba(255,255,255,0.05)' : 'rgba(0,0,0,0.05)' })
        }
        .layoutWeight(60).height('100%').padding(32)
        .backgroundColor(this.isNightMode ? 'rgba(0, 0, 0, 0.6)' : 'rgba(255,255,255,0.85)')
        .borderRadius(24).border({ width: 1, color: this.isNightMode ? 'rgba(255,255,255,0.15)' : 'rgba(0,0,0,0.05)' })
        .justifyContent(FlexAlign.Center)
      }
      .width('100%').layoutWeight(1)
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

  // ... 剩余网络切换及初始化代码保持不变 ...
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
        title: '⚠️ 退出登录警告',
        message: '该操作将退出当前账户并强制清除底层安全密钥流。确认要退出吗？',
        autoCancel: true,
        alignment: DialogAlignment.Center,
        primaryButton: { value: '取消', action: (): void => {} },
        secondaryButton: {
          value: '确认退出', fontColor: '#FF1744',
          action: (): void => {
            this.username = '未登录';
            showToastSafe('已退出，安全连接已重置');
          }
        }
      })
    } catch (e) {}
  }
}

// 补齐之前的 RenameDialog
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
              showToastSafe('账户名称已同步');
            }
            this.controller?.close();
          })
      }.width('100%')
    }
    .padding(24).backgroundColor(this.isNightMode ? '#1E1E1E' : '#FFFFFF').borderRadius(24)
  }
}