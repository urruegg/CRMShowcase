import * as React from 'react';
import { createRoot, Root } from 'react-dom/client';
import { FluentProvider, webLightTheme } from '@fluentui/react-components';
import { AdvisorCockpit as AdvisorCockpitComponent } from '@crmshow/advisor-cockpit-ui';
import { cockpitFixtures } from '../../src/fixtures';
import { createFixtureHost } from '../../src/fixtureHost';
import { IInputs, IOutputs } from './generated/ManifestTypes';

const fixtureHost = createFixtureHost('pcf-artifact');

// PCF wrap for the already-built, already-tested AdvisorCockpit component
// (merged PR #70). Per the local-first polish loop pattern (step 4) and the
// 2026-08-14 scope decision to ship the existing PCF as-is first: this still
// renders the fixture data unchanged. Live Dataverse binding (context.webAPI)
// is deferred to a follow-up polish pass, tracked in ../DATA-BOM.md.
export class AdvisorCockpit implements ComponentFramework.StandardControl<IInputs, IOutputs> {
    private root!: Root;

    public init(
        _context: ComponentFramework.Context<IInputs>,
        _notifyOutputChanged: () => void,
        _state: ComponentFramework.Dictionary,
        container: HTMLDivElement
    ): void {
        this.root = createRoot(container);
        this.renderControl();
    }

    public updateView(_context: ComponentFramework.Context<IInputs>): void {
        this.renderControl();
    }

    private renderControl(): void {
        this.root.render(
            React.createElement(
                FluentProvider,
                { theme: webLightTheme },
                React.createElement(AdvisorCockpitComponent, { data: cockpitFixtures, host: fixtureHost }),
            ),
        );
    }

    public getOutputs(): IOutputs {
        return {};
    }

    public destroy(): void {
        this.root.unmount();
    }
}
