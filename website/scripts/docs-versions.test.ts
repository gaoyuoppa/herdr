import { describe, expect, test } from 'bun:test';
import {
  buffersEqualModuloCheckoutLineEndings,
  normalizeVersion,
  sortVersionsNewestFirst,
} from './docs-versions.mjs';

describe('normalizeVersion', () => {
  test.each([
    ['0.7.5', '0.7.5'],
    ['v0.7.5', '0.7.5'],
  ])('normalizes %s', (input, expected) => {
    expect(normalizeVersion(input)).toBe(expected);
  });

  test('rejects non-release refs', () => {
    expect(() => normalizeVersion('preview-123')).toThrow();
  });
});

describe('sortVersionsNewestFirst', () => {
  test('sorts semantic versions numerically', () => {
    const versions = [
      { version: '0.6.10' },
      { version: '0.7.2' },
      { version: '0.7.10' },
      { version: '0.5.12' },
    ];

    expect(sortVersionsNewestFirst(versions).map(({ version }) => version)).toEqual([
      '0.7.10',
      '0.7.2',
      '0.6.10',
      '0.5.12',
    ]);
  });
});

describe('buffersEqualModuloCheckoutLineEndings', () => {
  test('accepts CRLF working-tree text that matches an LF git blob', () => {
    expect(
      buffersEqualModuloCheckoutLineEndings(
        Buffer.from('first\r\nsecond\r\n'),
        Buffer.from('first\nsecond\n'),
      ),
    ).toBe(true);
  });

  test('still rejects semantic content changes', () => {
    expect(
      buffersEqualModuloCheckoutLineEndings(
        Buffer.from('first\r\nchanged\r\n'),
        Buffer.from('first\nsecond\n'),
      ),
    ).toBe(false);
  });
});
