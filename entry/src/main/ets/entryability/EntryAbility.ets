import { AbilityConstant, Configuration, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { WindowChromeController } from '../services/WindowChromeController';

const DOMAIN = 0x0000;
const TITLE_BAR_HEIGHT = 52;
const TITLE_BUTTON_FALLBACK_INSET = 132;

export default class EntryAbility extends UIAbility {
  private mainWindow: window.Window | undefined = undefined;
  private titleButtonRectChange = (rect: window.TitleButtonRect): void => {
    this.publishTitleButtonInset(rect);
  };

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, 'Nimbo', 'EntryAbility created');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    AppStorage.setOrCreate('nimbo.titleButtonInset', TITLE_BUTTON_FALLBACK_INSET);
    this.loadMainPage(windowStage);
  }

  onWindowStageDestroy(): void {
    if (this.mainWindow) {
      try {
        this.mainWindow.off('windowTitleButtonRectChange', this.titleButtonRectChange);
      } catch (error) {
        hilog.warn(DOMAIN, 'Nimbo', 'Unable to detach title button observer: %{public}s', JSON.stringify(error));
      }
    }
    WindowChromeController.unbind();
    this.mainWindow = undefined;
  }

  onConfigurationUpdate(newConfig: Configuration): void {
    if (!this.mainWindow || newConfig.colorMode === undefined) return;
    try {
      this.mainWindow.setDecorButtonStyle({ buttonIconSize: 18, buttonBackgroundSize: 32,
        spacingBetweenButtons: 8, closeButtonRightMargin: 12, buttonBackgroundCornerRadius: 16,
        colorMode: newConfig.colorMode });
    } catch (error) {
      hilog.warn(DOMAIN, 'Nimbo', 'Unable to update title button colors: %{public}s', JSON.stringify(error));
    }
  }

  private loadMainPage(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/Index', (error) => {
      if (error.code) {
        hilog.error(DOMAIN, 'Nimbo', 'Failed to load the main page: %{public}s', JSON.stringify(error));
        return;
      }
      windowStage.getMainWindow((windowError, mainWindow) => {
        if (!windowError.code) {
          this.configureWindowChrome(mainWindow);
        } else {
          hilog.warn(DOMAIN, 'Nimbo', 'Unable to configure window chrome: %{public}s', JSON.stringify(windowError));
        }
      });
    });
  }

  private configureWindowChrome(mainWindow: window.Window): void {
    this.mainWindow = mainWindow;
    WindowChromeController.bind(mainWindow);
    try {
      mainWindow.setWindowDecorVisible(false);
      mainWindow.setWindowDecorHeight(TITLE_BAR_HEIGHT);
      mainWindow.setWindowTitleMoveEnabled(true);
      mainWindow.setDecorButtonStyle({ buttonIconSize: 18, buttonBackgroundSize: 32,
        spacingBetweenButtons: 8, closeButtonRightMargin: 12, buttonBackgroundCornerRadius: 16 });
      this.publishTitleButtonInset(mainWindow.getTitleButtonRect());
      mainWindow.on('windowTitleButtonRectChange', this.titleButtonRectChange);
    } catch (error) {
      hilog.warn(DOMAIN, 'Nimbo', 'Immersive title bar is unavailable: %{public}s', JSON.stringify(error));
    }
  }

  private publishTitleButtonInset(rect: window.TitleButtonRect): void {
    const inset = Math.max(TITLE_BUTTON_FALLBACK_INSET, rect.right + rect.width + 12);
    AppStorage.setOrCreate('nimbo.titleButtonInset', inset);
  }
}
