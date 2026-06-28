const maxSafeInteger = BigInt(Number.MAX_SAFE_INTEGER);
const minSafeInteger = BigInt(Number.MIN_SAFE_INTEGER);

function isPlainObject(value: unknown): value is Record<string, unknown> {
  if (value === null || typeof value !== 'object') return false;
  const prototype = Object.getPrototypeOf(value);
  return prototype === Object.prototype || prototype === null;
}

function normalizeBigInt(value: bigint): number | string {
  if (value <= maxSafeInteger && value >= minSafeInteger) {
    return Number(value);
  }
  return value.toString();
}

export function serializeJsonResponse<T>(value: T): T {
  if (typeof value === 'bigint') {
    return normalizeBigInt(value) as T;
  }

  if (Array.isArray(value)) {
    return value.map((item) => serializeJsonResponse(item)) as T;
  }

  if (value instanceof Date || value instanceof Uint8Array) {
    return value;
  }

  if (value && typeof value === 'object') {
    if (!isPlainObject(value) && typeof (value as { toJSON?: () => unknown }).toJSON === 'function') {
      const serializable = value as unknown as { toJSON: () => unknown };
      return serializeJsonResponse(serializable.toJSON()) as T;
    }

    const entries = Object.entries(value as Record<string, unknown>).map(([key, entryValue]) => [
      key,
      serializeJsonResponse(entryValue),
    ]);
    return Object.fromEntries(entries) as T;
  }

  return value;
}
