import { describe, expect, it } from 'vitest';
import { act, fireEvent, render, screen, within } from '@testing-library/react';
import { FluentProvider, webLightTheme } from '@fluentui/react-components';
import {
  writeCapabilities,
  type AdvisorCockpitHost,
  type CockpitWriteCommand,
  type CommandResult,
} from '@crmshow/advisor-cockpit-domain';
import { AdvisorCockpit } from '@crmshow/advisor-cockpit-ui';
import { cockpitFixtures } from './fixtures';

const blockedHost: AdvisorCockpitHost = {
  context: {
    hostKind: 'fixture-harness',
    appId: null,
    environmentId: null,
    sessionId: null,
    userObjectId: null,
    locale: 'de-CH',
  },
  capability: (command: CockpitWriteCommand['type']) => writeCapabilities[command],
  execute: async () => ({ ok: false, message: 'Fixture writes are disabled.' }),
  navigate: async () => undefined,
};

function renderCockpit(host: AdvisorCockpitHost = blockedHost) {
  return render(
    <FluentProvider theme={webLightTheme}>
      <AdvisorCockpit data={cockpitFixtures} host={host} />
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
        <AdvisorCockpit data={custom} host={blockedHost} />
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

  it('keeps blocked lead assignment focusable and explains the limitation', () => {
    renderCockpit();
    fireEvent.click(screen.getByRole('tab', { name: 'Meine Leads' }));
    fireEvent.click(screen.getByRole('checkbox', { name: 'Lead Frau Keller — Vorsorge 3a auswählen' }));
    expect(screen.getAllByText(/ausgewählt/).length).toBeGreaterThan(0);
    fireEvent.change(screen.getByLabelText('Zuweisen an'), { target: { value: 'Thomas Vogt' } });
    const assign = screen.getByRole('button', { name: 'Zuweisen' });
    expect(assign).toHaveAttribute('aria-disabled', 'true');
    expect(assign).toHaveAttribute('tabindex', '0');
    expect(assign).toHaveAccessibleDescription(/polymorphic owner lookup/i);
  });

  it('opens the Live-Bündelung modal but explains its unverified write', () => {
    renderCockpit();
    fireEvent.click(screen.getByRole('tab', { name: 'Meine Leads' }));
    fireEvent.click(screen.getByRole('button', { name: 'Cockpit' }));
    fireEvent.click(screen.getAllByRole('button', { name: 'Leads bündeln' })[0]);
    expect(screen.getByText(/Live-Bündelung/)).toBeInTheDocument();
    expect(screen.queryByText(/DEV-gated|Demonstration/i)).not.toBeInTheDocument();
    const confirm = screen.getByRole('button', { name: 'Bündelung bestätigen' });
    expect(confirm).toHaveAttribute('aria-disabled', 'true');
    expect(confirm).toHaveAccessibleDescription(/lookup association/i);
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
    expect(screen.getByText('Karten hierher ziehen, um Status zu ändern')).toHaveAccessibleDescription(/generated-service update/i);
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

  it('keeps unverified cluster splitting visible and explained', () => {
    renderCockpit();
    fireEvent.click(screen.getByRole('tab', { name: 'Meine Leads' }));
    fireEvent.click(screen.getByRole('button', { name: 'Board' }));
    const split = screen.getByRole('button', { name: 'Splitten' });
    expect(split).toHaveAttribute('aria-disabled', 'true');
    expect(split).toHaveAccessibleDescription(/lookup disassociation/i);
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

  it('keeps blocked appointment creation visible and explained', () => {
    renderCockpit();
    fireEvent.click(screen.getByRole('tab', { name: 'Termine & Aufgaben' }));
    const createAppointment = screen.getByRole('button', { name: '+ Termin' });
    expect(createAppointment).toHaveAttribute('aria-disabled', 'true');
    expect(createAppointment).toHaveAccessibleDescription(/regarding relationship is polymorphic/i);
  });

  it('announces command success only after the host promise resolves', async () => {
    let resolveCommand!: (result: CommandResult) => void;
    const host: AdvisorCockpitHost = {
      ...blockedHost,
      execute: () => new Promise((resolve) => {
        resolveCommand = resolve;
      }),
    };
    renderCockpit(host);
    fireEvent.click(screen.getByRole('tab', { name: 'Meine Leads' }));
    fireEvent.click(screen.getByRole('button', { name: 'Cockpit' }));

    fireEvent.click(screen.getByRole('button', { name: 'Anrufen' }));
    expect(screen.getByRole('status')).not.toHaveTextContent('Call launched.');

    await act(async () => resolveCommand({ ok: true, message: 'Call launched.' }));
    expect(screen.getByRole('status')).toHaveTextContent('Call launched.');
  });

  it('does not silently accept an NBA when the advisor starts a call', async () => {
    const commands: CockpitWriteCommand[] = [];
    const host: AdvisorCockpitHost = {
      ...blockedHost,
      capability: (command) => command === 'acceptNba'
        ? { availability: 'supported', reason: 'Verified.', target: 'crmshow_nextbestaction.crmshow_status' }
        : writeCapabilities[command],
      execute: async (command) => {
        commands.push(command);
        return { ok: true, message: `${command.type} completed.` };
      },
    };
    renderCockpit(host);
    fireEvent.click(screen.getByRole('tab', { name: 'Meine Leads' }));
    fireEvent.click(screen.getByRole('button', { name: 'Cockpit' }));

    await act(async () => {
      fireEvent.click(screen.getByRole('button', { name: 'Anrufen' }));
    });

    expect(commands.map((command) => command.type)).toEqual(['call']);
  });

  it('does not claim meeting preparation opened when no preparation surface exists', () => {
    renderCockpit();
    fireEvent.click(screen.getByRole('button', { name: 'Vorbereiten' }));
    expect(screen.getByRole('status')).toHaveTextContent('Gesprächsvorbereitung ist in diesem Host nicht verfügbar.');
  });

  it('conveys data-source provenance without per-tile badges', () => {
    renderCockpit();
    expect(screen.queryByText('DBX')).not.toBeInTheDocument();
    expect(screen.queryByText('TBD')).not.toBeInTheDocument();
    // provenance stays available via the persistent legend
    expect(screen.getByText('Databricks (Mock)')).toBeInTheDocument();
    expect(screen.getByText('Noch nicht gemappt')).toBeInTheDocument();
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
