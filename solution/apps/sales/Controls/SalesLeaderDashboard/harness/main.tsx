import * as React from 'react';
import { createRoot } from 'react-dom/client';
import { FluentProvider, webLightTheme } from '@fluentui/react-components';
import { SalesLeaderDashboard } from '../src/SalesLeaderDashboard';
import { dashboardFixtures } from '../src/fixtures';

createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <FluentProvider theme={webLightTheme}>
      <SalesLeaderDashboard data={dashboardFixtures} />
    </FluentProvider>
  </React.StrictMode>,
);
