import { AbilityConstant, Configuration, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { WindowChromeController } from '../services/WindowChromeController';

const DOMAIN = 0x0000;
const TITLE_BAR_HEIGHT = 52;
const TITLE_BUTTON_FALLBACK_INSET = 132;
const TITLE_BAR_EDGE_INSET = 12;

export default class EntryAbility extends UIAbility {
  private mainWindow: window.Window | undefined = undefined;
  private currentWindowStatus: window.WindowStatusType = window.WindowStatusType.UNDEFINED;
  private titleButtonRectChange = (rect: window.TitleButtonRect): void => {
    this.publishTitleButtonInset(rect);
  };
  private windowStatusChange = (status: window.WindowStatusType): void => {
    this.publishTitleButtonInsetForStatus(status);
  };
  private windowEventChange = (event: window.WindowEventType): void => {
    if (event === window.WindowEventType.WINDOW_ACTIVE || event === window.WindowEventType.WINDOW_SHOWN) {
      AppStorage.setOrCreate('nimbo.windowFocused', true);
    } else if (event === window.WindowEventType.WINDOW_INACTIVE || event === window.WindowEventType.WINDOW_HIDDEN) {
      AppStorage.setOrCreate('nimbo.windowFocused', false);
    }
  };

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, 'Nimbo', 'EntryAbility created');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    AppStorage.setOrCreate('nimbo.titleButtonInset', TITLE_BUTTON_FALLBACK_INSET);
    AppStorage.setOrCreate('nimbo.windowFocused', true);
    this.loadMainPage(windowStage);
  }

  onWindowStageDestroy(): void {
    if (this.mainWindow) {
      try {
        this.mainWindow.off('windowTitleButtonRectChange', this.titleButtonRectChange);
        this.mainWindow.off('windowStatusDidChange', this.windowStatusChange);
        this.mainWindow.off('windowEvent', this.windowEventChange);
      } catch (error) {
        hilog.warn(DOMAIN, 'Nimbo', 'Unable to detach title button observer: %{public}s', JSON.stringify(error));
      }
    }
    WindowChromeController.unbind();
    this.mainWindow = undefined;
    this.currentWindowStatus = window.WindowStatusType.UNDEFINED;
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
      this.currentWindowStatus = mainWindow.getWindowStatus();
      this.publishTitleButtonInset(mainWindow.getTitleButtonRect(), this.currentWindowStatus);
      mainWindow.on('windowTitleButtonRectChange', this.titleButtonRectChange);
      mainWindow.on('windowStatusDidChange', this.windowStatusChange);
      mainWindow.on('windowEvent', this.windowEventChange);
    } catch (error) {
      hilog.warn(DOMAIN, 'Nimbo', 'Immersive title bar is unavailable: %{public}s', JSON.stringify(error));
    }
  }

  private publishTitleButtonInsetForStatus(status: window.WindowStatusType): void {
    this.currentWindowStatus = status;
    if (status === window.WindowStatusType.MAXIMIZE || status === window.WindowStatusType.FULL_SCREEN) {
      AppStorage.setOrCreate('nimbo.titleButtonInset', TITLE_BAR_EDGE_INSET);
      return;
    }
    if (!this.mainWindow) {
      AppStorage.setOrCreate('nimbo.titleButtonInset', TITLE_BUTTON_FALLBACK_INSET);
      return;
    }
    try {
      this.publishTitleButtonInset(this.mainWindow.getTitleButtonRect(), status);
    } catch (_error) {
      AppStorage.setOrCreate('nimbo.titleButtonInset', TITLE_BUTTON_FALLBACK_INSET);
    }
  }

  private publishTitleButtonInset(rect: window.TitleButtonRect,
    status?: window.WindowStatusType): void {
    const currentStatus = status ?? this.currentWindowStatus;
    if (currentStatus === window.WindowStatusType.MAXIMIZE || currentStatus === window.WindowStatusType.FULL_SCREEN) {
      AppStorage.setOrCreate('nimbo.titleButtonInset', TITLE_BAR_EDGE_INSET);
      return;
    }
    const inset = Math.max(TITLE_BUTTON_FALLBACK_INSET, rect.right + rect.width + 12);
    AppStorage.setOrCreate('nimbo.titleButtonInset', inset);
  }
}
