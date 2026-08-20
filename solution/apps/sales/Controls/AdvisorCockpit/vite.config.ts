import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';

const here = dirname(fileURLToPath(import.meta.url));
// Repo root is six levels up: Controls/AdvisorCockpit -> Controls -> sales -> apps -> solution -> repo
const repoRoot = resolve(here, '../../../../../..');

export default defineConfig({
  // Pin the root to this control folder so the dev server is independent of the cwd it is launched from.
  root: here,
  plugins: [react()],
  base: './',
  server: {
    port: 5173,
    // Allow importing the shared synthetic fixtures under data/scenarios from outside this control folder.
    fs: { allow: [repoRoot] },
  },
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: ['./src/test-setup.ts'],
    alias: {
      tabster: resolve(here, '../../node_modules/tabster/dist/esm/index.js'),
    },
    server: {
      deps: {
        inline: [
          /@crmshow\/advisor-cockpit-(domain|ui)/,
          /@fluentui\//,
        ],
      },
    },
  },
});
