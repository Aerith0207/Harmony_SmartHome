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
      const payload = this.currentDeviceAdapter.encodeCommand(command.deviceType, command.action, command.value);
      this.protocolAdapter.publish('smart_home/control', payload);
    } catch (e) {
      console.error(`[DeviceManager]指令下发阻断:${e}`);
    }
  }
}