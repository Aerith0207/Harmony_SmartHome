// frontend/entry/src/main/ets/features/ai/AiDecisionEngine.ets
import http from '@ohos.net.http';

// 1. 严格定义数据模型，消灭 any 和匿名对象
export class AiCommand {
  device: string = '';
  action: string = '';
  value: string | number | boolean = '';
}

class CacheItem {
  strategy: AiCommand[] = [];
  timestamp: number = 0;
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
  // 2. 避免在 static 方法中使用 this，改用显式的类名引用
  private static readonly API_URL: string = 'https://api.deepseek.com/chat/completions';
  private static readonly AI_ALLOWED_DEVICES: string[] = ['ac', 'light'];
  private static strategyCache: Map<string, CacheItem> = new Map();
  private static readonly CACHE_TTL_MS: number = 5 * 60 * 1000;

  static async requestStrategy(userIntent: string, currentTemp: number, currentHumid: number): Promise<AiCommand[]> {
    let cacheKey = userIntent + "_" + currentTemp.toString() + "_" + currentHumid.toString();
    let cachedResult = AiDecisionEngine.strategyCache.get(cacheKey);

    if (cachedResult !== undefined && (Date.now() - cachedResult.timestamp < AiDecisionEngine.CACHE_TTL_MS)) {
      console.info("[AiDecision] 命中本地策略缓存");
      return cachedResult.strategy;
    }

    let availableDevices = AiDecisionEngine.AI_ALLOWED_DEVICES.join(', ');
    let systemPrompt = `你是一个智能家居中央决策大脑。
请根据用户的意图和当前环境数据（温度${currentTemp}℃，湿度${currentHumid}%），生成设备控制策略。

【输出格式】
必须且只能输出合法的JSON数组，禁止包含Markdown标记。

【设备能力字典（极度严格约束）】
你生成的 JSON 中，device 和 action 字段必须严格使用以下枚举，绝不允许编造其他词：

1. 空调
   - device: "ac"
   - 支持的action:
     * "power" (值: true开 / false关)
     * "temperature" (值: 16到30的整数)
     * "auto" (值: true进入自动模式 / false退出自动模式)

2. 客厅主灯
   - device: "light"
   - 支持的action:
     * "power" (值: true开灯 / false关灯)
     * "auto" (值: true进入自动模式 / false退出自动模式)

【示例】
用户说：“有点冷，开空调制热”，你必须返回：
[{"device":"ac","action":"power","value":true}, {"device":"ac","action":"temperature","value":30}]`;

    let httpRequest = http.createHttp();

    // 3. 使用严格类实例化替代匿名对象字面量
    let msgSystem: PromptMessage = new PromptMessage();
    msgSystem.role = "system";
    msgSystem.content = systemPrompt;

    let msgUser: PromptMessage = new PromptMessage();
    msgUser.role = "user";
    msgUser.content = userIntent;

    let requestBody: AiRequestBody = new AiRequestBody();
    requestBody.model = "deepseek-chat";
    requestBody.messages = [msgSystem, msgUser];
    requestBody.temperature = 0.1;
    requestBody.stream = false;

    try {
      // 请务必替换为您的真实 Key
      let realApiKey = "sk-904070bc70904c6f86ec1f5c57ac8930";

      let response = await httpRequest.request(AiDecisionEngine.API_URL, {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ' + realApiKey
        },
        extraData: JSON.stringify(requestBody)
      });

      if (response.responseCode === 200) {
        // 4. ArkTS 强制要求 JSON 解析后进行显式类型转换
        let resultObj = JSON.parse(response.result as string) as Record<string, Object>;
        let choices = resultObj['choices'] as Array<Record<string, Object>>;
        let message = choices[0]['message'] as Record<string, string>;
        let contentStr = message['content'].trim();

        let rawStrategy = JSON.parse(contentStr) as Array<Record<string, Object>>;
        let validStrategy = AiDecisionEngine.validateStrategy(rawStrategy);

        if (validStrategy.length > 0) {
          let newCache = new CacheItem();
          newCache.strategy = validStrategy;
          newCache.timestamp = Date.now();
          AiDecisionEngine.strategyCache.set(cacheKey, newCache);
        }
        return validStrategy;
      }
    } catch (err) {
      console.error("[AiDecision] 请求异常：" + JSON.stringify(err));
    } finally {
      httpRequest.destroy();
    }
    return [];
  }

  // 严格 Schema 校验
  private static validateStrategy(rawList: Array<Record<string, Object>>): AiCommand[] {
    let validList: AiCommand[] = [];
    if (!Array.isArray(rawList)) { return validList; }

    for (let i = 0; i < rawList.length; i++) {
      let item = rawList[i];
      let deviceStr = item['device'] as string;
      let actionStr = item['action'] as string;
      let val = item['value'] as string | number | boolean;

      if (!deviceStr || !actionStr || val === undefined) {
        console.warn("[AiDecision] 拦截：指令结构不完整");
        continue;
      }
      if (!AiDecisionEngine.AI_ALLOWED_DEVICES.includes(deviceStr)) {
        console.warn("[AiDecision] 拦截：越权访问设备 " + deviceStr);
        continue;
      }

      let cmd = new AiCommand();
      cmd.device = deviceStr;
      cmd.action = actionStr;
      cmd.value = val;
      validList.push(cmd);
    }
    return validList;
  }
}