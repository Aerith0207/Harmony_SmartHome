import hilog from '@ohos.hilog';
import { IDeviceAdapter } from './IDeviceAdapter';

export class GreeAdapter implements IDeviceAdapter {
  getDeviceBrand(): string {
    return "Gree";
  }

  encodeCommand(deviceType: string, action: string, value: number | string | boolean): Record<string, string | number> {
    // 将布尔值安全转换为数字以通过ArkTS类型检查
    let safeValue: string | number = typeof value === 'boolean' ? (value ? 1 : 0) : value;

    hilog.info(0x0000, 'ADAPTER', `[GREE] 动态组装格力空调38kHz专属时序: 动作=${action}, 值=${safeValue}`);

    return {
      "device": deviceType,
      "action": action,
      "value": safeValue,
      "protocol": "gree_ir_standard",
      "vendorCode": "0x47"
    };
  }
}