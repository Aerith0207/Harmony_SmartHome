// frontend/entry/src/main/ets/features/ai/AiDecisionEngine.ets
import http from '@ohos.net.http';
import hilog from '@ohos.hilog';

export class AiCommand {
  device: string = '';
  action: string = '';
  value: string | number | boolean = '';
}

export class AiStrategyResult {
  type: string = 'NONE';
  message: string = '';
  commands: AiCommand[] = [];
}

class PromptMessage {
  role: string = '';
  content: string = '';
}

class AiRequestBody {
  model: string = '';
  messages: PromptMessage[] = [];
  temperature: number = 0;
  stream: boolean = false;
}

export class AiDecisionEngine {
  private static readonly API_URL: string = 'https://api.deepseek.com/chat/completions';
  private static readonly AI_ALLOWED_DEVICES: string[] = ['ac', 'light'];

  // 🌟 核心修改 1：改变入参，引入 acTargetTemp (空调设定温度) 作为微调基准
  static async requestStrategy(userIntent: string, currentRoomTemp: number, acTargetTemp: number): Promise<AiStrategyResult> {
    let finalResult = new AiStrategyResult();

    // 🌟 核心修改 2：全面重构系统级 Prompt，卡死安全底线与计算基准
    let systemPrompt = `【最高优先级规则】
首先判断用户的输入是否属于智能家居控制请求。你只负责解析室内环境与照明相关话题，绝对不要猜测用户意图，不要盲目控制设备！所有涉及控制的策略，必须等待用户人工确认授权后才会执行。
你必须返回一个严格的 JSON 对象，包含 type, message, commands 三个字段。

【输出 JSON 格式定义】
{
  "type": "CONTROL" 或 "ADVICE" 或 "NONE",
  "message": "用自然语言回复给用户的话",
  "commands": [
    {"device": "设备名", "action": "动作名", "value": 数值或布尔值}
  ]
}

【Type 判定核心准则】
1. CONTROL：明确的环境设备控制指令，需要生成授权策略。
2. ADVICE：与家居环境相关，但不需要立刻控制设备。
3. NONE：闲聊、无关指令或涉及安全底线的指令。

【🌡️ 智能微调原则 (严禁越权)】
- 若表达模糊感受（如"太热/太冷"）：必须在【空调当前设定的温度（${acTargetTemp}℃）】基础上加减 2~3℃，切勿使用环境温度（${currentRoomTemp}℃）作为基准。

【设备能力字典】（非常重要：严格遵守 action 和 value 的定义）
1. 空调 (device: "ac")：
   - 开关 -> action: "power", value: true 或 false
   - 温度 -> action: "temp", value: 16~30的整数
   - 模式 -> action: "mode", value: 0(自动), 1(制冷), 2(除湿), 3(送风), 4(制热)
   - 风速 -> action: "fan", value: 0(自动), 1(低风), 2(中风), 3(高风)
2. 主灯 (device: "light")：
   - 开关 -> action: "power", value: true 或 false

【场景示例】
用户："有点冷，风也太大了"
返回：{"type":"CONTROL", "message":"已为您生成策略：上调温度并降低风速，请确认授权。", "commands":[{"device":"ac","action":"temp","value":${acTargetTemp + 2}}, {"device":"ac","action":"fan","value":1}]}
用户："讲个笑话" 或 "打开大门"
返回：{"type":"NONE", "message":"抱歉，我仅负责提供环境气候与灯光控制策略，无法处理此类操作。", "commands":[]}`;

    let httpRequest = http.createHttp();

    let msgSystem = new PromptMessage();
    msgSystem.role = "system"; msgSystem.content = systemPrompt;

    let msgUser = new PromptMessage();
    msgUser.role = "user"; msgUser.content = userIntent;

    let requestBody = new AiRequestBody();
    requestBody.model = "deepseek-chat";
    requestBody.messages = [msgSystem, msgUser];
    requestBody.temperature = 0.1;

    try {
      let realApiKey = "";
      let startTime = Date.now();
      hilog.info(0x0000, 'AI_TEST', '🚀 开始向DeepSeek推送带有环境上下文的Prompt...');

      let response = await httpRequest.request(AiDecisionEngine.API_URL, {
        method: http.RequestMethod.POST,
        header: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + realApiKey },
        extraData: JSON.stringify(requestBody)
      });

      if (response.responseCode === 200) {
        let resultObj = JSON.parse(response.result as string) as Record<string, Object>;
        let choices = resultObj['choices'] as Array<Record<string, Object>>;
        let message = choices[0]['message'] as Record<string, string>;
        let contentStr = message['content'].trim();

        let rawAiResponse = JSON.parse(contentStr) as Record<string, Object>;
        finalResult.type = (rawAiResponse['type'] as string) || 'NONE';
        finalResult.message = (rawAiResponse['message'] as string) || '未识别的指令';

        if (finalResult.type === 'CONTROL' && Array.isArray(rawAiResponse['commands'])) {
          finalResult.commands = AiDecisionEngine.validateStrategy(rawAiResponse['commands']);
        }

        let endTime = Date.now();
        let costTime = endTime - startTime;
        hilog.info(0x0000, 'AI_TEST', `✅ JSON策略解析完成！链路总耗时: ${costTime} ms`);
      }
    } catch (err) {
      finalResult.message = "AI引擎网络异常";
    } finally {
      httpRequest.destroy();
    }
    return finalResult;
  }

  private static validateStrategy(rawList: Array<Record<string, Object>>): AiCommand[] {
    let validList: AiCommand[] = [];
    for (let i = 0; i < rawList.length; i++) {
      let item = rawList[i];
      let deviceStr = item['device'] as string;
      let actionStr = item['action'] as string;
      let val = item['value'] as string | number | boolean;
      if (deviceStr && actionStr && val !== undefined && AiDecisionEngine.AI_ALLOWED_DEVICES.includes(deviceStr)) {
        let cmd = new AiCommand();
        cmd.device = deviceStr; cmd.action = actionStr; cmd.value = val;
        validList.push(cmd);
      }
    }
    return validList;
  }
}