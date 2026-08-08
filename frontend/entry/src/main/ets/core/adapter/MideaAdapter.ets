import hilog from '@ohos.hilog';
import { IDeviceAdapter } from './IDeviceAdapter';

export class MideaAdapter implements IDeviceAdapter {
  getDeviceBrand(): string {
    return "Midea";
  }

  encodeCommand(deviceType: string, action: string, value: number | string | boolean): Record<string, string | number> {
    hilog.info(0x0000, 'ADAPTER', `[MIDEA] 动态组装美的空调专属红外数据帧: 动作=${action}, 值=${value}`);

    // 核心修复点：将boolean强制转换为number，满足ArkTS的类型约束
    let safeValue: string | number = typeof value === 'boolean' ? (value ? 1 : 0) : value;

    return {
      "device": deviceType,
      "action": action,
      "value": safeValue,
      "protocol": "midea_ir_v2",
      "vendorCode": "0x4D"
    };
  }
}