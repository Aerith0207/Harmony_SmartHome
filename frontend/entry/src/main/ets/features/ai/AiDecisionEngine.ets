// frontend/entry/src/main/ets/features/ai/AiDecisionEngine.ets
import http from '@ohos.net.http';

// 1. 扩充 AI 命令类
export class AiCommand {
  device: string = '';
  action: string = '';
  value: string | number | boolean = '';
}

// 🌟 2. 新增：高级 AI 响应结果类 (完美落实您的三态设计)
export class AiStrategyResult {
  type: string = 'NONE'; // 可选值: 'CONTROL', 'ADVICE', 'NONE'
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

  static async requestStrategy(userIntent: string, currentTemp: number, currentHumid: number): Promise<AiStrategyResult> {
    let finalResult = new AiStrategyResult();

    // 🌟 完美融合您的“两阶段思维”与“安全限制”的顶级 Prompt
    let systemPrompt = `【最高优先级规则】
首先判断用户的输入是否属于智能家居控制请求。绝对不要猜测用户意图，不要盲目控制设备！
你必须返回一个严格的 JSON 对象，包含 type, message, commands 三个字段。

【输出 JSON 格式定义】
{
  "type": "CONTROL" 或 "ADVICE" 或 "NONE",
  "message": "用自然语言回复给用户的话",
  "commands": [ 具体的控制指令，若无则为空数组 [] ]
}

【Type 判定核心准则】
1. CONTROL：明确的设备控制指令（如"开灯"、"太热了"）。
2. ADVICE：与家居环境相关，但不需要立刻控制设备（如"今天适合开空调吗"）。
3. NONE：闲聊、无关指令或涉及安全底线的指令（如"讲个笑话"、"打开门锁"）。

【🌡️ 温度智能微调原则】
- 若明确指定温度：直接设置。
- 若表达模糊感受（如"太热/太冷"）：必须在当前温度（${currentTemp}℃）基础上加减 2~3℃！绝对禁止直接输出 16℃ 或 30℃ 等极端值！

【设备能力字典】（仅限以下设备，严禁控制门锁等安防设备）
1. 空调 (device: "ac") -> action: "power" (true/false), "temperature" (整数)
2. 主灯 (device: "light") -> action: "power" (true/false)

【场景示例】
用户："有点冷"
返回：{"type":"CONTROL", "message":"当前${currentTemp}℃，已为您将空调上调两度。", "commands":[{"device":"ac","action":"power","value":true},{"device":"ac","action":"temperature","value":${currentTemp + 2}}]}

用户："讲个笑话" 或 "打开大门"
返回：{"type":"NONE", "message":"抱歉，我仅负责处理室内环境与照明控制，无法执行此操作。", "commands":[]}`;

    let httpRequest = http.createHttp();

    let msgSystem = new PromptMessage();
    msgSystem.role = "system"; msgSystem.content = systemPrompt;

    let msgUser = new PromptMessage();
    msgUser.role = "user"; msgUser.content = userIntent;

    let requestBody = new AiRequestBody();
    requestBody.model = "deepseek-chat";
    requestBody.messages = [msgSystem, msgUser];
    requestBody.temperature = 0.1; // 极低温度，保证 JSON 输出稳定

    try {
      let realApiKey = "";

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

        // 🌟 解析新的复合 JSON 结构
        let rawAiResponse = JSON.parse(contentStr) as Record<string, Object>;
        finalResult.type = (rawAiResponse['type'] as string) || 'NONE';
        finalResult.message = (rawAiResponse['message'] as string) || '未识别的指令';

        if (finalResult.type === 'CONTROL' && Array.isArray(rawAiResponse['commands'])) {
          finalResult.commands = AiDecisionEngine.validateStrategy(rawAiResponse['commands']);
        }
      }
    } catch (err) {
      finalResult.message = "AI 引擎网络异常";
    } finally {
      httpRequest.destroy();
    }
    return finalResult;
  }

  // 严格 Schema 校验保持不变
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