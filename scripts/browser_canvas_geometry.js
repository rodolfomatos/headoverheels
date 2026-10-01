// Reports the geometry of the drawing surface a Flutter web build uses.
//
// `document.querySelectorAll('canvas')` returns nothing on a Flutter web page:
// the surface lives inside a shadow root. A `flutter-view` reading is true about
// the host element and silent about the surface, which is how D001 nearly
// recorded a false conclusion — and how the room's misplaced transform was
// blamed on the page for a whole session. This walks every shadow root.
//
// Usage: node scripts/browser_canvas_geometry.js http://127.0.0.1:8081/

const { chromium } = require('playwright');
const sleep = ms => new Promise(r => setTimeout(r, ms));
(async () => {
  const browser = await chromium.launch({ args: ['--no-sandbox'] });
  const page = await browser.newPage({ viewport: { width: 1280, height: 800 } });
  await page.goto(process.argv[2] || 'http://127.0.0.1:8081/', { waitUntil: 'load' });
  await sleep(7000);
  const found = await page.evaluate(() => {
    const out = [];
    const walk = (root, depth) => {
      root.querySelectorAll('*').forEach((el) => {
        if (el.tagName === 'CANVAS') {
          const r = el.getBoundingClientRect();
          out.push({ depth, attrW: el.width, attrH: el.height,
                     cssW: Math.round(r.width), cssH: Math.round(r.height),
                     left: Math.round(r.left), top: Math.round(r.top),
                     parent: el.parentElement ? el.parentElement.tagName : null });
        }
        if (el.shadowRoot) walk(el.shadowRoot, depth + 1);
      });
    };
    walk(document, 0);
    return { canvases: out, dpr: window.devicePixelRatio };
  });
  console.log(JSON.stringify(found, null, 1));
  await browser.close();
})();
