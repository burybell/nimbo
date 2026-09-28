import filePicker from '@ohos.file.picker';
import { fileIo } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';

export interface RunnerDataRow {
  values: Record<string, string>;
}

export interface RunnerDataSet {
  fileName: string;
  columns: string[];
  rows: RunnerDataRow[];
}

export class RunnerDataService {
  private static readonly MAX_BYTES: number = 2 * 1024 * 1024;
  private static readonly MAX_ROWS: number = 1000;
  private static readonly MAX_COLUMNS: number = 100;

  private static displayName(uri: string): string {
    const slash = uri.lastIndexOf('/');
    const name = slash < 0 ? uri : uri.substring(slash + 1);
    try { return decodeURIComponent(name); } catch (_error) { return name; }
  }

  private static async readText(uri: string): Promise<string> {
    let descriptor = -1;
    try {
      const file = await fileIo.open(uri, fileIo.OpenMode.READ_ONLY);
      descriptor = file.fd;
      const stat = await fileIo.stat(descriptor);
      if (stat.size > RunnerDataService.MAX_BYTES) {
        throw new Error('The data file exceeds the 2 MB limit.');
      }
      const buffer = new ArrayBuffer(stat.size);
      const bytesRead = await fileIo.read(descriptor, buffer);
      return new util.TextDecoder().decodeToString(new Uint8Array(buffer.slice(0, bytesRead)));
    } catch (error) {
      if (error instanceof Error) throw error;
      throw new Error('The selected data file could not be read.');
    } finally {
      if (descriptor >= 0) {
        try { fileIo.closeSync(descriptor); } catch (_error) {}
      }
    }
  }

  private static validateColumns(columns: string[]): void {
    if (columns.length === 0) throw new Error('The data file has no columns.');
    if (columns.length > RunnerDataService.MAX_COLUMNS) {
      throw new Error(`The data file exceeds the ${RunnerDataService.MAX_COLUMNS}-column limit.`);
    }
    const seen: string[] = [];
    columns.forEach((column: string, index: number) => {
      if (column.length === 0) throw new Error(`Column ${index + 1} has an empty name.`);
      if (seen.includes(column)) throw new Error(`Duplicate column name: ${column}`);
      seen.push(column);
    });
  }

  private static parseCsvRows(text: string): string[][] {
    const rows: string[][] = [];
    let row: string[] = [];
    let field = '';
    let quoted = false;
    let afterQuote = false;
    for (let index = 0; index < text.length; index += 1) {
      const character = text[index];
      if (quoted) {
        if (character === '"') {
          if (index + 1 < text.length && text[index + 1] === '"') {
            field += '"';
            index += 1;
          } else {
            quoted = false;
            afterQuote = true;
          }
        } else {
          field += character;
        }
        continue;
      }
      if (afterQuote) {
        if (character === ' ' || character === '\t') continue;
        if (character !== ',' && character !== '\n' && character !== '\r') {
          throw new Error(`Unexpected character after a quoted field near row ${rows.length + 1}.`);
        }
        afterQuote = false;
      }
      if (character === '"') {
        if (field.length > 0) throw new Error(`Unexpected quote near row ${rows.length + 1}.`);
        quoted = true;
      } else if (character === ',') {
        row.push(field);
        field = '';
      } else if (character === '\n' || character === '\r') {
        if (character === '\r' && index + 1 < text.length && text[index + 1] === '\n') index += 1;
        row.push(field);
        rows.push(row);
        row = [];
        field = '';
      } else {
        field += character;
      }
    }
    if (quoted) throw new Error(`Unclosed quoted field near row ${rows.length + 1}.`);
    if (field.length > 0 || row.length > 0) {
      row.push(field);
      rows.push(row);
    }
    while (rows.length > 0 && rows[rows.length - 1].every((value: string) => value.length === 0)) {
      rows.pop();
    }
    return rows;
  }

  private static parseCsv(fileName: string, text: string): RunnerDataSet {
    const parsed = RunnerDataService.parseCsvRows(text);
    if (parsed.length < 2) throw new Error('CSV data requires a header and at least one data row.');
    const columns = parsed[0].map((value: string, index: number) =>
      (index === 0 ? value.replace(/^\uFEFF/, '') : value).trim());
    RunnerDataService.validateColumns(columns);
    const rows: RunnerDataRow[] = [];
    for (let index = 1; index < parsed.length; index += 1) {
      const values = parsed[index];
      if (values.every((value: string) => value.length === 0)) continue;
      if (values.length !== columns.length) {
        throw new Error(`CSV row ${index + 1} has ${values.length} values; expected ${columns.length}.`);
      }
      const mapped: Record<string, string> = {};
      columns.forEach((column: string, columnIndex: number) => { mapped[column] = values[columnIndex]; });
      rows.push({ values: mapped });
    }
    if (rows.length === 0) throw new Error('CSV data has no non-empty data rows.');
    if (rows.length > RunnerDataService.MAX_ROWS) {
      throw new Error(`The data file exceeds the ${RunnerDataService.MAX_ROWS}-row limit.`);
    }
    return { fileName, columns, rows };
  }

  private static jsonValue(value: Object | null, row: number, column: string): string {
    if (value === null) return '';
    if (typeof value === 'string' || typeof value === 'number' || typeof value === 'boolean') {
      return value.toString();
    }
    throw new Error(`JSON row ${row}, column ${column} must contain a primitive value.`);
  }

  private static parseJson(fileName: string, text: string): RunnerDataSet {
    let source: Object;
    try {
      source = JSON.parse(text) as Object;
    } catch (_error) {
      throw new Error('The selected data file is not valid JSON.');
    }
    if (!Array.isArray(source) || source.length === 0) {
      throw new Error('JSON data must be a non-empty array of objects.');
    }
    if (source.length > RunnerDataService.MAX_ROWS) {
      throw new Error(`The data file exceeds the ${RunnerDataService.MAX_ROWS}-row limit.`);
    }
    const columns: string[] = [];
    source.forEach((value: Object, index: number) => {
      if (value === null || Array.isArray(value) || typeof value !== 'object') {
        throw new Error(`JSON row ${index + 1} must be an object.`);
      }
      Object.keys(value).forEach((column: string) => {
        if (!columns.includes(column)) columns.push(column);
      });
    });
    RunnerDataService.validateColumns(columns);
    const rows: RunnerDataRow[] = source.map((value: Object, index: number): RunnerDataRow => {
      const record = value as Record<string, Object | null>;
      const mapped: Record<string, string> = {};
      columns.forEach((column: string) => {
        mapped[column] = Object.keys(record).includes(column) ?
          RunnerDataService.jsonValue(record[column], index + 1, column) : '';
      });
      return { values: mapped };
    });
    return { fileName, columns, rows };
  }

  static parse(fileName: string, text: string): RunnerDataSet {
    const trimmed = text.trim();
    if (trimmed.length === 0) throw new Error('The selected data file is empty.');
    if (fileName.toLowerCase().endsWith('.json') || trimmed.startsWith('[')) {
      return RunnerDataService.parseJson(fileName, trimmed);
    }
    return RunnerDataService.parseCsv(fileName, text);
  }

  static async select(): Promise<RunnerDataSet | undefined> {
    const uris = await new filePicker.DocumentViewPicker().select();
    if (uris.length === 0) return undefined;
    const fileName = RunnerDataService.displayName(uris[0]);
    return RunnerDataService.parse(fileName, await RunnerDataService.readText(uris[0]));
  }
}
