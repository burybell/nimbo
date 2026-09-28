import { window } from '@kit.ArkUI';

const TITLE_BUTTON_FALLBACK_INSET = 132;
const TITLE_BAR_EDGE_INSET = 12;

export class WindowChromeController {
  private static mainWindow: window.Window | undefined = undefined;

  static bind(mainWindow: window.Window): void {
    WindowChromeController.mainWindow = mainWindow;
  }

  static unbind(): void {
    WindowChromeController.mainWindow = undefined;
  }

  static startMoving(): void {
    WindowChromeController.mainWindow?.startMoving().catch(() => {});
  }

  static toggleMaximized(): void {
    const mainWindow = WindowChromeController.mainWindow;
    if (!mainWindow) return;
    try {
      const status = mainWindow.getWindowStatus();
      if (status === window.WindowStatusType.MAXIMIZE || status === window.WindowStatusType.FULL_SCREEN) {
        AppStorage.setOrCreate('nimbo.titleButtonInset', TITLE_BUTTON_FALLBACK_INSET);
        mainWindow.recover().then(() => {
          try {
            const rect = mainWindow.getTitleButtonRect();
            AppStorage.setOrCreate('nimbo.titleButtonInset',
              Math.max(TITLE_BUTTON_FALLBACK_INSET, rect.right + rect.width + TITLE_BAR_EDGE_INSET));
          } catch (_error) {
            // Keep the safe fallback until the title button rectangle callback arrives.
          }
        }).catch(() => {});
      } else {
        AppStorage.setOrCreate('nimbo.titleButtonInset', TITLE_BAR_EDGE_INSET);
        mainWindow.maximize().catch(() => {
          AppStorage.setOrCreate('nimbo.titleButtonInset', TITLE_BUTTON_FALLBACK_INSET);
        });
      }
    } catch (_error) {
      // Native title dragging remains available when status inspection is unsupported.
    }
  }
}
