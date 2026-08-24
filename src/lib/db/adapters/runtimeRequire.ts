// src/lib/db/adapters/runtimeRequire.ts
/**
 * Load optional database drivers from the runtime rather than bundling them.
 *
 * The standalone server is emitted as CommonJS chunks and externalizes the
 * native database packages. Keep those requests as static `require()` calls so
 * webpack preserves the external boundary. Development and tests run as ESM,
 * where `require` is unavailable; the `createRequire(import.meta.url)` fallback
 * handles those callers.
 */
import { createRequire } from "node:module";

declare const require: NodeRequire | undefined;

function esmRuntimeRequire(specifier: string): unknown {
  try {
    return createRequire(import.meta.url)(specifier);
  } catch {
    return null;
  }
}

export function runtimeRequire(specifier: string): unknown {
  try {
    return esmRuntimeRequire(specifier);
  } catch {
    return null;
  }
}
