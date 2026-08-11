import { describe, expect, it } from 'vitest';
import { render, screen } from '@testing-library/react';
import { FluentProvider, webLightTheme } from '@fluentui/react-components';
import { AdvisorCockpit } from './AdvisorCockpit';
import { cockpitFixtures } from './fixtures';

function renderCockpit() {
  return render(
    <FluentProvider theme={webLightTheme}>
      <AdvisorCockpit data={cockpitFixtures} />
    </FluentProvider>,
  );
}

describe('<AdvisorCockpit />', () => {
  it('greets the advisor and shows the Copilot NBA panel', () => {
    renderCockpit();
    expect(screen.getByText(/Guten Morgen, Rahel Moser/)).toBeInTheDocument();
    expect(screen.getByText('Contoso Copilot')).toBeInTheDocument();
  });

  it('renders the Brunner top lead and its NBA card', () => {
    renderCockpit();
    expect(screen.getAllByText(/Haushalt Brunner/).length).toBeGreaterThan(0);
    expect(screen.getByText(/4h-Fenster läuft/)).toBeInTheDocument();
  });

  it('discloses AI-assisted provenance on every NBA card', () => {
    renderCockpit();
    expect(screen.getAllByText(/KI-unterstützt/).length).toBe(cockpitFixtures.nba.length);
  });
});
