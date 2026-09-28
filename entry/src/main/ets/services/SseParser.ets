export interface ParsedSseEvent {
  event: string;
  data: string;
  eventId: string;
  retry: string;
}

export class SseParser {
  private buffer: string = '';

  private parseBlock(block: string): ParsedSseEvent | undefined {
    let event = 'message';
    let eventId = '';
    let retry = '';
    const data: string[] = [];
    block.split('\n').forEach((line: string) => {
      if (line.length === 0 || line.startsWith(':')) return;
      const separator = line.indexOf(':');
      const field = separator < 0 ? line : line.substring(0, separator);
      let value = separator < 0 ? '' : line.substring(separator + 1);
      if (value.startsWith(' ')) value = value.substring(1);
      if (field === 'event' && value.length > 0) event = value;
      else if (field === 'data') data.push(value);
      else if (field === 'id') eventId = value;
      else if (field === 'retry' && /^\d+$/.test(value)) retry = value;
    });
    if (data.length === 0 && eventId.length === 0 && retry.length === 0 && event === 'message') return undefined;
    return { event, data: data.join('\n'), eventId, retry };
  }

  push(value: string): ParsedSseEvent[] {
    this.buffer += value.replace(/\r\n/g, '\n').replace(/\r/g, '\n');
    const events: ParsedSseEvent[] = [];
    let separator = this.buffer.indexOf('\n\n');
    while (separator >= 0) {
      const parsed = this.parseBlock(this.buffer.substring(0, separator));
      this.buffer = this.buffer.substring(separator + 2);
      if (parsed) events.push(parsed);
      separator = this.buffer.indexOf('\n\n');
    }
    return events;
  }

  finish(): ParsedSseEvent[] {
    if (this.buffer.trim().length === 0) {
      this.buffer = '';
      return [];
    }
    const parsed = this.parseBlock(this.buffer);
    this.buffer = '';
    return parsed ? [parsed] : [];
  }
}
