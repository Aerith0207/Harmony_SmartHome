// 文件路径参考: entry/src/main/ets/features/ai/AiConfirmDialog.ets
import { AiCommand } from './AiDecisionEngine';

@CustomDialog
export struct AiConfirmDialog {
  controller: CustomDialogController;
  strategyList: AiCommand[] = [];
  onConfirm: () => void = () => {};

  build() {
    Column() {
      Text('🧠 AI 智能场景决策')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 15 })

      ForEach(this.strategyList, (item: AiCommand) => {
        Row() {
          Text(`设备: ${item.device} `).fontColor('#666').fontSize(16)
          Text(`动作: ${item.action} -> ${item.value}`).fontColor('#00E5FF').fontSize(16).fontWeight(FontWeight.Medium)
        }.width('100%').margin({ bottom: 10 }).padding({ left: 10, right: 10 })
      })

      Row({ space: 20 }) {
        Button('取消忽略')
          .backgroundColor('#F5F5F5')
          .fontColor('#333')
          .layoutWeight(1)
          .onClick(() => { this.controller.close() })

        Button('授权执行')
          .backgroundColor('#00E5FF')
          .fontColor(Color.White)
          .layoutWeight(1)
          .onClick(() => {
            this.onConfirm();
            this.controller.close();
          })
      }.margin({ top: 20 }).width('100%')
    }
    .padding(24)
    .backgroundColor(Color.White)
    .borderRadius(16)
  }
}