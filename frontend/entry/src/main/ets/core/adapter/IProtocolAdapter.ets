export interface IProtocolAdapter {
  getProtocolName(): string;
  connect(url: string, port: number): Promise<boolean>;
  publish(topic: string, payload: Record<string, string | number>): void;
}