#!/usr/bin/env node
// How fast does this build actually render, and under which flags?
//
// T095 concluded the game runs at about one frame per second under software GL,
// from counting distinct screenshots. That was a proxy, and it was a guess in the
// end: the number came from sampling once a second and seeing eleven distinct
// frames out of twelve, which cannot tell one frame a second from sixty.
//
// This measures the thing directly. Flutter web schedules through
// `requestAnimationFrame`, so counting rAF callbacks is counting rendered frames,
// with no sampling and no inference.
//
//   node scripts/browser_fps.js <build-dir>

const { chromium } = require('playwright');
const http = require('http');
const fs = require('fs');
const path = require('path');

const root = process.argv[2];
const WINDOW_MS = Number(process.env.WINDOW_MS || 8000);
const LOAD_MS = Number(process.env.LOAD_MS || 20000);
const CLICK = process.env.CLICK || '638,363';

const CONFIGS = [
  {
    name: 'angle/swiftshader 1280x800  (what verify-browser uses)',
    args: '--use-gl=angle --use-angle=swiftshader --enable-unsafe-swiftshader',
    viewport: '1280x800',
  },
  {
    name: 'angle/swiftshader  640x400  (a quarter of the pixels)',
    args: '--use-gl=angle --use-angle=swiftshader --enable-unsafe-swiftshader',
    viewport: '640x400',
  },
  {
    name: 'plain swiftshader 1280x800  (what browser_walk used)',
    args: '--use-gl=swiftshader',
    viewport: '1280x800',
  },
  {
    name: 'headless default  1280x800  (no GL flags at all)',
    args: '',
    viewport: '1280x800',
  },
  {
    name: 'angle/swiftshader  960x600',
    args: '--use-gl=angle --use-angle=swiftshader --enable-unsafe-swiftshader',
    viewport: '960x600',
  },
];

const TYPES = {
  '.html': 'text/html', '.js': 'text/javascript', '.mjs': 'text/javascript',
  '.json': 'application/json', '.png': 'image/png', '.jpg': 'image/jpeg',
  '.svg': 'image/svg+xml', '.wasm': 'application/wasm', '.otf': 'font/otf',
  '.ttf': 'font/ttf', '.woff2': 'font/woff2', '.bin': 'application/octet-stream',
  '.wav': 'audio/wav', '.ico': 'image/x-icon', '.map': 'application/json',
  '.symbols': 'text/plain', '.frag': 'text/plain', '.bin.json': 'text/plain',
};

function serve(dir, port) {
  return new Promise((resolve) => {
    const server = http.createServer((req, res) => {
      const rel = decodeURIComponent(req.url.split('?')[0]);
      let file = path.join(dir, rel === '/' ? 'index.html' : rel);
      if (!fs.existsSync(file) || fs.statSync(file).isDirectory()) {
        res.writeHead(404);
        res.end('not found');
        return;
      }
      res.writeHead(200, {
        'Content-Type': TYPES[path.extname(file)] || 'application/octet-stream',
      });
      fs.createReadStream(file).pipe(res);
    });
    server.listen(port, () => resolve(server));
  });
}

async function measure(config, port) {
  const server = await serve(root, port);
  const args = config.args ? config.args.split(' ') : [];
  const browser = await chromium.launch({ args });
  const [w, h] = config.viewport.split('x').map(Number);
  const page = await browser.newPage({ viewport: { width: w, height: h } });

  // Count every rAF the page runs. Flutter web schedules its frames through this,
  // so this is the renderer's own count of frames it drew.
  await page.addInitScript(() => {
    window.__frames = 0;
    const native = window.requestAnimationFrame.bind(window);
    window.requestAnimationFrame = (cb) =>
      native((t) => {
        window.__frames++;
        return cb(t);
      });
  });

  await page.goto(`http://localhost:${port}/`, { waitUntil: 'load', timeout: 90000 });
  await page.waitForTimeout(5000);
  const [cx, cy] = CLICK.split(',').map(Number);
  await page.mouse.click(cx, cy);
  const ph = page.locator('flt-semantics-placeholder').first();
  if (await ph.count().catch(() => 0)) {
    await ph.click({ force: true, timeout: 5000 }).catch(() => {});
  }
  await page.waitForTimeout(LOAD_MS);

  const start = await page.evaluate(() => window.__frames);
  await page.waitForTimeout(WINDOW_MS);
  const end = await page.evaluate(() => window.__frames);
  const loaded = await page.evaluate(
    () => !!document.querySelector('flt-scene, flt-canvas, canvas'));

  await browser.close();
  server.close();
  return { frames: end - start, fps: (end - start) / (WINDOW_MS / 1000), loaded };
}

async function main() {
  console.log(`measuring ${WINDOW_MS / 1000}s of rendered frames per config\n`);
  const rows = [];
  let port = 8160;
  for (const config of CONFIGS) {
    let result;
    try {
      result = await measure(config, port++);
    } catch (error) {
      rows.push({ name: config.name, fps: null, note: String(error).slice(0, 70) });
      console.log(`  ${config.name}: failed -- ${String(error).slice(0, 70)}`);
      continue;
    }
    rows.push(result);
    console.log(`  ${result.fps.toFixed(1).padStart(6)} fps  `
      + `(${String(result.frames).padStart(5)} frames, `
      + `${config.viewport})  ${config.name}`);
  }

  const good = rows.filter((r) => r.fps && r.fps >= 10)
    .sort((a, b) => b.fps - a.fps);
  console.log();
  if (!good.length) {
    console.log('No configuration reached ten frames a second.');
    console.log('A walk across a planet is not reachable here at any of these');
    console.log('settings, and T095 stands with a number attached to it.');
    process.exit(2);
  }
  console.log(`Fast enough to walk the game: ${good[0].name} at `
    + `${good[0].fps.toFixed(1)} fps.`);
  console.log(`GL_ARGS="${good[0].configArgs || ''}" VIEWPORT=${good[0].viewport}`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});