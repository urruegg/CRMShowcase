import { describe, expect, it } from 'vitest';
import { fireEvent, render, screen } from '@testing-library/react';
import { FluentProvider, webLightTheme } from '@fluentui/react-components';
import { SalesLeaderDashboard } from './SalesLeaderDashboard';
import { dashboardFixtures } from './fixtures';

function renderDashboard() {
  return render(
    <FluentProvider theme={webLightTheme}>
      <SalesLeaderDashboard data={dashboardFixtures} />
    </FluentProvider>,
  );
}

describe('<SalesLeaderDashboard />', () => {
  it('renders the leadership header and the Führungssicht narrative', () => {
    renderDashboard();
    expect(screen.getByText('Führungsdashboard / Sales Steering')).toBeInTheDocument();
    expect(screen.getByText(/GA-Führung Generalagentur Bern-Mittelland/)).toBeInTheDocument();
    expect(screen.getByText(/Strategisches Lagebild/)).toBeInTheDocument();
  });

  it('binds the GA identity from the profile data (not hardcoded)', () => {
    const custom = { ...dashboardFixtures, profile: { generalAgency: 'Generalagentur Testregion', scopeLabel: 'Testumfang' } };
    render(
      <FluentProvider theme={webLightTheme}>
        <SalesLeaderDashboard data={custom} />
      </FluentProvider>,
    );
    expect(screen.getByText(/GA-Führung Generalagentur Testregion · Testumfang/)).toBeInTheDocument();
  });

  it('shows the four scorecard KPIs sourced from the measure projection', () => {
    renderDashboard();
    expect(screen.getByText('Zielerreichung')).toBeInTheDocument();
    expect(screen.getByText('96 %')).toBeInTheDocument();
    expect(screen.getByText('Wachstum YoY')).toBeInTheDocument();
    expect(screen.getByText('+7.2 %')).toBeInTheDocument();
    expect(screen.getByText('NPS')).toBeInTheDocument();
    expect(screen.getByText('Automatisierung')).toBeInTheDocument();
  });

  it('defaults to the Übersicht tab with the forecast band and strategic radar', () => {
    renderDashboard();
    expect(screen.getByText('Neugeschäft & Prämienvolumen über Zeit')).toBeInTheDocument();
    expect(screen.getByText(/Ziellinie 430/)).toBeInTheDocument();
    expect(screen.getByText('Strategischer Scorecard')).toBeInTheDocument();
  });

  it('switches to Produkte & Regionen and shows both breakdown cards', () => {
    renderDashboard();
    fireEvent.click(screen.getByRole('tab', { name: 'Produkte & Regionen' }));
    expect(screen.getByText('Neugeschäft je Produktlinie')).toBeInTheDocument();
    expect(screen.getByText('Wachstum je Markt / Region (YoY)')).toBeInTheDocument();
  });

  it('switches to the Funnel tab and flags the Kontakt→Qualifiziert bottleneck', () => {
    renderDashboard();
    fireEvent.click(screen.getByRole('tab', { name: 'Funnel' }));
    expect(screen.getByText('Volumen & Conversion je Phase')).toBeInTheDocument();
    expect(screen.getByText('Qualifiziert')).toBeInTheDocument();
    expect(screen.getAllByText(/Engpass/).length).toBeGreaterThan(0);
  });

  it('switches to GA-Vergleich and ranks peer GAs with the current GA marked', () => {
    renderDashboard();
    fireEvent.click(screen.getByRole('tab', { name: 'GA-Vergleich' }));
    expect(screen.getByText('GA-Benchmark & Best-Practice')).toBeInTheDocument();
    expect(screen.getByText('Luzern')).toBeInTheDocument();
    expect(screen.getByText('104%')).toBeInTheDocument();
    expect(screen.getByText(/Ihre GA/)).toBeInTheDocument();
  });

  it('classifies data-source provenance in a legend without per-tile badges', () => {
    renderDashboard();
    expect(screen.getByText(/Measure-Projektion/)).toBeInTheDocument();
    expect(screen.getByText(/noch nicht im Measure-Kontrakt/)).toBeInTheDocument();
    expect(screen.queryByText('DBX')).not.toBeInTheDocument();
    expect(screen.queryByText('TBD')).not.toBeInTheDocument();
  });
});
