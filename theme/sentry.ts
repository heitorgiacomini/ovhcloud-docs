import * as Sentry from '@sentry/react';

declare const SENTRY_DSN: string | undefined;
declare const SENTRY_ENVIRONMENT: string | undefined;

let initialized = false;

export function initSentry() {
  if (initialized || !SENTRY_DSN) return;
  initialized = true;

  Sentry.init({
    dsn: SENTRY_DSN,
    environment: SENTRY_ENVIRONMENT || 'production',
    integrations: [Sentry.browserTracingIntegration()],
    tracesSampleRate: 1.0,
  });
}
