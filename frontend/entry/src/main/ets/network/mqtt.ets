// frontend/entry/src/main/ets/network/mqtt.ets
import { MqttAsync, MqttClient, MqttPublishOptions, MqttSubscribeOptions } from '@ohos/mqtt';
import { SensorDataModel } from '../models/DeviceModels';
import hilog from '@ohos.hilog';
import { CryptoUtil } from '../core/utils/CryptoUtil';

export class MqttBusService {
  private static instance: MqttBusService | null = null;
  public client: MqttClient | null = null;
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
        url: 'ssl://broker-cn.emqx.io:8883',
        clientId: `hmos_sh_node_${Date.now()}`,
        persistenceType: 1
      });

      this.client.connect({
        userName: '',
        password: '',
        keepAliveInterval: 60,
        cleanSession: true,
        sslOptions: {
          enableServerCertAuth: false
        }
      }).then(() => {
        this.isConnected = true;
        hilog.info(0x0000, 'MQTT_BUS', '✅ MQTT连接成功 [Broker:8883]');
        this.subscribeTopics();

        this.client?.publish({
          topic: 'test/tls',
          payload: 'tls_handshake_probe',
          qos: 0
        });

        onConnectedSuccess();
      }).catch((err: Error) => {
        hilog.error(0x0000, 'MQTT_BUS', `❌ MQTT Connect Error: ${JSON.stringify(err)} | msg: ${err.message}`);
      });

      this.client.messageArrived((_err: Error, msg) => {
        hilog.info(0x0000, 'MQTT_BUS', `📡 物理层收到报文 -> Topic: ${msg?.topic}`);
        if (msg && msg.topic === 'smart_home/status') {
          // 自动推断二进制流类型并传入解密器
          this.handleIncomingData(msg.payload);
        }
      });
    } catch (e) {
      let err = e as Error;
      hilog.error(0x0000, 'MQTT_BUS', `初始化异常: ${err.message}`);
    }
  }

  private subscribeTopics(): void {
    if (!this.client) return;
    const subOpts: MqttSubscribeOptions = { topic: 'smart_home/status', qos: 1 };
    this.client.subscribe(subOpts).catch(() => {});
  }

  public registerSensorListener(callback: (data: SensorDataModel) => void): void {
    this.sensorCallback = callback;
  }

  // 🔒 下发指令时：AES-128-GCM 加密，封装为二进制字符串绕过 ArkTS 检查
  public publishCommand(payload: Record<string, string | number>): void {
    if (!this.client || !this.isConnected) return;
    let plainTextJson: string = JSON.stringify(payload);

    CryptoUtil.encrypt(plainTextJson).then((cipherBytes: Uint8Array) => {
      // 转 Hex 字符串
      let hexString = "";
      for (let i = 0; i < cipherBytes.length; i++) {
        let hex = cipherBytes[i].toString(16).toUpperCase();
        hexString += (hex.length === 1 ? "0" + hex : hex);
      }

      hilog.info(0x0000, 'MQTT_BUS', `🔒 指令已加密为Hex文本下发: ${hexString}`);

      const pubOpts: MqttPublishOptions = {
        topic: 'smart_home/control',
        payload: hexString, // 堂堂正正发送标准的纯净字符串
        qos: 1
      };
      this.client?.publish(pubOpts).catch((err: Error) => {});
    }).catch((err: Error) => {});
  }

  // 🔓 接收数据（Hex字符串 -> 还原二进制 -> 解密）
  private async handleIncomingData(rawPayload: ArrayBuffer | string): Promise<void> {
    try {
      hilog.info(0x0000, 'MQTT_BUS', `⚙️ 收到加密流，正在转换并解密...`);
      let cipherBytes: Uint8Array;

      // 解析绝对安全的 Hex 字符串
      if (typeof rawPayload === 'string') {
        let hexStr = rawPayload.trim();
        cipherBytes = new Uint8Array(hexStr.length / 2);
        for (let i = 0; i < hexStr.length; i += 2) {
          cipherBytes[i / 2] = parseInt(hexStr.substring(i, i + 2), 16);
        }
      } else {
        return; // 防御性拦截
      }

      // 送入 AES 引擎解密
      let decryptedText: string = await CryptoUtil.decrypt(cipherBytes);
      if (!decryptedText) {
        hilog.error(0x0000, 'MQTT_BUS', '❌ 解密失败或校验未通过！');
        return;
      }

      const parsed: Record<string, number> = JSON.parse(decryptedText) as Record<string, number>;

      if (parsed) {
        hilog.info(0x0000, 'MQTT_BUS', `✅ 密文解开！明文数据: 温度=${parsed['temp']}, 湿度=${parsed['humi']}`);

        const model = new SensorDataModel();

        model.temperature = parsed['temp'] !== undefined ? parsed['temp'] : 24.5;
        model.humidity = parsed['humi'] !== undefined ? parsed['humi'] : 50.0;
        model.light = parsed['light'] !== undefined ? parsed['light'] : 400;

        model.lightStatus = parsed['light_sw'] === 1;
        model.doorOpen = parsed['door'] === 1;
        model.acStatus = parsed['ac_sw'] === 1;
        model.acTemp = parsed['ac_temp'] !== undefined ? parsed['ac_temp'] : 26;
        model.acMode = parsed['ac_mode'] !== undefined ? parsed['ac_mode'] : 0;
        model.autoLight = parsed['auto_light'] === 1;
        model.autoAc = parsed['auto_ac'] === 1;

        if (this.sensorCallback) {
          this.sensorCallback(model);
        } else {
          hilog.warn(0x0000, 'MQTT_BUS', '⚠️ 警告：UI 层的 sensorCallback 未注册，数据被丢弃！');
        }
      }
    } catch (err) {
      let e = err as Error;
      hilog.error(0x0000, 'MQTT_BUS', `❌ 解密后 JSON 解析异常: ${e.message}`);
    }
  }
}