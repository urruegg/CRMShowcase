import type { ProvenanceKind } from './provenance';

export interface DataStateMetadata {
  provenance: Readonly<Record<string, ProvenanceKind>>;
  unmappedFields: readonly string[];
}

export type DataState<T> =
  | { status: 'ready'; data: T; metadata: DataStateMetadata }
  | { status: 'empty'; message: string }
  | { status: 'denied'; region: string; message: string }
  | { status: 'error'; region: string; message: string }
  | { status: 'unsupported'; region: string; message: string }
  | { status: 'unmapped'; data: T; metadata: DataStateMetadata; message: string };