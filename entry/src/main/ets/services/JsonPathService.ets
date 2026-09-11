interface JsonPathToken {
  kind: 'property' | 'index' | 'wildcard';
  property: string;
  index: number;
}

export interface JsonPathResult {
  success: boolean;
  status: 'success' | 'noMatch' | 'invalidJson' | 'invalidPath';
  value: string;
  message: string;
}

export class JsonPathService {
  private static invalid(message: string): JsonPathResult {
    return { success: false, status: 'invalidPath', value: '', message };
  }

  private static parse(path: string): JsonPathToken[] | undefined {
    const source = path.trim();
    if (source.length === 0 || source[0] !== '$') return undefined;
    const tokens: JsonPathToken[] = [];
    let index = 1;
    while (index < source.length) {
      if (source[index] === '.') {
        index += 1;
        if (index < source.length && source[index] === '*') {
          tokens.push({ kind: 'wildcard', property: '', index: -1 });
          index += 1;
          continue;
        }
        const start = index;
        while (index < source.length && source[index] !== '.' && source[index] !== '[') index += 1;
        if (start === index) return undefined;
        tokens.push({ kind: 'property', property: source.substring(start, index), index: -1 });
      } else if (source[index] === '[') {
        const close = source.indexOf(']', index + 1);
        if (close < 0) return undefined;
        const content = source.substring(index + 1, close).trim();
        if (content === '*') {
          tokens.push({ kind: 'wildcard', property: '', index: -1 });
        } else if ((content.startsWith("'") && content.endsWith("'")) ||
          (content.startsWith('"') && content.endsWith('"'))) {
          tokens.push({ kind: 'property', property: content.substring(1, content.length - 1), index: -1 });
        } else {
          const arrayIndex = Number.parseInt(content);
          if (Number.isNaN(arrayIndex) || arrayIndex < 0 || arrayIndex.toString() !== content) return undefined;
          tokens.push({ kind: 'index', property: '', index: arrayIndex });
        }
        index = close + 1;
      } else {
        return undefined;
      }
    }
    return tokens;
  }

  private static children(value: Object, token: JsonPathToken): Object[] {
    if (token.kind === 'index') {
      if (!Array.isArray(value) || token.index >= value.length) return [];
      return [value[token.index] as Object];
    }
    if (token.kind === 'wildcard') {
      if (Array.isArray(value)) return value as Object[];
      if (value === null || typeof value !== 'object') return [];
      const record = value as Record<string, Object>;
      return Object.keys(record).map((key: string) => record[key]);
    }
    if (value === null || typeof value !== 'object' || Array.isArray(value)) return [];
    const record = value as Record<string, Object>;
    if (!Object.keys(record).includes(token.property)) return [];
    return [record[token.property]];
  }

  private static valueText(values: Object[]): string {
    const value: Object = values.length === 1 ? values[0] : values;
    if (value === null) return 'null';
    if (typeof value === 'string') return value;
    if (typeof value === 'number' || typeof value === 'boolean') return `${value}`;
    return JSON.stringify(value);
  }

  static evaluate(body: string, path: string): JsonPathResult {
    const tokens = JsonPathService.parse(path);
    if (tokens === undefined) return JsonPathService.invalid('Invalid JSONPath');
    let root: Object;
    try {
      root = JSON.parse(body) as Object;
    } catch (_error) {
      return { success: false, status: 'invalidJson', value: '', message: 'Response body is not valid JSON' };
    }
    let values: Object[] = [root];
    tokens.forEach((token: JsonPathToken) => {
      const next: Object[] = [];
      values.forEach((value: Object) => next.push(...JsonPathService.children(value, token)));
      values = next;
    });
    if (values.length === 0) {
      return { success: false, status: 'noMatch', value: '', message: 'JSONPath did not match a value' };
    }
    return { success: true, status: 'success', value: JsonPathService.valueText(values), message: '' };
  }
}
