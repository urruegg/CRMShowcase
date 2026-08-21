import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: './tests/visual',
  outputDir: './TestResults/playwright',
  reporter: 'list',
  fullyParallel: false,
  workers: 1,
  use: {
    baseURL: 'http://127.0.0.1:5173',
    colorScheme: 'light',
    locale: 'de-CH',
    timezoneId: 'Europe/Zurich',
  },
  webServer: {
    command: 'npm run dev --workspace @crmshow/advisor-cockpit-harness -- --host 127.0.0.1',
    url: 'http://127.0.0.1:5173',
    reuseExistingServer: !process.env.CI,
  },
});