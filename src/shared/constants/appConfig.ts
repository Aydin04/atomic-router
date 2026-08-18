import pkg from "../../../package.json" with { type: "json" };

export const APP_CONFIG = {
  name: "AtomicRouter",
  description: "Universal AI Gateway & Proxy for Multi-Provider LLMs",
  version: pkg.version,
};

export const THEME_CONFIG = {
  storageKey: "theme",
  defaultTheme: "system",
};
