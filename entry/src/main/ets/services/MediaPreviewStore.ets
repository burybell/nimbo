import { fileIo } from '@kit.CoreFileKit';

export class MediaPreviewStore {
  private static paths: Map<string, string> = new Map<string, string>();

  private static extension(contentType: string): string {
    const value = contentType.toLowerCase();
    if (value.includes('png')) return 'png';
    if (value.includes('jpeg') || value.includes('jpg')) return 'jpg';
    if (value.includes('gif')) return 'gif';
    if (value.includes('webp')) return 'webp';
    if (value.includes('svg')) return 'svg';
    if (value.includes('webm')) return 'webm';
    if (value.includes('quicktime')) return 'mov';
    if (value.includes('ogg')) return 'ogv';
    if (value.includes('mpeg')) return 'mpeg';
    return 'mp4';
  }

  private static safeId(id: string): string {
    return id.replace(/[^a-zA-Z0-9_-]/g, '-');
  }

  private static async removePrevious(id: string): Promise<void> {
    const path = MediaPreviewStore.paths.get(id);
    if (!path) return;
    try {
      await fileIo.unlink(path);
    } catch (_error) {
      // Cache files can already be removed by the operating system.
    }
    MediaPreviewStore.paths.delete(id);
  }

  static async create(cacheDir: string, id: string, contentType: string, data: ArrayBuffer): Promise<string> {
    await MediaPreviewStore.removePrevious(id);
    const path = `${cacheDir}/nimbo-preview-${MediaPreviewStore.safeId(id)}-${Date.now()}.` +
      MediaPreviewStore.extension(contentType);
    let descriptor = -1;
    try {
      const file = await fileIo.open(path,
        fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.TRUNC);
      descriptor = file.fd;
      let offset = 0;
      while (offset < data.byteLength) {
        const written = await fileIo.write(descriptor, data.slice(offset));
        if (written <= 0) throw new Error('Unable to write media preview.');
        offset += written;
      }
      MediaPreviewStore.paths.set(id, path);
      return `file://${path}`;
    } catch (error) {
      if (error instanceof Error) throw error;
      throw new Error('Unable to prepare media preview.');
    } finally {
      if (descriptor >= 0) {
        try { fileIo.closeSync(descriptor); } catch (_error) {}
      }
    }
  }
}
