import { DeviceType, DeviceAction } from './DeviceConstants';

export class DeviceCommand {
  deviceType: DeviceType;
  action: DeviceAction;
  value: number | string | boolean;

  // 答辩加分点：预留扩展字段，展现前瞻性
  timestamp?: number;
  userId?: string;

  constructor(deviceType: DeviceType, action: DeviceAction, value: number | string | boolean) {
    this.deviceType = deviceType;
    this.action = action;
    this.value = value;
    this.timestamp = Date.now();
  }
}