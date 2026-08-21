import { expect, test } from '@playwright/test';

for (const viewport of [
  { name: 'desktop', width: 1440, height: 1000 },
  { name: 'mobile', width: 390, height: 844 },
]) {
  test(`fixture harness ${viewport.name}`, async ({ page }) => {
    await page.setViewportSize(viewport);
    await page.clock.setFixedTime(new Date('2026-08-20T09:00:00+02:00'));
    await page.goto('/');
    await expect(page.getByText('Arbeitsvorrat & persönliche Ziele')).toBeVisible();
    const pageWidth = await page.evaluate(() => ({
      client: document.documentElement.clientWidth,
      scroll: document.documentElement.scrollWidth,
    }));
    expect(pageWidth.scroll).toBeLessThanOrEqual(pageWidth.client);
    if (viewport.name === 'mobile') {
      const heroHeading = page.getByRole('heading', { name: 'Mehr Zeit für vorbereitete Kundengespräche' });
      expect((await heroHeading.boundingBox())?.width ?? 0).toBeGreaterThan(250);
    }
    await expect(page).toHaveScreenshot(`advisor-cockpit-${viewport.name}.png`, {
      fullPage: true,
      animations: 'disabled',
    });
  });
}