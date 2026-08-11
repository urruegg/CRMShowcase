import { describe, expect, it } from 'vitest';
import { fireEvent, render, screen, within } from '@testing-library/react';
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

  it('selects a lead and shows a demo reassignment note', () => {
    renderCockpit();
    fireEvent.click(screen.getByRole('tab', { name: 'Meine Leads' }));
    fireEvent.click(screen.getByRole('checkbox', { name: 'Lead Frau Keller — Vorsorge 3a auswählen' }));
    expect(screen.getAllByText(/ausgewählt/).length).toBeGreaterThan(0);
    fireEvent.change(screen.getByLabelText('Zuweisen an'), { target: { value: 'Thomas Vogt' } });
    fireEvent.click(screen.getByRole('button', { name: 'Zuweisen' }));
    expect(screen.getByText(/an Thomas Vogt zugewiesen/)).toBeInTheDocument();
  });

  it('opens the Live-Bündelung modal from the Cockpit view and confirms', () => {
    renderCockpit();
    fireEvent.click(screen.getByRole('tab', { name: 'Meine Leads' }));
    fireEvent.click(screen.getByRole('button', { name: 'Cockpit' }));
    fireEvent.click(screen.getAllByRole('button', { name: 'Leads bündeln' })[0]);
    expect(screen.getByText(/Live-Bündelung/)).toBeInTheDocument();
    fireEvent.click(screen.getByRole('button', { name: 'Bündelung bestätigen' }));
    expect(screen.getByText(/gebündelt/)).toBeInTheDocument();
  });

  it('sorts the lead list when a column header is clicked', () => {
    renderCockpit();
    fireEvent.click(screen.getByRole('tab', { name: 'Meine Leads' }));
    const kunde = screen.getByRole('columnheader', { name: /Kunde/ });
    fireEvent.click(within(kunde).getByRole('button'));
    expect(kunde).toHaveAttribute('aria-sort', 'ascending');
  });

  it('shows the three status columns in the Board view', () => {
    renderCockpit();
    fireEvent.click(screen.getByRole('tab', { name: 'Meine Leads' }));
    fireEvent.click(screen.getByRole('button', { name: 'Board' }));
    expect(screen.getByText('Gebündelt / Geplant')).toBeInTheDocument();
    expect(screen.getByText('Karten hierher ziehen, um Status zu ändern')).toBeInTheDocument();
    expect(screen.getByText('Gebündelte Leads bleiben verknüpft')).toBeInTheDocument();
  });

  it('selects a Board card and reveals the reassignment bar', () => {
    renderCockpit();
    fireEvent.click(screen.getByRole('tab', { name: 'Meine Leads' }));
    fireEvent.click(screen.getByRole('button', { name: 'Board' }));
    fireEvent.click(screen.getByRole('checkbox', { name: 'Lead Frau Keller — Vorsorge 3a auswählen' }));
    expect(screen.getAllByText(/ausgewählt/).length).toBeGreaterThan(0);
    expect(screen.getByLabelText('Zuweisen an')).toBeInTheDocument();
  });

  it('splits a bundled group from the Board view', () => {
    renderCockpit();
    fireEvent.click(screen.getByRole('tab', { name: 'Meine Leads' }));
    fireEvent.click(screen.getByRole('button', { name: 'Board' }));
    fireEvent.click(screen.getByRole('button', { name: 'Splitten' }));
    expect(screen.getByText(/aufgelöst/)).toBeInTheDocument();
  });

  it('marks the Fokus-Lead in the Cockpit view', () => {
    renderCockpit();
    fireEvent.click(screen.getByRole('tab', { name: 'Meine Leads' }));
    fireEvent.click(screen.getByRole('button', { name: 'Cockpit' }));
    expect(screen.getAllByText('Fokus-Lead').length).toBeGreaterThan(0);
  });

  it('shows the Cockpit two panes and promotes a queue lead into focus', () => {
    renderCockpit();
    fireEvent.click(screen.getByRole('tab', { name: 'Meine Leads' }));
    fireEvent.click(screen.getByRole('button', { name: 'Cockpit' }));
    expect(screen.getByText('Priorisierte Warteschlange')).toBeInTheDocument();
    expect(screen.getByText('Hausrat-Offerte fortsetzen')).toBeInTheDocument();
    fireEvent.click(screen.getAllByRole('button', { name: 'In Fokus' })[0]);
    expect(screen.getByRole('button', { name: 'Anrufen' })).toBeInTheDocument();
  });

  it('sorts the Offene Fälle grid by a column header', () => {
    renderCockpit();
    fireEvent.click(screen.getByRole('tab', { name: 'Offene Fälle' }));
    const kunde = screen.getByRole('columnheader', { name: /Kunde/ });
    fireEvent.click(within(kunde).getByRole('button'));
    expect(kunde).toHaveAttribute('aria-sort', 'ascending');
  });

  it('creates a Termin via the + Termin action (demo)', () => {
    renderCockpit();
    fireEvent.click(screen.getByRole('tab', { name: 'Termine & Aufgaben' }));
    fireEvent.click(screen.getByRole('button', { name: '+ Termin' }));
    expect(screen.getByText(/Neuen Termin anlegen/)).toBeInTheDocument();
  });

  it('marks non-CRM tiles with a non-colour provenance tag', () => {
    renderCockpit();
    expect(screen.getAllByText('DBX').length).toBeGreaterThan(0);
    expect(screen.getByText('TBD')).toBeInTheDocument();
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
