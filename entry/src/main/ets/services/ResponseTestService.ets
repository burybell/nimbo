import { KeyValueItem, ResponseModel, TestResult, TestResultMessage, TestRule } from '../models/ShellModels';
import { JsonPathResult, JsonPathService } from './JsonPathService';

export class ResponseTestService {
  private static result(rule: TestRule, status: 'passed' | 'failed' | 'notRun',
    actual: string, message: TestResultMessage): TestResult {
    return { ruleId: rule.id, status, actual, expected: rule.expected, message };
  }

  private static header(response: ResponseModel, name: string): KeyValueItem | undefined {
    const target = name.trim().toLowerCase();
    return response.headers.find((item: KeyValueItem) => item.key.trim().toLowerCase() === target);
  }

  private static evaluate(rule: TestRule, response: ResponseModel): TestResult {
    if (rule.kind === 'statusEquals') {
      const expectedText = rule.expected.trim();
      const expected = Number(expectedText);
      const actual = response.statusCode.toString();
      if (expectedText.length === 0 || Number.isNaN(expected) || !Number.isInteger(expected) || expected < 100 ||
        expected > 999) return ResponseTestService.result(rule, 'failed', actual,
        'configurationInvalid');
      return ResponseTestService.result(rule, response.statusCode === expected ? 'passed' : 'failed', actual,
        response.statusCode === expected ? 'statusMatched' : 'statusMismatch');
    }
    if (rule.kind === 'durationLessThan') {
      const expectedText = rule.expected.trim();
      const expected = Number(expectedText);
      const actual = Number(response.duration);
      if (expectedText.length === 0 || Number.isNaN(expected) || expected < 0) return ResponseTestService.result(rule,
        'failed', response.duration,
        'configurationInvalid');
      if (Number.isNaN(actual)) return ResponseTestService.result(rule, 'failed', response.duration,
        'durationUnavailable');
      return ResponseTestService.result(rule, actual < expected ? 'passed' : 'failed', `${actual} ms`,
        actual < expected ? 'durationMatched' : 'durationMismatch');
    }
    if (rule.kind === 'headerExists' || rule.kind === 'headerEquals') {
      if (rule.target.trim().length === 0) return ResponseTestService.result(rule, 'failed', '',
        'configurationInvalid');
      const header = ResponseTestService.header(response, rule.target);
      if (header === undefined) return ResponseTestService.result(rule, 'failed', '', 'headerMissing');
      if (rule.kind === 'headerExists') return ResponseTestService.result(rule, 'passed', header.value,
        'headerPresent');
      const passed = header.value === rule.expected;
      return ResponseTestService.result(rule, passed ? 'passed' : 'failed', header.value,
        passed ? 'headerMatched' : 'headerMismatch');
    }
    if (rule.target.trim().length === 0) return ResponseTestService.result(rule, 'failed', '',
      'configurationInvalid');
    const evaluated: JsonPathResult = JsonPathService.evaluate(response.body, rule.target);
    if (!evaluated.success) {
      if (evaluated.status === 'invalidJson') return ResponseTestService.result(rule, 'failed', '', 'invalidJson');
      if (evaluated.status === 'invalidPath') return ResponseTestService.result(rule, 'failed', '', 'invalidJsonPath');
      return ResponseTestService.result(rule, 'failed', '', 'jsonPathNoMatch');
    }
    if (rule.kind === 'jsonPathExists') return ResponseTestService.result(rule, 'passed', evaluated.value,
      'jsonPathMatched');
    const passed = evaluated.value === rule.expected;
    return ResponseTestService.result(rule, passed ? 'passed' : 'failed', evaluated.value,
      passed ? 'jsonPathMatched' : 'jsonPathMismatch');
  }

  static run(rules: TestRule[], response: ResponseModel): TestResult[] {
    const enabled = rules.filter((rule: TestRule) => rule.enabled);
    if (enabled.length === 0) return [];
    if (response.status === 'empty' || response.status === 'sending' || response.status === 'error' ||
      response.status === 'cancelled') {
      return enabled.map((rule: TestRule) => ResponseTestService.result(rule, 'notRun', '',
        'responseUnavailable'));
    }
    return enabled.map((rule: TestRule) => ResponseTestService.evaluate(rule, response));
  }
}
