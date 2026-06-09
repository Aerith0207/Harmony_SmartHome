export interface IDeviceAdapter {
  getDeviceBrand(): string;
  encodeCommand(deviceType: string, action: string, value: number | string | boolean): Record<string, string | number>;
}