import { describe, expect, it } from 'vitest';
import { fireEvent, render, screen } from '@testing-library/react';
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
  it('greets the advisor and shows the Fokus-heute hero', () => {
    renderCockpit();
    expect(screen.getByText(/Guten Morgen, Rahel Moser/)).toBeInTheDocument();
    expect(screen.getByText('Mehr Zeit für vorbereitete Kundengespräche')).toBeInTheDocument();
  });

  it('binds the header identity from the advisor context data (not hardcoded)', () => {
    const custom = {
      ...cockpitFixtures,
      advisor: { fullName: 'Test Advisor', role: 'Kundenberater', generalAgency: 'GA Testregion' },
    };
    render(
      <FluentProvider theme={webLightTheme}>
        <AdvisorCockpit data={custom} />
      </FluentProvider>,
    );
    expect(screen.getByText(/Guten Morgen, Test Advisor/)).toBeInTheDocument();
    expect(screen.getByText(/Kundenberater · GA Testregion/)).toBeInTheDocument();
  });

  it('renders the Arbeitsvorrat KPI grid', () => {
    renderCockpit();
    expect(screen.getByText('Arbeitsvorrat & persönliche Ziele')).toBeInTheDocument();
    expect(screen.getByText('Leads heute kontaktieren')).toBeInTheDocument();
    expect(screen.getByText('Neugeschäftsvolumen (Q2)')).toBeInTheDocument();
  });

  it('shows the Empfohlener Fokus recommendation for Brunner on the default Tagesplan tab', () => {
    renderCockpit();
    expect(screen.getByText(/Empfohlener Fokus/)).toBeInTheDocument();
    expect(screen.getByText(/Warum jetzt:/)).toBeInTheDocument();
    expect(screen.getByText('Woher stammt das?')).toBeInTheDocument();
    expect(screen.getAllByText(/KI-unterstützt/).length).toBeGreaterThan(0);
  });

  it('lists the Brunner lead cluster under the Meine Leads tab', () => {
    renderCockpit();
    fireEvent.click(screen.getByRole('tab', { name: 'Meine Leads' }));
    expect(screen.getAllByText(/Haushalt Brunner/).length).toBeGreaterThan(0);
    expect(screen.getByText('Hausrat-Offerte fortsetzen')).toBeInTheDocument();
  });

  it('switches Meine Leads between Liste, Board and Cockpit views', () => {
    renderCockpit();
    fireEvent.click(screen.getByRole('tab', { name: 'Meine Leads' }));
    expect(screen.getByText('Hausrat-Offerte fortsetzen')).toBeInTheDocument();
    fireEvent.click(screen.getByRole('button', { name: 'Board' }));
    expect(screen.getAllByText(/Haushalt Brunner/).length).toBeGreaterThan(0);
    fireEvent.click(screen.getByRole('button', { name: 'Cockpit' }));
    expect(screen.getAllByText('Leads bündeln').length).toBeGreaterThan(0);
  });

  it('filters the lead list by customer', () => {
    renderCockpit();
    fireEvent.click(screen.getByRole('tab', { name: 'Meine Leads' }));
    fireEvent.change(screen.getByLabelText('Kunde / Konto'), { target: { value: 'Stucki' } });
    expect(screen.getByText('Bäckerei Stucki — Betriebshaftpflicht')).toBeInTheDocument();
    expect(screen.queryByText('Hausrat-Offerte fortsetzen')).not.toBeInTheDocument();
  });

  it('reveals the full NBA list with a disclosure on every card under the Copilot tab', () => {
    renderCockpit();
    fireEvent.click(screen.getByRole('tab', { name: 'Copilot' }));
    expect(screen.getByText(/4h-Fenster läuft/)).toBeInTheDocument();
    expect(screen.getAllByText(/KI-unterstützt/).length).toBe(cockpitFixtures.nba.length);
  });

  it('shows Anliegen & Schäden under the Offene Fälle tab', () => {
    renderCockpit();
    fireEvent.click(screen.getByRole('tab', { name: 'Offene Fälle' }));
    expect(screen.getByText('SCH-77310')).toBeInTheDocument();
    expect(screen.getByText('Adressänderung')).toBeInTheDocument();
  });
});
