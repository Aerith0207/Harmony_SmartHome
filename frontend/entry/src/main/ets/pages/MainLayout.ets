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
struct MainLayout {
  @State currentIndex: number = 0;
  @State isNightMode: boolean = false;

  private tabItems: TabItem[] = [
    { title: '全屋总览', subTitle: 'OVERVIEW' },
    { title: '控制中心', subTitle: 'CONTROLS' },
    { title: '个人中心', subTitle: 'PROFILE' }
  ];

  build() {
    Stack() {
      // 🌟 背景层：根据模式切换图片，并让夜间模式的图片镜像翻转
      Image(this.isNightMode ? $r('app.media.night_bg') : $r('app.media.day_bg'))
        .width('100%').height('100%')
        .objectFit(ImageFit.Cover)
        .backgroundColor(this.isNightMode ? '#07090C' : '#E8ECEF')
        .rotate({ y: 1, angle: this.isNightMode ? 180 : 0 }) // 镜像反转魔法

      Column().width('100%').height('100%').backdropBlur(40)

      Row() {
        Column() {
          Text("SYSTEM")
            .fontSize(11).fontColor(this.isNightMode ? '#00E5FF' : '#007799').letterSpacing(3).margin({ top: 40, bottom: 4 })
          Text("智能中控台")
            .fontSize(20).fontWeight(FontWeight.Bold).fontColor(this.isNightMode ? '#FFFFFF' : '#1A1A1A').margin({ bottom: 40 })

          ForEach(this.tabItems, (item: TabItem, index: number) => {
            Column() {
              Row() {
                Column() {
                  Text(item.title).fontSize(15).fontWeight(this.currentIndex === index ? FontWeight.Bold : FontWeight.Normal)
                    .fontColor(this.currentIndex === index ? (this.isNightMode ? '#00E5FF' : '#0066CC') : (this.isNightMode ? '#C0C8D0' : '#556677'))
                  Text(item.subTitle).fontSize(9)
                    .fontColor(this.currentIndex === index ? (this.isNightMode ? '#00E5FF' : '#0066CC') : (this.isNightMode ? '#A0AAB5' : '#8899AA'))
                    .margin({ top: 2 })
                }.alignItems(HorizontalAlign.Start)

                Blank()

                if (this.currentIndex === index) {
                  Circle({ width: 6, height: 6 }).fill(this.isNightMode ? '#00E5FF' : '#0066CC').shadow({ radius: 5, color: this.isNightMode ? '#00E5FF' : '#0066CC' })
                }
              }
              .width('100%').height(64).padding({ left: 20, right: 20 }).borderRadius(20)
              .backgroundColor(this.currentIndex === index ? (this.isNightMode ? 'rgba(0, 229, 255, 0.05)' : 'rgba(0, 102, 204, 0.08)') : 'transparent')
              .border({ width: this.currentIndex === index ? 1 : 0, color: this.isNightMode ? 'rgba(0, 229, 255, 0.15)' : 'rgba(0, 102, 204, 0.2)' })
            }
            .width('88%').margin({ bottom: 12 })
            .onClick(() => {
              this.currentIndex = index;
            })
          })

          Blank()

          Row() {
            Text(this.isNightMode ? '🌙 夜间' : '☀️ 白天').fontSize(14).fontColor(this.isNightMode ? '#FFF' : '#333')
            Toggle({ type: ToggleType.Switch, isOn: this.isNightMode })
              .onChange((val: boolean) => this.isNightMode = val)
          }.margin({bottom: 40}).padding(16).borderRadius(20).backgroundColor(this.isNightMode ? 'rgba(128,128,128,0.1)' : 'rgba(0,0,0,0.05)')

        }
        .width(240).height('100%')
        .backgroundColor(this.isNightMode ? 'rgba(0,0,0,0.4)' : 'rgba(255,255,255,0.7)')
        .border({ width: { right: 1 }, color: this.isNightMode ? 'rgba(255, 255, 255, 0.1)' : 'rgba(0, 0, 0, 0.05)' })

        Column() {
          if (this.currentIndex === 0) {
            HomePage({ isNightMode: this.isNightMode })
          } else if (this.currentIndex === 1) {
            ControlPage({ isNightMode: this.isNightMode })
          } else if (this.currentIndex === 2) {
            // 🌟 完美同步主题到个人中心
            ProfilePage({ isNightMode: this.isNightMode })
          }
        }
        .layoutWeight(1).height('100%').backgroundColor('transparent')
      }
      .width('100%')
      .height('100%')
    }
  }
}