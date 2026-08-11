import '@testing-library/jest-dom/vitest';

// Recharts' ResponsiveContainer relies on ResizeObserver, which jsdom does not
// implement. Provide a no-op so chart-bearing components render in tests.
class ResizeObserverStub {
  observe(): void {}
  unobserve(): void {}
  disconnect(): void {}
}
globalThis.ResizeObserver = globalThis.ResizeObserver ?? (ResizeObserverStub as unknown as typeof ResizeObserver);
