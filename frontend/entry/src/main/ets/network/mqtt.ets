// frontend/entry/src/main/ets/network/mqtt.ets
import { MqttAsync, MqttClient, MqttPublishOptions, MqttSubscribeOptions } from '@ohos/mqtt';
import { SensorDataModel } from '../models/DeviceModels';
import hilog from '@ohos.hilog';
import { CryptoUtil } from '../core/utils/CryptoUtil';

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
    if (!this.client || !this.isConnected) {
      hilog.warn(0x0000, 'MQTT_BUS', '网道未就绪，控制拦截');
      return;
    }

    let plainTextJson: string = JSON.stringify(payload);

    CryptoUtil.encrypt(plainTextJson).then((cipherBytes: Uint8Array) => {
      hilog.info(0x0000, 'MQTT_BUS', `🔒 指令已加密，准备发送二进制流，长度: ${cipherBytes.length} bytes`);

      // 🌟 纯血 ArkTS 破局法：将字节流逐个转为单字节字符拼成字符串
      let binaryString: string = "";
      for (let i = 0; i < cipherBytes.length; i++) {
        binaryString += String.fromCharCode(cipherBytes[i]);
      }

      const pubOpts: MqttPublishOptions = {
        topic: 'smart_home/control',
        payload: binaryString, // 堂堂正正传入 string，保留真实的二进制数据
        qos: 1
      };

      this.client?.publish(pubOpts).catch((err: Error) => {
        hilog.error(0x0000, 'MQTT_BUS', `下发失败: ${err.message}`);
      });
    }).catch((err: Error) => {
      hilog.error(0x0000, 'MQTT_BUS', `❌ 指令加密异常，已拦截发送: ${err.message}`);
    });
  }

  // 🔓 收到上报数据时：将原始二进制流送入 AES-128-GCM 引擎验证解密
  private async handleIncomingData(rawPayload: ArrayBuffer | string): Promise<void> {
    try {
      hilog.info(0x0000, 'MQTT_BUS', `⚙️ 收到加密流，正在送入 AES-128-GCM 引擎解密...`);

      let cipherBytes: Uint8Array;

      // 鲁棒性兼容转换：将网络层载荷统一提取为规范的 Uint8Array 字节流
      if (rawPayload instanceof ArrayBuffer) {
        cipherBytes = new Uint8Array(rawPayload);
      } else if (typeof rawPayload === 'string') {
        cipherBytes = new Uint8Array(rawPayload.length);
        for (let i = 0; i < rawPayload.length; i++) {
          cipherBytes[i] = rawPayload.charCodeAt(i);
        }
      } else {
        hilog.error(0x0000, 'MQTT_BUS', '❌ 收到未知类型的数据载荷');
        return;
      }

      let decryptedText: string = await CryptoUtil.decrypt(cipherBytes);

      if (!decryptedText) {
        hilog.error(0x0000, 'MQTT_BUS', '❌ 解密失败或防篡改校验未通过，已丢弃该报文！');
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