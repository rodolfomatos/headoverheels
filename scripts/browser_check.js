#!/usr/bin/env node
// Drives a built web game in a real browser and leaves a capture behind.
//
// It does not judge what the game looks like. It opens the build, gets to the
// game, waits for the load, screenshots it, and prints the console and the
// timings, so "it draws" can be counted from the PNG by
// scripts/browser_pixels.py rather than believed from a picture.
//
//   node scripts/browser_check.js <build-dir> <name> [route] [settle-ms] [port]

const { chromium } = require('playwright');
const http = require('http');
const fs = require('fs');
const path = require('path');

const root = process.argv[2];
const name = process.argv[3] || 'shot';
const click = process.argv[4] || '';   // "x,y" into the page
const settleMs = Number(process.argv[5] || 25000);
const port = Number(process.argv[6] || 8099);

const TYPES = {
  '.html': 'text/html', '.js': 'text/javascript', '.mjs': 'text/javascript',
  '.json': 'application/json', '.png': 'image/png', '.jpg': 'image/jpeg',
  '.svg': 'image/svg+xml', '.wasm': 'application/wasm', '.otf': 'font/otf',
  '.ttf': 'font/ttf', '.woff2': 'font/woff2', '.bin': 'application/octet-stream',
  '.wav': 'audio/wav', '.ico': 'image/x-icon', '.map': 'application/json',
  '.symbols': 'text/plain', '.frag': 'text/plain', '.bin.json': 'application/json',
};

function serve() {
  return new Promise((resolve) => {
    const server = http.createServer((req, res) => {
      const url = decodeURIComponent(req.url.split('?')[0]);
      let file = path.join(root, url === '/' ? '/index.html' : url);
      if (!fs.existsSync(file) || fs.statSync(file).isDirectory()) {
        file = path.join(root, 'index.html');
      }
      res.writeHead(200, {
        'Content-Type': TYPES[path.extname(file)] || 'application/octet-stream',
      });
      fs.createReadStream(file).pipe(res);
    });
    server.listen(port, () => resolve(server));
  });
}

(async () => {
  const server = await serve();
  const browser = await chromium.launch({
    args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'],
  });
  const page = await browser.newPage({ viewport: { width: 1280, height: 800 } });
  const log = [];
  page.on('console', (m) => log.push(m.type() + ': ' + m.text().slice(0, 200)));
  page.on('pageerror', (e) => log.push('pageerror: ' + e.message.slice(0, 200)));
  const requests = [];
  page.on('response', (r) => requests.push([r.status(), r.url()]));

  const report = { build: root, name, click, steps: [] };
  const started = Date.now();
  try {
    fs.mkdirSync('build/browser', { recursive: true });
    await page.goto(`http://localhost:${port}/`, { waitUntil: 'load', timeout: 90000 });
    await page.waitForTimeout(5000);
    await page.screenshot({ path: `build/browser/${name}_menu.png` });
    report.steps.push(`menu after ${Date.now() - started}ms`);

    if (click) {
      // Flutter paints into a canvas, so there is nothing in the DOM to click:
      // a menu is reached by clicking coordinates, and the coordinates are
      // found by looking at the capture the step above took.
      const [cx, cy] = click.split(',').map(Number);
      await page.mouse.click(cx, cy);
      report.steps.push(`clicked ${cx},${cy} at ${Date.now() - started}ms`);
    }


    // Flutter paints into a canvas, so the page has no text to read until the
    // accessibility tree is switched on. That tree is the only way to tell
    // "the room is loading" from "the room is a flat colour" from a script.
    // Flutter web puts an invisible button in the corner; a real click on it is
    // what turns the semantics tree on.
    const ph = page.locator('flt-semantics-placeholder').first();
    if (await ph.count().catch(() => 0)) {
      await ph.click({ force: true, timeout: 5000 }).catch((e) => report.semClick = String(e).slice(0, 120));
    }
    await page.waitForTimeout(2000);
    report.semantics = await page.evaluate(`(() => {
      const labels = [];
      const walk = (root) => {
        for (const el of root.querySelectorAll('*')) {
          const a = el.getAttribute && el.getAttribute('aria-label');
          if (a) labels.push(a);
          if (el.shadowRoot) walk(el.shadowRoot);
        }
      };
      walk(document);
      return labels.slice(0, 40);
    })()`).catch((e) => ['semantics failed: ' + e]);

    // An optional drag on the touch controls, once the game is up, so a frame
    // before and a frame after a movement can be told apart. "x,y,dx,dy".
    const drag = process.env.DRAG;
    if (drag) {
      const [dx0, dy0, ddx, ddy] = drag.split(',').map(Number);
      await page.waitForTimeout(Number(process.env.DRAG_AFTER || 12000));
      await page.mouse.move(dx0, dy0);
      await page.mouse.down();
      await page.mouse.move(dx0 + ddx, dy0 + ddy, { steps: 5 });
      report.steps.push(`holding the control at ${dx0},${dy0} -> `
        + `${dx0 + ddx},${dy0 + ddy} at ${Date.now() - started}ms`);
    }

    // Take a capture every two seconds so "the room was never there" and "the
    // room arrived at 30 seconds" are different pictures rather than a claim.
    let firstBusy = null;
    const shots = [];
    for (let waited = 0; waited <= settleMs; waited += 2000) {
      if (waited > 0) await page.waitForTimeout(2000);
      const file = `build/browser/${name}_${String(waited).padStart(5, '0')}.png`;
      await page.screenshot({ path: file });
      shots.push(file);
    }
    if (drag) {
      await page.mouse.up();
      report.steps.push(`released at ${Date.now() - started}ms`);
    }
    report.steps.push(`captured ${shots.length} frames over ${settleMs}ms`);
    report.frames = shots;
    report.notFound = requests.filter(([s]) => s >= 400);
    report.assetCount = requests.length;
    report.urls = requests.map(([, u]) => u.replace(/^http:\/\/[^/]+/, '')).slice(0, 80);
  } catch (e) {
    report.error = String(e).slice(0, 400);
  }
  report.totalMs = Date.now() - started;
  report.console = log.filter((l) => !l.startsWith('debug:')).slice(0, 40);
  report.all = log.slice(0, 60);
  console.log(JSON.stringify(report, null, 2));
  await browser.close();
  server.close();
})();
