// frontend/entry/src/main/ets/models/DeviceModels.ets

export type DeviceType = 'ac' | 'light' | 'lock' | 'valve' | 'pump';
export type DeviceAction = 'on' | 'off' | 'status_sync';

export class SmartPayload {
  public device_type: DeviceType;
  public action: DeviceAction;
  public brand: string;
  public target_temp: number;

  constructor(device_type: DeviceType, action: DeviceAction, brand: string = '', target_temp: number = 0) {
    this.device_type = device_type;
    this.action = action;
    this.brand = brand;
    this.target_temp = target_temp;
  }
}

export class SensorDataModel {
  public temperature: number = 0.0;
  public humidity: number = 0.0;
  public light: number = 0.0;
  public co2: number = 0.0;
  public ph: number = 0.0;
  public soilMoist: number = 0.0;
  public reportTime: string = '';
}

export class CryptoModuleState {
  public name: string;
  public algorithm: string;
  public isEncrypted: boolean;

  constructor(name: string, algorithm: string, isEncrypted: boolean) {
    this.name = name;
    this.algorithm = algorithm;
    this.isEncrypted = isEncrypted;
  }
}