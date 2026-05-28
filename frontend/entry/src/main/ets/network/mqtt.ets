// frontend/entry/src/main/ets/network/mqtt.ets
import { MqttAsync, MqttClient, MqttPublishOptions, MqttSubscribeOptions } from '@ohos/mqtt';
import { SmartPayload, SensorDataModel } from '../models/DeviceModels';
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

    //
    try {
      //   this.client = MqttAsync.createMqtt({
      //     url: 'tcp://115.175.12.81:1883',
      //     clientId: `hmos_sh_node_${Date.now()}`,
      //     persistenceType: 1
      //   });
      this.client = MqttAsync.createMqtt({
        // 🌟 1. 换成全球免费公共测试代理节点
        url: 'tcp://broker.emqx.io:1883',
        clientId: `hmos_sh_node_${Date.now()}`,
        persistenceType: 1
      });

      this.client.connect({
        // 🌟 恢复这两个字段，传入空字符串（或随便填任意字符），专门用来“骗”过 ArkTS 的类型检查
        userName: '',
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
        if (msg && msg.topic === 'agri/device/hi3861_001/result') {
          this.handleIncomingData(msg.payload);
        }
      });
    } catch (e) {
      hilog.error(0x0000, 'MQTT_BUS', '初始化异常');
    }
  }

  private subscribeTopics(): void {
    if (!this.client) return;
    const subOpts: MqttSubscribeOptions = { topic: 'agri/device/hi3861_001/result', qos: 1 };
    this.client.subscribe(subOpts).catch(() => {});
  }

  public registerSensorListener(callback: (data: SensorDataModel) => void): void {
    this.sensorCallback = callback;
  }

  public publishCommand(payload: SmartPayload): void {
    if (!this.client || !this.isConnected) {
      hilog.warn(0x0000, 'MQTT_BUS', '网道未就绪，控制拦截');
      return;
    }
    const pubOpts: MqttPublishOptions = {
      topic: 'agri/device/hi3861_001/control',
      payload: JSON.stringify(payload),
      qos: 1
    };
    this.client.publish(pubOpts).catch((err: Error) => {
      hilog.error(0x0000, 'MQTT_BUS', `下发失败: ${err.message}`);
    });
  }

  private handleIncomingData(rawPayload: string): void {
    try {
      const parsed = JSON.parse(rawPayload) as Record<string, Record<string, number | string>>;
      if (parsed && parsed.data) {
        const model = new SensorDataModel();
        model.temperature = (parsed.data.temp as number) ?? 24.5;
        model.humidity = (parsed.data.hum as number) ?? 50.0;
        model.light = (parsed.data.light as number) ?? 400;
        model.co2 = (parsed.data.co2 as number) ?? 600;
        model.reportTime = (parsed.data.report_time as string) ?? '';
        if (this.sensorCallback) this.sensorCallback(model);
      }
    } catch (e) {
      hilog.error(0x0000, 'MQTT_BUS', '流解析异常');
    }
  }
}