import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { CryptoUtil } from '../core/utils/CryptoUtil';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  // 🌟 新增：用于记录冷热启动时间的类成员变量
  private coldStartTime: number = 0;
  private hotStartTime: number = 0;

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    // 🌟 核心埋点：记录冷启动起点
    this.coldStartTime = Date.now();
    hilog.info(DOMAIN, 'PERF_TEST', '🚀 [冷启动起点] App onCreate 触发, 时间戳: %{public}d', this.coldStartTime);

    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    CryptoUtil.initKeyStore();
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, 'testTag', '开始加载页面...');

    try {
      windowStage.loadContent('pages/Login', (err) => {
        if (err && err.code) {
          hilog.error(DOMAIN, 'testTag', '⚠️ 页面加载失败！错误码: %{public}d, 原因: %{public}s', err.code, err.message);
          return;
        }
        // 🌟 核心埋点：记录窗口加载完成
        hilog.info(DOMAIN, 'PERF_TEST', '🔲 WindowStage 加载主页面完成');
      });
    } catch (exception) {
      hilog.error(DOMAIN, 'testTag', '💥 loadContent 发生致命同步异常: %{public}s', JSON.stringify(exception));
    }
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // 🌟 核心埋点：记录热启动起点
    this.hotStartTime = Date.now();
    hilog.info(DOMAIN, 'PERF_TEST', '⚡ [热启动起点] App onForeground 触发, 时间戳: %{public}d', this.hotStartTime);
  }

  onBackground(): void {
    hilog.info(DOMAIN, 'PERF_TEST', '💤 App 进入后台挂起 (onBackground)');
  }
}