// frontend/entry/src/main/ets/network/mqtt.ets
import { MqttAsync, MqttClient, MqttPublishOptions, MqttSubscribeOptions } from '@ohos/mqtt';
import { SensorDataModel } from '../models/DeviceModels';
import hilog from '@ohos.hilog';

export class MqttBusService {
  private static instance: MqttBusService | null = null;
  private client: MqttClient | null = null;
  private isConnected: boolean = false;
  private sensorCallback: ((data: SensorDataModel) => void) | null = null;

  private constructor() {}

  public static getInstance(): MqttBusService {
    if (!MqttBusService.instance) {
      MqttBusService.instance = new MqttBusService();
    }
    return MqttBusService.instance;
  }

  public init(onConnectedSuccess: () => void): void {
    if (this.isConnected) return;

    try {
      this.client = MqttAsync.createMqtt({
        // 🌟 实验性探针：指向 TLS 端口
        url: 'ssl://broker.emqx.io:8883',
        clientId: `hmos_sh_node_${Date.now()}`,
        persistenceType: 1
      });

      this.client.connect({
        userName: '',
        password: '',
        keepAliveInterval: 60,
        cleanSession: true,
        sslOptions: {
          enableServerCertAuth: false  // 盲测绝招：先关闭 CA 证书强校验，只验证加密隧道能否打通
        }
      }).then(() => {
        this.isConnected = true;
        // 🌟 修正 1：严谨的日志描述，不提前宣告胜利
        hilog.info(0x0000, 'MQTT_BUS', '✅ MQTT连接成功 [Broker:8883]');
        this.subscribeTopics();

        // 🌟 验证步骤 2：连接成功后，主动向测试通道发一条探测报文
        this.client?.publish({
          topic: 'test/tls',
          payload: 'tls_handshake_probe',
          qos: 0
        });

        onConnectedSuccess();
      }).catch((err: Error) => {
        // 🌟 修正 2：完整暴露底层的握手崩溃细节，方便精准排雷
        hilog.error(0x0000, 'MQTT_BUS', `❌ MQTT Connect Error: ${JSON.stringify(err)} | msg: ${err.message}`);
      });

      this.client.messageArrived((_err: Error, msg) => {
        hilog.info(0x0000, 'MQTT_BUS', `📡 物理层收到报文 -> Topic: ${msg?.topic}, Payload: ${msg?.payload}`);
        if (msg && msg.topic === 'smart_home/status') {
          this.handleIncomingData(msg.payload);
        }
      });
    } catch (e) {
      hilog.error(0x0000, 'MQTT_BUS', `初始化异常: ${JSON.stringify(e)}`);
    }
  }

  private subscribeTopics(): void {
    if (!this.client) return;
    // 🌟 对齐硬件的上报主题
    const subOpts: MqttSubscribeOptions = { topic: 'smart_home/status', qos: 1 };
    this.client.subscribe(subOpts).catch(() => {});
  }

  public registerSensorListener(callback: (data: SensorDataModel) => void): void {
    this.sensorCallback = callback;
  }

  // 🌟 将参数类型从 SmartPayload 修改为支持通用对象的 Record
  public publishCommand(payload: Record<string, string | number>): void {
    if (!this.client || !this.isConnected) {
      hilog.warn(0x0000, 'MQTT_BUS', '网道未就绪，控制拦截');
      return;
    }
    const pubOpts: MqttPublishOptions = {
      // 🌟 对齐硬件的下发主题
      topic: 'smart_home/control',
      payload: JSON.stringify(payload),
      qos: 1
    };
    this.client.publish(pubOpts).catch((err: Error) => {
      hilog.error(0x0000, 'MQTT_BUS', `下发失败: ${err.message}`);
    });
  }

  private handleIncomingData(rawPayload: string): void {
    try {
      hilog.info(0x0000, 'MQTT_BUS', `⚙️ 开始解析 Payload...`);
      const parsed = JSON.parse(rawPayload) as Record<string, number>;

      if (parsed) {
        // 🌟 注入雷达 2：确认 JSON 解析是否完美对齐
        hilog.info(0x0000, 'MQTT_BUS', `✅ JSON解析成功: 温度=${parsed.temp}, 湿度=${parsed.humi}`);

        const model = new SensorDataModel();

        // 1. 基础环境数据提取
        model.temperature = parsed.temp !== undefined ? parsed.temp : 24.5;
        model.humidity = parsed.humi !== undefined ? parsed.humi : 50.0;
        model.light = parsed.light !== undefined ? parsed.light : 400;

        // 🌟 2. 开关与模式状态提取 (0 为 false/关，1 为 true/开)
        model.lightStatus = parsed.light_sw === 1;
        model.doorOpen = parsed.door === 1;
        model.acStatus = parsed.ac_sw === 1;
        model.acTemp = parsed.ac_temp !== undefined ? parsed.ac_temp : 26;
        model.acMode = parsed.ac_mode !== undefined ? parsed.ac_mode : 0;
        model.autoLight = parsed.auto_light === 1;
        model.autoAc = parsed.auto_ac === 1;

        if (this.sensorCallback) {
          hilog.info(0x0000, 'MQTT_BUS', '🚀 准备将物理流推送到大屏 UI 回调中...');
          this.sensorCallback(model);
        } else {
          hilog.warn(0x0000, 'MQTT_BUS', '⚠️ 警告：UI 层的 sensorCallback 未注册，数据被丢弃！');
        }
      }
    } catch (e) {
      // 🌟 注入雷达 3：捕获隐藏的格式化崩溃
      hilog.error(0x0000, 'MQTT_BUS', `❌ 流解析异常: ${e.message}`);
    }
  }
}