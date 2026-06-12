import { IDeviceAdapter } from './IDeviceAdapter';
import { DeviceType, DeviceAction } from './DeviceConstants';

export class Hi3861Adapter implements IDeviceAdapter {
  getDeviceBrand(): string {
    return 'Hi3861_Standard_Board';
  }

  encodeCommand(deviceType: string, action: string, value: number | string | boolean): Record<string, string | number> {
    // 1.客厅主灯开关
    if (deviceType === DeviceType.LIGHT && action === DeviceAction.POWER) {
      return { "cmd": value ? "light_on" : "light_off", "value": 0 };
    }
    // 2.新增：客厅主灯自动模式
    if (deviceType === DeviceType.LIGHT && action === DeviceAction.AUTO) {
      return { "cmd": value ? "auto_light_on" : "auto_light_off", "value": 0 };
    }
    // 3.智能门锁
    if (deviceType === DeviceType.DOOR && action === DeviceAction.LOCK) {
      return { "cmd": value ? "door_close" : "door_open", "value": 0 };
    }
    // 4.空调开关
    if (deviceType === DeviceType.AC && action === DeviceAction.POWER) {
      return { "cmd": value ? "ac_on" : "ac_off", "value": 0 };
    }
    // 5.空调温度调节
    if (deviceType === DeviceType.AC && action === DeviceAction.TEMPERATURE) {
      return { "cmd": "ac_set", "value": value as number };
    }
    // 6.自动空调模式 (注：已按硬件协议彻底移除ac_mode分支)
    if (deviceType === DeviceType.AC && action === DeviceAction.AUTO) {
      return { "cmd": value ? "auto_ac_on" : "auto_ac_off", "value": 0 };
    }
    // 7.空调品牌设置(0=通用,1=海尔,2=格力,3=美的)
    if (deviceType === DeviceType.AC && action === 'brand') {
      return { "cmd": "ac_brand_set", "value": value as number };
    }

    // 兜底防御：任何未经硬件确认的指令组合直接阻断
    throw new Error(`[Adapter Error]不支持的Hi3861指令组合:Type=${deviceType},Action=${action}`);
  }
}