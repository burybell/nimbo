import filePicker from '@ohos.file.picker';
import { fileIo } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';

export class LocalFileExporter {
  private static async write(uri: string, data: ArrayBuffer): Promise<void> {
    let descriptor = -1;
    try {
      const file = await fileIo.open(uri, fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.TRUNC);
      descriptor = file.fd;
      let offset = 0;
      while (offset < data.byteLength) {
        const written = await fileIo.write(descriptor, data.slice(offset));
        if (written <= 0) throw new Error('The selected file could not be written.');
        offset += written;
      }
    } catch (error) {
      if (error instanceof Error) throw error;
      throw new Error('The selected file could not be written.');
    } finally {
      if (descriptor >= 0) {
        try { fileIo.closeSync(descriptor); } catch (_error) {}
      }
    }
  }

  static async saveBytes(suggestedName: string, data: ArrayBuffer): Promise<boolean> {
    const options = new filePicker.DocumentSaveOptions();
    options.newFileNames = [suggestedName];
    const uris = await new filePicker.DocumentViewPicker().save(options);
    if (uris.length === 0) return false;
    await LocalFileExporter.write(uris[0], data);
    return true;
  }

  static async saveText(suggestedName: string, value: string): Promise<boolean> {
    const encoded = new util.TextEncoder().encodeInto(value);
    return LocalFileExporter.saveBytes(suggestedName, encoded.buffer as ArrayBuffer);
  }
}
