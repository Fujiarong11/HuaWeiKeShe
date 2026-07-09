import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { deviceInfo } from '@kit.BasicServicesKit';
import { DatabaseHelper } from '../data/DatabaseHelper';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }

    // 检测设备类型并存储到 AppStorage，用于分布式布局适配
    try {
      const deviceType = deviceInfo.deviceType;
      AppStorage.setOrCreate('deviceType', deviceType);
      hilog.info(DOMAIN, 'testTag', 'Device type: %{public}s', deviceType);
    } catch (err) {
      // 默认手机布局
      AppStorage.setOrCreate('deviceType', 'phone');
    }

    // 初始化本地数据库
    try {
      DatabaseHelper.init(this.context);
      hilog.info(DOMAIN, 'testTag', 'Database initialized');
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Database init failed: %{public}s', JSON.stringify(err));
    }

    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/home/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }

  /**
   * 分布式迁移回调：保存当前页面状态用于跨设备迁移
   */
  onContinue(wantParam: Record<string, Object>): AbilityConstant.OnContinueResult {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onContinue');
    return AbilityConstant.OnContinueResult.AGREE;
  }

  /**
   * 处理跨设备迁移传递的数据（平板端接收）
   */
  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onNewWant');
  }
}
