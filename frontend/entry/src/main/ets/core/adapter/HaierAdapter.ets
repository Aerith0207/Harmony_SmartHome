import hilog from '@ohos.hilog';
import { IDeviceAdapter } from './IDeviceAdapter';

export class HaierAdapter implements IDeviceAdapter {
  getDeviceBrand(): string {
    return "Haier";
  }

  encodeCommand(deviceType: string, action: string, value: number | string | boolean): Record<string, string | number> {
    // 将布尔值安全转换为数字以通过ArkTS类型检查
    let safeValue: string | number = typeof value === 'boolean' ? (value ? 1 : 0) : value;

    hilog.info(0x0000, 'ADAPTER', `[HAIER] 构建海尔特有校验和控制包: 动作=${action}, 值=${safeValue}`);

    return {
      "device": deviceType,
      "action": action,
      "value": safeValue,
      "protocol": "haier_ir_checksum",
      "vendorCode": "0x48"
    };
  }
}