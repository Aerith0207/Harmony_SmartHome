import { DeviceFactory, DeviceBrand } from './adapter/DeviceFactory';
import { IDeviceAdapter } from './adapter/IDeviceAdapter';
import { IProtocolAdapter } from './adapter/IProtocolAdapter';
import { MqttProtocolAdapter } from './adapter/MqttProtocolAdapter';
import { DeviceCommand } from './adapter/CommandModel';
import hilog from '@ohos.hilog';

import { HaierAdapter } from './adapter/HaierAdapter';
import { GreeAdapter } from './adapter/GreeAdapter';
import { MideaAdapter } from './adapter/MideaAdapter';

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
      // 🌟 修复1：使用 as string 将枚举转化为字符串，绕过无交集的严格类型检查
      if ((command.action as string) === 'brand') {
        let brandIndex = command.value as number;
        if (brandIndex === 1) {
          this.currentDeviceAdapter = new HaierAdapter();
        } else if (brandIndex === 2) {
          this.currentDeviceAdapter = new GreeAdapter();
        } else if (brandIndex === 3) {
          this.currentDeviceAdapter = new MideaAdapter();
        } else {
          this.currentDeviceAdapter = DeviceFactory.createAdapter(DeviceBrand.HI3861);
        }
        hilog.info(0x0000, 'ADAPTER', `[DeviceManager] 底层解耦生效，已动态热插拔至适配器索引: ${brandIndex}`);
        return;
      }

      const payload = this.currentDeviceAdapter.encodeCommand(command.deviceType, command.action, command.value);
      hilog.info(0x0000, 'ADAPTER', `[DeviceManager] 下发硬件指令报文: ${JSON.stringify(payload)}`);

      // 🌟 修复2：坚决弃用unknown，通过遍历重组一个严格符合规范的安全Record对象
      let safePayload: Record<string, string | number> = {};
      let keys = Object.keys(payload);
      for (let i = 0; i < keys.length; i++) {
        let key = keys[i];
        let val = payload[key];
        // 动态将可能存在的boolean转换为0或1，确保绝对类型安全
        safePayload[key] = typeof val === 'boolean' ? (val ? 1 : 0) : val;
      }

      this.protocolAdapter.publish('smart_home/control', safePayload);
    } catch (e) {
      hilog.error(0x0000, 'ADAPTER', `[DeviceManager] 指令下发阻断:${e}`);
    }
  }
}