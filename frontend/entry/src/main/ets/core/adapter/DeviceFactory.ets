import { IDeviceAdapter } from './IDeviceAdapter';
import { Hi3861Adapter } from './Hi3861Adapter';

export enum DeviceBrand {
  HI3861 = 'HI3861',
  MIDEA = 'MIDEA',
  GREE = 'GREE'
}

export class DeviceFactory {
  public static createAdapter(brand: DeviceBrand): IDeviceAdapter {
    switch (brand) {
      case DeviceBrand.HI3861:
        return new Hi3861Adapter();
      case DeviceBrand.MIDEA:
        throw new Error('MideaAdapter未实现。底层架构已做好商用品牌扩展预留。');
      case DeviceBrand.GREE:
        throw new Error('GreeAdapter未实现。底层架构已做好商用品牌扩展预留。');
      default:
        throw new Error(`不支持的品牌:${brand}`);
    }
  }
}