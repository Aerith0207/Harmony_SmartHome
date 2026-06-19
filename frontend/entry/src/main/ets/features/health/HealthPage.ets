// frontend/entry/src/main/ets/features/health/HealthPage.ets

import http from '@ohos.net.http';
import promptAction from '@ohos.promptAction';

// ==========================================
// 🌟 专为 ArkTS 严格模式定义的数据类和接口
// ==========================================
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

// 🌟 社区帖子数据模型
export class CommunityPostData {
  id: string = '';
  author: string = '';
  title: string = '';
  content: string = '';
  likes: number = 0;
  isLiked: boolean = false;
}

@Component
export struct HealthPage {
  @Prop isNightMode: boolean;

  // 环境算分与 AI 状态
  @State healthScore: number = 100;
  @State healthEvalText: string = '环境数据分析中...';
  @State acUsageText: string = '暂无历史记录';
  @State isAiLoading: boolean = false;

  @StorageLink('global_realTemp') @Watch('onEnvChange') realTemp: string = '26.0';
  @StorageLink('global_realHum') @Watch('onEnvChange') realHum: string = '45.0';
  @StorageLink('global_isAcOn') isAcOn: boolean = false;

  @State aiAdvice: string = "正在连接 AI 引擎，综合分析全屋环境与设备运行数据...";

  // 🌟 社区专属状态
  @State postList: CommunityPostData[] = [];
  @State isCommunityLoading: boolean = true;
  @State newPostContent: string = ''; // 用户自己输入的评论内容

  aboutToAppear() {
    this.onEnvChange();
    this.fetchAiAdvice();
    this.loadCommunityData();
  }

  // 环境算分算法
  onEnvChange() {
    let t = parseFloat(this.realTemp) || 25.0;
    let h = parseFloat(this.realHum) || 50.0;
    let score = 100.0 - (Math.abs(t - 25.0) * 4) - (Math.abs(h - 50.0) * 0.5);
    this.healthScore = Math.max(0, Math.min(100, Math.round(score)));

    if (this.healthScore >= 90) {
      this.healthEvalText = '各项瞬时环境指标极佳，适宜长期居住与深度睡眠。';
    } else if (this.healthScore >= 75) {
      this.healthEvalText = '环境整体舒适，部分指标存在波动，系统将通过智能场景自动微调。';
    } else {
      this.healthEvalText = '当前温湿度可能引起体感不适，建议立刻开启空调或加湿器干预！';
    }
    this.acUsageText = this.isAcOn ? '空调正在实时运转中' : '设备处于待机休眠状态';
  }

  // 大模型请求
  fetchAiAdvice() {
    this.isAiLoading = true;
    this.aiAdvice = "管家正在思考中，请稍候...";
    let httpRequest = http.createHttp();
    let promptText = `你现在是智能家居系统里的AI健康管家。当前瞬时室内温度为${this.realTemp}度，湿度为${this.realHum}%。请结合这些瞬时数据，用60个字以内给出一句贴心的人文关怀与调节建议。`;

    let reqMsg = new AiMessage();
    reqMsg.role = "user"; reqMsg.content = promptText;
    let payload = new AiRequestPayload();
    payload.model = "deepseek-chat"; payload.messages = [reqMsg];

    httpRequest.request(
      "https://api.deepseek.com/chat/completions",
      {
        method: http.RequestMethod.POST,
        header: { 'Content-Type': 'application/json', 'Authorization': 'Bearer 你的API_KEY_填在这里' },
        readTimeout: 15000,
        extraData: JSON.stringify(payload)
      },
      (err: Error, data: http.HttpResponse) => {
        if (!err && data.responseCode === 200) {
          try {
            let res = JSON.parse(data.result as string) as AiResponse;
            this.aiAdvice = res.choices[0].message.content;
          } catch (e) {
            this.aiAdvice = "数据解析异常，请稍后再试。";
          }
        } else {
          this.aiAdvice = "AI 引擎暂时离线，请检查网络或 API_KEY 配置。\n\n(建议：当前室内湿度偏低，建议开启加湿器，并尽量在今晚 23:30 前入睡。)";
        }
        this.isAiLoading = false;
        httpRequest.destroy();
      }
    );
  }

  // ==========================================
  // 🌟 社区交互：核心功能区
  // ==========================================

  // 1. 加载系统预设帖子
  loadCommunityData() {
    this.isCommunityLoading = true;
    setTimeout(() => {
      let p1 = new CommunityPostData();
      p1.id = 'p1'; p1.author = '👨‍💻 极客老王'; p1.title = '夏天空调开多少度最适合睡觉？'; p1.content = '我个人觉得26度+睡眠模式最舒服，也不容易得空调病，亲测有效。'; p1.likes = 128;

      let p2 = new CommunityPostData();
      p2.id = 'p2'; p2.author = '👩‍⚕️ 李医生'; p2.title = '警惕！夜间长明灯对褪黑素的抑制'; p2.content = '研究表明，如果凌晨还在接触强光，第二天的精神状态会下降30%，强烈建议设置定时关灯。'; p2.likes = 342;

      let p3 = new CommunityPostData();
      p3.id = 'p3'; p3.author = '🍃 养生达人'; p3.title = '加湿器里千万别加自来水！'; p3.content = '自来水里的矿物质会被打碎成PM2.5散布在空气中，推荐使用纯净水或者蒸馏水。'; p3.likes = 56;

      this.postList = [p1, p2, p3];
      this.isCommunityLoading = false;
    }, 1000);
  }

  // 2. 真实解决点赞刷新问题！
  toggleLike(postId: string) {
    let index = this.postList.findIndex(p => p.id === postId);
    if (index !== -1) {
      this.postList[index].isLiked = !this.postList[index].isLiked;
      this.postList[index].likes += this.postList[index].isLiked ? 1 : -1;

      // 🌟 ArkUI 的核心解法：重组数组，强行触发渲染！
      this.postList = [...this.postList];
    }
  }

  // 3. 发布我的评论
  publishMyPost() {
    if (this.newPostContent.trim() === '') {
      promptAction.showToast({ message: '评论内容不能为空哦' });
      return;
    }
    let myPost = new CommunityPostData();
    myPost.id = 'my_' + Date.now().toString(); // 生成唯一ID
    myPost.author = '👤 我 (系统管理员)';
    myPost.title = '新动态';
    myPost.content = this.newPostContent;
    myPost.likes = 0;
    myPost.isLiked = false;

    // 将我的评论塞入数组最前面，并重组数组触发刷新
    this.postList = [myPost, ...this.postList];
    this.newPostContent = ''; // 清空输入框
    promptAction.showToast({ message: '发布成功！' });
  }

  build() {
    Column({ space: 24 }) {
      Row() {
        Text('健康生活与环境感知').fontSize(28).fontWeight(FontWeight.Bold).fontColor(this.isNightMode ? '#FFF' : '#1A1A1A')
        Blank()
        Text('HEALTH & LIFESTYLE').fontColor(this.isNightMode ? '#00E5FF' : '#007799').fontSize(14).letterSpacing(2)
      }.width('100%')

      Row({ space: 24 }) {
        // ================= 左侧：数据统计区 =================
        Column({ space: 20 }) {
          Row() {
            Stack() {
              Circle({ width: 100, height: 100 }).fill('transparent').stroke(this.isNightMode ? 'rgba(0, 255, 0, 0.2)' : 'rgba(0, 200, 0, 0.2)').strokeWidth(4)
              Circle({ width: 100, height: 100 }).fill('transparent')
                .stroke(this.healthScore >= 80 ? '#00FF00' : (this.healthScore >= 60 ? '#FF9100' : '#FF1744'))
                .strokeWidth(4).strokeDashArray([(this.healthScore / 100) * 314, 314])
                .animation({ duration: 800, curve: Curve.FastOutSlowIn })
              Column() {
                Text(this.healthScore.toString()).fontSize(36).fontWeight(FontWeight.Bolder)
                  .fontColor(this.healthScore >= 80 ? (this.isNightMode ? '#FFF' : '#1A1A1A') : '#FF1744')
                Text('分').fontSize(12).fontColor(this.isNightMode ? '#A0AAB5' : '#888')
              }
            }
            Column({ space: 8 }) {
              Text('瞬时环境综合评级').fontSize(16).fontWeight(FontWeight.Bold).fontColor(this.isNightMode ? '#FFF' : '#1A1A1A')
              Text(this.healthEvalText).fontSize(12).fontColor(this.isNightMode ? '#8899AA' : '#667788').lineHeight(18)
            }.layoutWeight(1).margin({ left: 24 }).alignItems(HorizontalAlign.Start)
          }
          .width('100%').padding(24).backgroundColor(this.isNightMode ? 'rgba(255,255,255,0.05)' : 'rgba(255,255,255,0.85)')
          .borderRadius(24).border({ width: 1, color: this.isNightMode ? 'rgba(255,255,255,0.2)' : 'rgba(0,0,0,0.05)' })

          Row({ space: 16 }) {
            this.StatCard('❄️', '当前空调状态', this.isAcOn ? 'ON' : 'OFF', this.acUsageText, this.isAcOn ? '#00E5FF' : '#888')
            this.StatCard('💡', '当前光照干预', '无需', '当前未检测到异常光照', '#00FF00')
          }.width('100%')

          Column() {
            Text('室内温湿度稳定性 (近24小时)').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.isNightMode ? '#FFF' : '#333').margin({ bottom: 16 })
            Row({ space: 8 }) {
              ForEach([30, 45, 50, 60, 55, 65, 70, 60, 50, 40, 35, 45], (val: number) => {
                Column().width(12).height(`${val}%`).backgroundColor('#00E5FF').borderRadius(6).opacity(0.6)
              }, (val: number, index: number) => index.toString())
            }.width('100%').height(80).alignItems(VerticalAlign.Bottom).justifyContent(FlexAlign.SpaceAround)
          }
          .width('100%').padding(24).layoutWeight(1).backgroundColor(this.isNightMode ? 'rgba(255,255,255,0.05)' : 'rgba(255,255,255,0.85)')
          .borderRadius(24).border({ width: 1, color: this.isNightMode ? 'rgba(255,255,255,0.2)' : 'rgba(0,0,0,0.05)' })
          .alignItems(HorizontalAlign.Start)
        }.layoutWeight(5).height('100%')

        // ================= 右侧：大模型建议与社区 =================
        Column({ space: 20 }) {
          Column() {
            Row() {
              Text('✨ AI 健康管家分析').fontSize(16).fontWeight(FontWeight.Bold).fontColor(this.isNightMode ? '#00E5FF' : '#007799')
              Blank()
              Button(this.isAiLoading ? '请求中...' : '重新生成').fontSize(10).height(24)
                .backgroundColor(this.isNightMode ? 'rgba(0, 229, 255, 0.1)' : 'rgba(0, 119, 153, 0.1)')
                .fontColor(this.isNightMode ? '#00E5FF' : '#007799')
                .onClick(() => { if (!this.isAiLoading) this.fetchAiAdvice(); })
            }.width('100%').margin({ bottom: 16 })
            Text(this.aiAdvice).fontSize(14).fontColor(this.isNightMode ? '#E0E0E0' : '#444').lineHeight(24)
          }
          .width('100%').padding(24).backgroundColor(this.isNightMode ? 'rgba(0, 229, 255, 0.05)' : 'rgba(0, 119, 153, 0.05)')
          .borderRadius(24).border({ width: 1, color: this.isNightMode ? 'rgba(0, 229, 255, 0.3)' : 'rgba(0, 119, 153, 0.2)' })

          // 🌟🌟 改进后的社区互动区 🌟🌟
          Column() {
            Row() {
              Text('康居社区 (大家都在聊)').fontSize(16).fontWeight(FontWeight.Bold).fontColor(this.isNightMode ? '#FFF' : '#333')
              Blank()
              if(this.isCommunityLoading) Text('📡 加载中...').fontSize(12).fontColor(this.isNightMode ? '#00E5FF' : '#007799')
            }.width('100%').margin({ bottom: 16 })

            // 帖子列表区 (占据大部分空间)
            List({ space: 12 }) {
              ForEach(this.postList, (post: CommunityPostData) => {
                ListItem() { this.CommunityPostItem(post) }
              }, (post: CommunityPostData) => post.id) // 用 id 保证渲染效率
            }.width('100%').layoutWeight(1)

            // 发布互动输入区 (放置在底部)
            Row({ space: 12 }) {
              TextInput({ placeholder: '分享你的智能健康心得...', text: this.newPostContent })
                .layoutWeight(1).height(40).borderRadius(20)
                .backgroundColor(this.isNightMode ? 'rgba(128,128,128,0.1)' : 'rgba(0,0,0,0.05)')
                .fontColor(this.isNightMode ? '#FFF' : '#333')
                .onChange((val) => this.newPostContent = val)
                .onSubmit(() => this.publishMyPost())

              Button('发布').height(40).borderRadius(20)
                .backgroundColor(this.isNightMode ? '#00E5FF' : '#007799')
                .fontColor('#FFF')
                .onClick(() => this.publishMyPost())
            }.width('100%').margin({ top: 12 })

          }
          .width('100%').padding(24).layoutWeight(1)
          .backgroundColor(this.isNightMode ? 'rgba(255,255,255,0.05)' : 'rgba(255,255,255,0.85)')
          .borderRadius(24).border({ width: 1, color: this.isNightMode ? 'rgba(255,255,255,0.2)' : 'rgba(0,0,0,0.05)' })

        }.layoutWeight(5).height('100%')
      }.width('100%').layoutWeight(1)
    }.width('100%').height('100%').padding(32)
  }

  @Builder StatCard(icon: string, title: string, value: string, subDesc: string, color: string) {
    Column({ space: 8 }) {
      Row() { Text(icon).fontSize(20); Blank(); Circle({ width: 6, height: 6 }).fill(color) }.width('100%')
      Text(title).fontSize(12).fontColor(this.isNightMode ? '#A0AAB5' : '#888').alignSelf(ItemAlign.Start)
      Text(value).fontSize(28).fontWeight(FontWeight.Bold).fontColor(this.isNightMode ? '#FFF' : '#1A1A1A').alignSelf(ItemAlign.Start)
      Text(subDesc).fontSize(10).fontColor(color).alignSelf(ItemAlign.Start)
    }.layoutWeight(1).padding(16).backgroundColor(this.isNightMode ? 'rgba(128,128,128,0.05)' : 'rgba(0,0,0,0.03)')
    .borderRadius(20).border({ width: 1, color: this.isNightMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.05)' })
  }

  @Builder CommunityPostItem(post: CommunityPostData) {
    Column({ space: 6 }) {
      if (post.title) Text(post.title).fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.isNightMode ? '#FFF' : '#333')
      Text(post.content).fontSize(12).fontColor(this.isNightMode ? '#A0AAB5' : '#666').maxLines(3).textOverflow({ overflow: TextOverflow.Ellipsis })
      Row() {
        Text(post.author).fontSize(10).fontColor(this.isNightMode ? '#00E5FF' : '#007799')
        Blank()

        // 🌟 解决后的点赞按钮逻辑
        Row({ space: 4 }) {
          Text(post.isLiked ? '❤️' : '👍').fontSize(12).animation({ duration: 300, curve: Curve.EaseOut })
          Text(`${post.likes}`).fontSize(12).fontWeight(FontWeight.Bold)
            .fontColor(post.isLiked ? '#FF1744' : (this.isNightMode ? '#667788' : '#999'))
        }
        .padding({ top: 4, bottom: 4, left: 10, right: 10 })
        .backgroundColor(post.isLiked ? 'rgba(255, 23, 68, 0.1)' : (this.isNightMode ? 'rgba(255,255,255,0.05)' : 'rgba(0,0,0,0.05)'))
        .borderRadius(12)
        .onClick(() => this.toggleLike(post.id))

      }.width('100%').margin({ top: 4 })
    }
    .width('100%').padding(12).backgroundColor(this.isNightMode ? 'rgba(0,0,0,0.2)' : 'rgba(255,255,255,0.6)')
    .borderRadius(12).border({ width: 1, color: this.isNightMode ? 'rgba(255,255,255,0.05)' : 'rgba(0,0,0,0.05)' })
  }
}