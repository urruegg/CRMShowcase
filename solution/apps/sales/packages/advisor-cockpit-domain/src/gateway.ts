import type { CockpitData, LeadRecord, NbaRecord } from './types';
import type { DataState } from './data-state';

export interface NbaChanges {
  channel?: string;
  rank?: number;
}

export interface CockpitDataGateway {
  load(): Promise<DataState<CockpitData>>;
  updateNbaStatus(id: string, status: 'Accepted' | 'Planned' | 'Dismissed'): Promise<NbaRecord>;
  updateNba(id: string, changes: NbaChanges): Promise<NbaRecord>;
  updateLeadQueueStatus(id: string, status: string): Promise<LeadRecord>;
  setLeadCluster(id: string, clusterId: string | null): Promise<LeadRecord>;
}