export enum DeviceType {
  LIGHT = 'light',
  DOOR = 'door',
  AC = 'ac'
}

export enum DeviceAction {
  POWER = 'power',
  TEMPERATURE = 'temperature',
  MODE = 'mode',
  LOCK = 'lock',
  AUTO = 'auto' // 🌟 新增：自动环境感知动作
}