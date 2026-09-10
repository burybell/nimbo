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
}
