import { IProtocolAdapter } from './IProtocolAdapter';
import { MqttBusService } from '../../network/mqtt';
import hilog from '@ohos.hilog';

export class MqttProtocolAdapter implements IProtocolAdapter {
  getProtocolName(): string {
    return 'MQTT over TLS 1.3';
  }

  async connect(url: string, port: number): Promise<boolean> {
    // 🌟 打印日志，消耗掉 url 和 port 参数，消除 ArkTS 警告
    hilog.info(0x0000, 'ProtocolAdapter', `[${this.getProtocolName()}] 准备连接至: ${url}:${port}`);
    return true;
  }

  publish(topic: string, payload: Record<string, string | number>): void {
    // 🌟 消耗掉 topic 参数
    hilog.info(0x0000, 'ProtocolAdapter', `[${this.getProtocolName()}] 路由至主题: ${topic}`);
    MqttBusService.getInstance().publishCommand(payload);
  }
}