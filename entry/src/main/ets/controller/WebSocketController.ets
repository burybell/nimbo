import { BusinessError } from '@kit.BasicServicesKit';
import { webSocket } from '@kit.NetworkKit';

export type WebSocketEventKind = 'open' | 'message' | 'close' | 'error';

export interface WebSocketEvent {
  kind: WebSocketEventKind;
  text: string;
  code: string;
}

export class WebSocketController {
  private sockets: Map<string, webSocket.WebSocket> = new Map<string, webSocket.WebSocket>();

  private messageText(data: string | ArrayBuffer): string {
    if (typeof data === 'string') return data;
    return `[Binary message · ${data.byteLength} bytes]`;
  }

  private errorText(error: BusinessError): string {
    return error && typeof error.message === 'string' && error.message.length > 0 ? error.message :
      'WebSocket operation failed';
  }

  private errorCode(error: BusinessError): string {
    return error && typeof error.code === 'number' ? `${error.code}` : 'WEBSOCKET_ERROR';
  }

  async connect(id: string, url: string, headers: Record<string, string>,
    onEvent: (event: WebSocketEvent) => void): Promise<void> {
    await this.disconnect(id, false);
    const socket = webSocket.createWebSocket();
    this.sockets.set(id, socket);
    socket.on('open', (error: BusinessError) => {
      if (this.sockets.get(id) !== socket) return;
      if (error) {
        onEvent({ kind: 'error', text: this.errorText(error), code: this.errorCode(error) });
        return;
      }
      onEvent({ kind: 'open', text: '', code: '' });
    });
    socket.on('message', (error: BusinessError, data: string | ArrayBuffer) => {
      if (this.sockets.get(id) !== socket) return;
      if (error) {
        onEvent({ kind: 'error', text: this.errorText(error), code: this.errorCode(error) });
        return;
      }
      onEvent({ kind: 'message', text: this.messageText(data), code: '' });
    });
    socket.on('close', (error: BusinessError, data: webSocket.CloseResult) => {
      if (this.sockets.get(id) !== socket) return;
      this.sockets.delete(id);
      if (error) {
        onEvent({ kind: 'error', text: this.errorText(error), code: this.errorCode(error) });
        return;
      }
      onEvent({ kind: 'close', text: data.reason ?? '', code: `${data.code}` });
    });
    socket.on('error', (error: BusinessError) => {
      if (this.sockets.get(id) !== socket) return;
      onEvent({ kind: 'error', text: this.errorText(error), code: this.errorCode(error) });
    });
    try {
      if (Object.keys(headers).length > 0) await socket.connect(url, { header: headers });
      else await socket.connect(url);
    } catch (error) {
      if (this.sockets.get(id) === socket) this.sockets.delete(id);
      const failure = error as BusinessError;
      onEvent({ kind: 'error', text: this.errorText(failure), code: this.errorCode(failure) });
    }
  }

  async send(id: string, value: string): Promise<boolean> {
    const socket = this.sockets.get(id);
    if (!socket) return false;
    try {
      return await socket.send(value);
    } catch (_error) {
      return false;
    }
  }

  async disconnect(id: string, notify: boolean = true): Promise<void> {
    const socket = this.sockets.get(id);
    if (!socket) return;
    if (!notify) this.sockets.delete(id);
    try {
      await socket.close({ code: 1000, reason: 'Closed by Nimbo' });
    } catch (_error) {
      this.sockets.delete(id);
    }
  }

  disconnectAll(): void {
    this.sockets.forEach((socket: webSocket.WebSocket) => {
      try {
        socket.close({ code: 1001, reason: 'Nimbo window closed' });
      } catch (_error) {
        // The socket may already be closing.
      }
    });
    this.sockets.clear();
  }
}
