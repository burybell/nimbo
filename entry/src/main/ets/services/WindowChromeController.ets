import { window } from '@kit.ArkUI';

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
        mainWindow.recover().catch(() => {});
      } else {
        mainWindow.maximize().catch(() => {});
      }
    } catch (_error) {
      // Native title dragging remains available when status inspection is unsupported.
    }
  }
}
