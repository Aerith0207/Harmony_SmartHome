// frontend/entry/src/main/ets/pages/MainLayout.ets
import { HomePage } from '../features/home/HomePage';
import { ControlPage } from '../features/climate/ControlPage';
import { ProfilePage } from '../features/security/ProfilePage';

interface TabItem {
  title: string;
  subTitle: string;
}

@Entry
@Component
export struct MainLayout {
  @State currentIndex: number = 0;

  private tabItems: TabItem[] = [
    { title: '全屋总览', subTitle: 'OVERVIEW' },
    { title: '控制中心', subTitle: 'CONTROLS' },
    { title: '安全配置', subTitle: 'SECURITY' }
  ];

  build() {
    // 采用最原始稳健的 Row 布局作为主架构容器
    Row() {
      // 左侧一体化导航控制列
      Column() {
        Text("SYSTEM")
          .fontSize(11).fontColor('#00E5FF').letterSpacing(3).margin({ top: 40, bottom: 4 })
        Text("智能中控台")
          .fontSize(20).fontWeight(FontWeight.Bold).fontColor('#FFFFFF').margin({ bottom: 40 })

        ForEach(this.tabItems, (item: TabItem, index: number) => {
          Column() {
            Row() {
              Column() {
                Text(item.title).fontSize(15).fontWeight(this.currentIndex === index ? FontWeight.Bold : FontWeight.Normal)
                  .fontColor(this.currentIndex === index ? '#00E5FF' : '#A0AAB5')
                Text(item.subTitle).fontSize(9).fontColor(this.currentIndex === index ? '#00E5FF' : '#506070').margin({ top: 2 })
              }.alignItems(HorizontalAlign.Start)

              Blank()

              if (this.currentIndex === index) {
                Circle({ width: 6, height: 6 }).fill('#00E5FF').shadow({ radius: 5, color: '#00E5FF' })
              }
            }
            .width('100%').height(64).padding({ left: 20, right: 20 }).borderRadius(12)
            .backgroundColor(this.currentIndex === index ? 'rgba(0, 229, 255, 0.05)' : 'transparent')
            .border({ width: this.currentIndex === index ? 1 : 0, color: 'rgba(0, 229, 255, 0.15)' })
          }
          .width('88%').margin({ bottom: 12 })
          .onClick(() => {
            this.currentIndex = index;
          })
        })
      }
      .width(240).height('100%').backgroundColor('#07090C')
      .border({ width: { right: 1 }, color: 'rgba(255, 255, 255, 0.05)' })

      // 右侧内容视窗，按需独立挂载对应的功能模块
      Column() {
        if (this.currentIndex === 0) {
          HomePage()
        } else if (this.currentIndex === 1) {
          ControlPage()
        } else if (this.currentIndex === 2) {
          ProfilePage()
        }
      }
      .layoutWeight(1).height('100%').backgroundColor('#0A0C10')
    }
    .width('100%')
    .height('100%')
  }
}