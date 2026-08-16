import * as React from 'react';
import { createRoot, Root } from 'react-dom/client';
import { FluentProvider, webLightTheme } from '@fluentui/react-components';
import { SalesLeaderDashboard as SalesLeaderDashboardComponent } from '../../src/SalesLeaderDashboard';
import { dashboardFixtures } from '../../src/fixtures';
import { IInputs, IOutputs } from './generated/ManifestTypes';

// PCF wrap for the already-built, already-tested SalesLeaderDashboard component
// (merged PR #74). Per the local-first polish loop pattern (step 4) and the
// 2026-08-14 scope decision to ship the existing PCF as-is first: this still
// renders the fixture data unchanged. Live Dataverse binding (context.webAPI)
// is deferred to a follow-up polish pass, tracked in ../DATA-BOM.md.
export class SalesLeaderDashboard implements ComponentFramework.StandardControl<IInputs, IOutputs> {
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
                React.createElement(SalesLeaderDashboardComponent, { data: dashboardFixtures }),
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
