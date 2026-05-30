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
        url: 'tcp://broker.emqx.io:1883', // 全球公共测试服
        clientId: `hmos_sh_node_${Date.now()}`,
        persistenceType: 1
      });

      this.client.connect({
        userName: '', // 骗过 ArkTS 类型检查
        password: '',
        keepAliveInterval: 60,
        cleanSession: true
      }).then(() => {
        this.isConnected = true;
        hilog.info(0x0000, 'MQTT_BUS', '✅ 智能家居控制总线连接成功');
        this.subscribeTopics();
        onConnectedSuccess();
      }).catch((err: Error) => {
        hilog.error(0x0000, 'MQTT_BUS', `❌ 连接建立失败: ${err.message}`);
      });

      this.client.messageArrived((_err: Error, msg) => {
        // 🌟 注入雷达 1：只要底层收到任何报文，第一时间拦截并打印！
        hilog.info(0x0000, 'MQTT_BUS', `📡 物理层收到报文 -> Topic: ${msg?.topic}, Payload: ${msg?.payload}`);

        if (msg && msg.topic === 'smart_home/status') {
          this.handleIncomingData(msg.payload);
        }
      });
    } catch (e) {
      hilog.error(0x0000, 'MQTT_BUS', '初始化异常');
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
        model.temperature = parsed.temp !== undefined ? parsed.temp : 24.5;
        model.humidity = parsed.humi !== undefined ? parsed.humi : 50.0;
        model.light = parsed.light !== undefined ? parsed.light : 400;

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