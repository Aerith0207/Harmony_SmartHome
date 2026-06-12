import { DeviceFactory, DeviceBrand } from './adapter/DeviceFactory';
import { IDeviceAdapter } from './adapter/IDeviceAdapter';
import { IProtocolAdapter } from './adapter/IProtocolAdapter';
import { MqttProtocolAdapter } from './adapter/MqttProtocolAdapter';
import { DeviceCommand } from './adapter/CommandModel';

export class DeviceManager {
  private static instance: DeviceManager;
  private currentDeviceAdapter: IDeviceAdapter;
  private protocolAdapter: IProtocolAdapter;

  private constructor() {
    this.currentDeviceAdapter = DeviceFactory.createAdapter(DeviceBrand.HI3861);
    this.protocolAdapter = new MqttProtocolAdapter();
  }

  public static getInstance(): DeviceManager {
    if (!DeviceManager.instance) {
      DeviceManager.instance = new DeviceManager();
    }
    return DeviceManager.instance;
  }

  public sendCommand(command: DeviceCommand): void {
    try {
      // 这里的encodeCommand会自动调用Hi3861DeviceAdapter里的翻译逻辑
      const payload = this.currentDeviceAdapter.encodeCommand(command.deviceType, command.action, command.value);

      // 增加日志打印让控制流转过程更加清晰
      console.info(`[DeviceManager]下发硬件指令报文:${payload}`);

      this.protocolAdapter.publish('smart_home/control', payload);
    } catch (e) {
      console.error(`[DeviceManager]指令下发阻断:${e}`);
    }
  }
}