// frontend/entry/src/main/ets/features/health/HealthPage.ets

import http from '@ohos.net.http';
import promptAction from '@ohos.promptAction';

function showToastSafe(msg: string): void {
  try {
    promptAction.showToast({ message: msg });
  } catch (error) {
    // 忽略异常
  }
}

class AiMessage {
  role: string = '';
  content: string = '';
}

class AiRequestPayload {
  model: string = '';
  messages: AiMessage[] = [];
}

interface AiResponseMessage {
  content: string;
}

interface AiResponseChoice {
  message: AiResponseMessage;
}

interface AiResponse {
  choices: AiResponseChoice[];
}

@Observed
export class CommunityPostData {
  id: string = '';
  author: string = '';
  title: string = '';
  content: string = '';
  likes: number = 0;
  isLiked: boolean = false;
  isUser: boolean = false;
}

const SYSTEM_TIPS_POOL: CommunityPostData[] = [
  { id: 's1', author: '👨‍💻 极客老王', title: '夏天空调开多少度最适合睡觉？', content: '我个人觉得26度+睡眠模式最舒服，也不容易得空调病，亲测有效。', likes: 128, isLiked: false, isUser: false },
  { id: 's2', author: '👩‍⚕️ 李医生', title: '警惕！夜间长明灯对褪黑素的抑制', content: '研究表明，如果凌晨还在接触强光，第二天的精神状态会下降30%，强烈建议设置定时关灯。', likes: 342, isLiked: false, isUser: false },
  { id: 's3', author: '🍃 养生达人', title: '加湿器里千万别加自来水！', content: '自来水里的矿物质会被打碎成PM2.5散布在空气中，推荐使用纯净水或者蒸馏水。', likes: 56, isLiked: false, isUser: false }
];

@Component
struct CommunityPostItemView {
  @ObjectLink post: CommunityPostData;
  @Prop isNightMode: boolean;
  onDelete: (id: string) => void = (id: string): void => {};

  build() {
    Column({ space: 6 }) {
      Row() {
        if (this.post.title) {
          Text(this.post.title)
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.isNightMode ? '#FFF' : '#333')
            .layoutWeight(1)
        }

        Text('✖')
          .fontSize(12)
          .fontColor(this.isNightMode ? '#8899AA' : '#A0AAB5')
          .padding(4)
          .borderRadius(12)
          .backgroundColor(this.isNightMode ? '#3A3F48' : '#F5F7FA')
          .onClick((): void => this.onDelete(this.post.id))
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)

      Text(this.post.content)
        .fontSize(13)
        .fontColor(this.isNightMode ? '#B0BEC5' : '#666')
        .lineHeight(18)
        .maxLines(3)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 4 })

      Row() {
        Text(this.post.author)
          .fontSize(11)
          .fontColor(this.isNightMode ? '#00E5FF' : '#007799')
        Blank()
        Row({ space: 4 }) {
          Text(this.post.isLiked ? '❤️' : '👍')
            .fontSize(12)
            .animation({ duration: 300, curve: Curve.EaseOut })
          Text(`${this.post.likes}`)
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.post.isLiked ? '#FF1744' : (this.isNightMode ? '#8899AA' : '#999'))
        }
        .padding({ top: 4, bottom: 4, left: 10, right: 10 })
        .backgroundColor(this.post.isLiked ? 'rgba(255, 23, 68, 0.1)' : (this.isNightMode ? '#3A3F48' : '#F5F7FA'))
        .borderRadius(12)
        .onClick((): void => {
          this.post.isLiked = !this.post.isLiked;
          this.post.likes += this.post.isLiked ? 1 : -1;
        })
      }
      .width('100%')
      .margin({ top: 4 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.isNightMode ? '#2A2E35' : '#F5F7FA')
    .borderRadius(16)
    .border({ width: 1, color: this.isNightMode ? '#3A3F48' : '#E0E4E8' })
  }
}

@Component
export struct HealthPage {
  @Prop isNightMode: boolean;

  @State healthScore: number = 100;
  @State healthEvalText: string = '环境数据分析中...';
  @State acUsageText: string = '暂无历史记录';
  @State isAiLoading: boolean = false;

  @StorageLink('global_realTemp') @Watch('onEnvChange') realTemp: string = '26.0';
  @StorageLink('global_realHum') @Watch('onEnvChange') realHum: string = '45.0';
  @StorageLink('global_isAcOn') isAcOn: boolean = false;
  @StorageLink('global_acTemp') targetTemp: number = 24;
  @StorageLink('global_isMainLightOn') isMainLightOn: boolean = false;

  @State aiAdvice: string = "正在连接 AI 引擎，综合分析全屋环境与设备运行数据...";
  @StorageLink('global_health_tips') postList: CommunityPostData[] = [];
  @State newPostContent: string = '';

  aboutToAppear() {
    this.onEnvChange();
    this.fetchAiAdvice();
    if (this.postList.length === 0) {
      this.refreshTips(true);
    }
  }

  refreshTips(isInit: boolean = false): void {
    let userPosts = this.postList.filter((p: CommunityPostData): boolean => p.isUser);
    let shuffled = [...SYSTEM_TIPS_POOL].sort((a: CommunityPostData, b: CommunityPostData): number => 0.5 - Math.random());
    let newSystemPosts = shuffled.slice(0, 3).map((tip: CommunityPostData): CommunityPostData => {
      let p = new CommunityPostData();
      p.id = tip.id + '_' + Date.now() + Math.random();
      p.author = tip.author;
      p.title = tip.title;
      p.content = tip.content;
      p.likes = tip.likes;
      p.isLiked = false;
      p.isUser = false;
      return p;
    });
    this.postList = [...userPosts, ...newSystemPosts];
    if (!isInit) {
      showToastSafe('系统建议已刷新');
    }
  }

  publishMyPost(): void {
    if (this.newPostContent.trim() === '') {
      showToastSafe('内容不能为空哦');
      return;
    }
    let myPost = new CommunityPostData();
    myPost.id = 'my_' + Date.now().toString();
    myPost.author = '👤 user';
    myPost.title = '随手记';
    myPost.content = this.newPostContent;
    myPost.likes = 0;
    myPost.isLiked = false;
    myPost.isUser = true;

    this.postList = [myPost, ...this.postList];
    this.newPostContent = '';
    showToastSafe('已保存至消息栏！');
  }

  deletePost(id: string): void {
    this.postList = this.postList.filter((p: CommunityPostData): boolean => p.id !== id);
    showToastSafe('已删除');
  }

  onEnvChange(): void {
    let t = parseFloat(this.realTemp) || 25.0;
    let h = parseFloat(this.realHum) || 50.0;
    let score = 100.0 - (Math.abs(t - 25.0) * 4) - (Math.abs(h - 50.0) * 0.5);
    this.healthScore = Math.max(0, Math.min(100, Math.round(score)));

    if (this.healthScore >= 90) {
      this.healthEvalText = '各项瞬时环境指标极佳，适宜长期居住与深度睡眠。';
    } else if (this.healthScore >= 75) {
      this.healthEvalText = '环境整体舒适，部分指标存在波动，系统将自动微调。';
    } else {
      this.healthEvalText = '当前温湿度可能引起体感不适，建议立刻干预！';
    }

    this.acUsageText = this.isAcOn ? '空调正在实时运转中' : '设备处于待机休眠状态';
  }

  fetchAiAdvice(): void {
    this.isAiLoading = true;
    this.aiAdvice = "管家正在思考中，请稍候...";

    try {
      let httpRequest = http.createHttp();

      // 🌟 修复点：严格实例化类，替代原来的匿名 JSON 构建
      let reqMsg = new AiMessage();
      reqMsg.role = "user";
      reqMsg.content = `当前温度${this.realTemp}度，湿度${this.realHum}%。给出一句贴心关怀与建议，60字内。`;

      let reqPayload = new AiRequestPayload();
      reqPayload.model = "deepseek-chat";
      reqPayload.messages = [reqMsg];

      let payloadStr = JSON.stringify(reqPayload);

      httpRequest.request(
        "https://api.deepseek.com/chat/completions",
        {
          method: http.RequestMethod.POST,
          header: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer 您的API_KEY_填在这里'
          },
          readTimeout: 15000,
          extraData: payloadStr
        },
        (err: Error, data: http.HttpResponse): void => {
          if (!err && data.responseCode === 200) {
            try {
              let res = JSON.parse(data.result as string) as AiResponse;
              this.aiAdvice = res.choices[0].message.content;
            } catch (e) {
              this.aiAdvice = "数据解析异常。";
            }
          } else {
            this.aiAdvice = "AI 引擎暂时离线，请检查网络。(建议：当前室内湿度偏低，建议开启加湿器)";
          }
          this.isAiLoading = false;
          try { httpRequest.destroy(); } catch(e) {}
        }
      );
    } catch (e) {
      this.isAiLoading = false;
      this.aiAdvice = "请求发送失败。";
    }
  }

  build() {
    Column({ space: 24 }) {
      Row() {
        Text('健康生活与环境感知')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.isNightMode ? '#FFF' : '#1A1A1A');
        Blank();
        Text('HEALTH & LIFESTYLE')
          .fontColor(this.isNightMode ? '#00E5FF' : '#007799')
          .fontSize(14)
          .letterSpacing(2)
      }
      .width('100%')

      Row({ space: 24 }) {
        Column({ space: 20 }) {
          Row() {
            Stack() {
              Circle({ width: 100, height: 100 })
                .fill('transparent')
                .stroke(this.isNightMode ? 'rgba(0, 255, 0, 0.2)' : 'rgba(0, 200, 0, 0.2)')
                .strokeWidth(4)
              Circle({ width: 100, height: 100 })
                .fill('transparent')
                .stroke(this.healthScore >= 80 ? '#00FF00' : (this.healthScore >= 60 ? '#FF9100' : '#FF1744'))
                .strokeWidth(4)
                .strokeDashArray([(this.healthScore / 100) * 314, 314])
                .animation({ duration: 800, curve: Curve.FastOutSlowIn })
              Column() {
                Text(this.healthScore.toString())
                  .fontSize(36)
                  .fontWeight(FontWeight.Bolder)
                  .fontColor(this.healthScore >= 80 ? (this.isNightMode ? '#FFF' : '#1A1A1A') : '#FF1744');
                Text('分')
                  .fontSize(12)
                  .fontColor(this.isNightMode ? '#A0AAB5' : '#888')
              }
            }
            Column({ space: 8 }) {
              Text('瞬时环境综合评级')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.isNightMode ? '#FFF' : '#1A1A1A');
              Text(this.healthEvalText)
                .fontSize(13)
                .fontColor(this.isNightMode ? '#B0BEC5' : '#667788')
                .lineHeight(20)
            }
            .layoutWeight(1)
            .margin({ left: 24 })
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')
          .padding(24)
          .backgroundColor(this.isNightMode ? '#1E222B' : '#FFFFFF')
          .borderRadius(24)
          .border({ width: 1, color: this.isNightMode ? '#2A2E35' : '#E0E4E8' })

          Row({ space: 16 }) {
            this.StatCard('❄️', '当前空调状态', this.isAcOn ? 'ON' : 'OFF', this.acUsageText, this.isAcOn ? '#00E5FF' : '#888')
            this.StatCard('💡', '当前光照干预', '无需', '当前未检测到异常光照', '#00FF00')
          }
          .width('100%')

          Column({ space: 16 }) {
            Text('设备行为与作息分析')
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.isNightMode ? '#FFF' : '#333')
              .alignSelf(ItemAlign.Start)

            this.BehaviorCard(
              '🌡️',
              '空调能耗与健康',
              this.isAcOn ? `设定温度 ${this.targetTemp}℃` : '处于关机状态',
              !this.isAcOn ? '设备当前处于休眠状态，主要依靠自然通风。' :
                (this.targetTemp < 24 ? '温度设定过低，夜间冷风直吹易引发感冒，建议调高至 26℃。' :
                  (this.targetTemp > 28 ? '温度设定过高，易导致体感闷热、出汗，建议适度调低。' : '温度设定适宜，有利于维持舒适睡眠并兼顾全屋节能。')),
              !this.isAcOn ? (this.isNightMode ? '#8899AA' : '#99AABB') :
                (this.targetTemp < 24 ? '#00E5FF' : (this.targetTemp > 28 ? '#FF1744' : '#00FF00'))
            )

            this.BehaviorCard(
              '🌙',
              '灯光与褪黑素',
              this.isMainLightOn ? '光源活跃中' : '光源已关闭',
              this.isMainLightOn ? '若当前已至深夜，持续开启主灯会抑制褪黑素分泌，存在熬夜伤身风险。' : '保持环境昏暗，有助于快速进入深度睡眠。',
              this.isMainLightOn ? '#FF1744' : '#00FF00'
            )

            Row() {
              Text('💡 康居小贴士：人体在夜间新陈代谢减慢。通过智能联动，可在入睡后自动微调空调并切断光源。')
                .fontSize(12)
                .fontColor(this.isNightMode ? '#A0AAB5' : '#556677')
                .lineHeight(20)
            }
            .width('100%')
            .padding(16)
            .backgroundColor(this.isNightMode ? '#2A2E35' : '#F5F7FA')
            .borderRadius(16)
          }
          .width('100%')
          .padding(24)
          .layoutWeight(1)
          .backgroundColor(this.isNightMode ? '#1E222B' : '#FFFFFF')
          .borderRadius(24)
          .border({ width: 1, color: this.isNightMode ? '#2A2E35' : '#E0E4E8' })
        }
        .layoutWeight(5)
        .height('100%')

        Column({ space: 20 }) {
          Column() {
            Row() {
              Text('✨ AI 健康管家分析')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.isNightMode ? '#00E5FF' : '#007799');
              Blank();
              Button(this.isAiLoading ? '请求中...' : '重新生成')
                .fontSize(11)
                .height(28)
                .backgroundColor(this.isNightMode ? '#2A2E35' : '#E0EBF5')
                .fontColor(this.isNightMode ? '#00E5FF' : '#007799')
                .onClick((): void => {
                  if (!this.isAiLoading) this.fetchAiAdvice();
                })
            }
            .width('100%')
            .margin({ bottom: 16 })

            Text(this.aiAdvice)
              .fontSize(14)
              .fontColor(this.isNightMode ? '#E0E0E0' : '#444')
              .lineHeight(24)
          }
          .width('100%')
          .padding(24)
          .backgroundColor(this.isNightMode ? '#1E222B' : '#FFFFFF')
          .borderRadius(24)
          .border({ width: 1, color: this.isNightMode ? '#2A2E35' : '#E0E4E8' })

          Column() {
            Row() {
              Text('健康消息与备忘录')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.isNightMode ? '#FFF' : '#333');
              Blank();
              Row({ space: 6 }) {
                Text('🔄').fontSize(14);
                Text('换一批')
                  .fontSize(12)
                  .fontColor(this.isNightMode ? '#00E5FF' : '#007799')
              }
              .padding(8)
              .borderRadius(12)
              .backgroundColor(this.isNightMode ? '#2A2E35' : '#F5F7FA')
              .onClick((): void => this.refreshTips())
            }
            .width('100%')
            .margin({ bottom: 16 })

            List({ space: 16 }) {
              ForEach(this.postList, (post: CommunityPostData) => {
                ListItem() {
                  CommunityPostItemView({
                    post: post,
                    isNightMode: this.isNightMode,
                    onDelete: (id: string): void => this.deletePost(id)
                  })
                }
              }, (post: CommunityPostData): string => post.id)
            }
            .width('100%')
            .height('100%')
            .layoutWeight(1)

            Row({ space: 12 }) {
              TextInput({ placeholder: '记录一下你的健康备忘录...', text: this.newPostContent })
                .layoutWeight(1)
                .height(44)
                .borderRadius(22)
                .backgroundColor(this.isNightMode ? '#2A2E35' : '#F5F7FA')
                .fontColor(this.isNightMode ? '#FFF' : '#333')
                // 🌟 同步修复这里输入框占位符看不清的问题
                .placeholderColor(this.isNightMode ? '#8899AA' : '#888')
                .onChange((val: string): void => { this.newPostContent = val; })
                .onSubmit((): void => this.publishMyPost())

              Button('保存')
                .height(44)
                .borderRadius(22)
                .backgroundColor(this.isNightMode ? '#00E5FF' : '#007799')
                .fontColor('#FFF')
                .onClick((): void => this.publishMyPost())
            }
            .width('100%')
            .margin({ top: 16 })
          }
          .width('100%')
          .padding(24)
          .layoutWeight(1)
          .backgroundColor(this.isNightMode ? '#1E222B' : '#FFFFFF')
          .borderRadius(24)
          .border({ width: 1, color: this.isNightMode ? '#2A2E35' : '#E0E4E8' })
        }
        .layoutWeight(5)
        .height('100%')
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .padding(32)
  }

  @Builder StatCard(icon: string, title: string, value: string, subDesc: string, color: string) {
    Column({ space: 8 }) {
      Row() {
        Text(icon).fontSize(22);
        Blank();
        Circle({ width: 8, height: 8 }).fill(color).animation({ duration: 300 })
      }
      .width('100%')

      Text(title)
        .fontSize(13)
        .fontColor(this.isNightMode ? '#A0AAB5' : '#888')
        .alignSelf(ItemAlign.Start)

      Text(value)
        .fontSize(32)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.isNightMode ? '#FFF' : '#1A1A1A')
        .alignSelf(ItemAlign.Start)
        .animation({ duration: 300 })

      Text(subDesc)
        .fontSize(11)
        .fontColor(color)
        .alignSelf(ItemAlign.Start)
        .animation({ duration: 300 })
    }
    .layoutWeight(1)
    .padding(20)
    .backgroundColor(this.isNightMode ? '#2A2E35' : '#F5F7FA')
    .borderRadius(20)
    .border({ width: 1, color: this.isNightMode ? '#3A3F48' : '#E0E4E8' })
  }

  @Builder BehaviorCard(icon: string, title: string, dataStr: string, advice: string, statusColor: string) {
    Row({ space: 16 }) {
      Text(icon).fontSize(28)
      Column({ space: 6 }) {
        Row() {
          Text(title)
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.isNightMode ? '#FFF' : '#333')
          Blank()
          Text(dataStr)
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .fontColor(statusColor)
        }
        .width('100%')
        Text(advice)
          .fontSize(13)
          .fontColor(this.isNightMode ? '#E0E0E0' : '#556677')
          .lineHeight(20)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .layoutWeight(1)
    .padding(20)
    .backgroundColor(this.isNightMode ? '#2A2E35' : '#F5F7FA')
    .borderRadius(20)
    .border({ width: 1, color: this.isNightMode ? '#3A3F48' : '#E0E4E8' })
  }
}