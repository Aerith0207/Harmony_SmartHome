import { IDeviceAdapter } from './IDeviceAdapter';
import { DeviceType, DeviceAction } from './DeviceConstants';

export class Hi3861Adapter implements IDeviceAdapter {
  getDeviceBrand(): string {
    return 'Hi3861_Standard_Board';
  }

  encodeCommand(deviceType: string, action: string, value: number | string | boolean): Record<string, string | number> {
    if (deviceType === DeviceType.LIGHT && action === DeviceAction.POWER) {
      return { "cmd": value ? "light_on" : "light_off", "value": 0 };
    }
    if (deviceType === DeviceType.DOOR && action === DeviceAction.LOCK) {
      return { "cmd": value ? "door_close" : "door_open", "value": 0 };
    }
    if (deviceType === DeviceType.AC && action === DeviceAction.POWER) {
      return { "cmd": value ? "ac_on" : "ac_off", "value": 0 };
    }
    if (deviceType === DeviceType.AC && action === DeviceAction.TEMPERATURE) {
      return { "cmd": "ac_set", "value": value as number };
    }
    if (deviceType === DeviceType.AC && action === DeviceAction.MODE) {
      return { "cmd": "ac_mode", "value": value as number };
    }
    if (deviceType === DeviceType.AC && action === DeviceAction.AUTO) {
      return { "cmd": value ? "auto_ac_on" : "auto_ac_off", "value": 0 };
    }
    throw new Error(`[Adapter Error]不支持的Hi3861指令组合:Type=${deviceType},Action=${action}`);
  }
}