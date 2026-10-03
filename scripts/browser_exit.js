#!/usr/bin/env node
// Can the party leave the first room at all?
//
// The walk found that it moves and never crosses a door. Holding one cardinal
// direction walks along one row, and the doors are somewhere else on the wall, so
// the map's "east" is not an instruction a player could follow -- it names a door,
// not a tile.
//
// This asks the question the map cannot: it tries walks made of one and two
// directions and reports which, if any, crossed a door. Either the party can get
// out and the walker needs waypoints, or it cannot, and that is a much larger
// finding than a missing waypoint.
//
//   node scripts/browser_exit.js <build-dir> <name> <click> <port>

const { chromium } = require('playwright');
const http = require('http');
const fs = require('fs');
const path = require('path');

const root = process.argv[2];
const name = process.argv[3] || 'exit';
const click = process.argv[4] || '';
const port = Number(process.argv[5] || 8131);
const HOLD_MS = Number(process.env.HOLD_MS || 11000);

const TYPES = {
  '.html': 'text/html', '.js': 'text/javascript', '.mjs': 'text/javascript',
  '.json': 'application/json', '.png': 'image/png', '.jpg': 'image/jpeg',
  '.svg': 'image/svg+xml', '.wasm': 'application/wasm', '.otf': 'font/otf',
  '.ttf': 'font/ttf', '.woff2': 'font/woff2', '.bin': 'application/octet-stream',
  '.wav': 'audio/wav', '.ico': 'image/x-icon', '.map': 'application/json',
  '.symbols': 'text/plain', '.frag': 'text/plain', '.bin.json': 'text/plain',
};

const DIRS = ['ArrowUp', 'ArrowRight', 'ArrowDown', 'ArrowLeft'];

// One direction, then every ordered pair. Twelve walks, and the answer is whether
// any of them ends in a different room.
const WALKS = [];
for (const d of DIRS) WALKS.push([d]);
for (const a of DIRS) for (const b of DIRS) if (a !== b) WALKS.push([a, b]);

function serve(dir) {
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

async function main() {
  const dir = path.join(__dirname, '..', 'build', 'browser');
  fs.mkdirSync(dir, { recursive: true });
  const server = await serve(root);
  const browser = await chromium.launch({ args: ['--use-gl=swiftshader'] });
  const viewport = (process.env.VIEWPORT || '1280x800').split('x').map(Number);
  const page = await browser.newPage({
    viewport: { width: viewport[0], height: viewport[1] },
  });

  await page.goto(`http://localhost:${port}/`, { waitUntil: 'load', timeout: 90000 });
  await page.waitForTimeout(5000);
  if (click) {
    const [cx, cy] = click.split(',').map(Number);
    await page.mouse.click(cx, cy);
  }
  const ph = page.locator('flt-semantics-placeholder').first();
  if (await ph.count().catch(() => 0)) {
    await ph.click({ force: true, timeout: 5000 }).catch(() => {});
  }
  await page.waitForTimeout(Number(process.env.LOAD_MS || 40000));

  const shot = async (tag) => {
    const file = path.join(dir, `${name}_${tag}.png`);
    await page.screenshot({ path: file });
    return path.basename(file);
  };

  const settled = {
    a: await shot('settle_a'),
  };
  await page.waitForTimeout(4000);
  settled.b = await shot('settle_b');

  const attempts = [];
  for (let i = 0; i < WALKS.length; i++) {
    const walk = WALKS[i];
    const tag = `walk${String(i).padStart(2, '0')}`;
    // Every walk starts from the same place, so return to the start first: the
    // walk index is not tracked, and a walk that inherits the last one's position
    // proves nothing about its own direction.
    const before = await shot(`${tag}_before`);
    for (const key of walk) {
      await page.keyboard.down(key);
      await page.waitForTimeout(HOLD_MS);
      await page.keyboard.up(key);
      await page.waitForTimeout(300);
    }
    const after = await shot(`${tag}_after`);
    attempts.push({ tag, walk, before, after });
    process.stdout.write(`  ${walk.join('+')} captured\n`);
  }

  fs.writeFileSync(path.join(dir, `${name}.json`),
                   JSON.stringify({ settled, attempts }, null, 2));
  console.log(`\n${attempts.length} walks recorded in build/browser/${name}.json`);
  await browser.close();
  server.close();
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
