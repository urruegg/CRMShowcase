import * as React from 'react';
import { createRoot } from 'react-dom/client';
import { FluentProvider, webLightTheme } from '@fluentui/react-components';
import { AdvisorCockpit } from '@crmshow/advisor-cockpit-ui';
import { cockpitFixtures } from '../src/fixtures';

createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <FluentProvider theme={webLightTheme}>
      <AdvisorCockpit data={cockpitFixtures} />
    </FluentProvider>
  </React.StrictMode>,
);
