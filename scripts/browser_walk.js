#!/usr/bin/env node
// Walks Head over Heels through its own map, in a real browser.
//
// This is the only thing in the repository that plays the game. Everything else
// counts pixels or queries a component tree, and `make check` was green through a
// party that vanished on every door.
//
// The walk is adaptive rather than a fixed key list, because the next direction
// depends on where the party is: `castle_hall` has no north exit, so holding north
// there walks into a wall and a list of keys cannot tell that from a broken door.
//
// Navigation is by the game's own map -- `world.json`, the file the game loads --
// so the plan says where the doors are meant to be, and the pixels say whether
// they are there. Disagreement is the finding.
//
// It records what it *believes* it visited. Whether the belief is true is
// `scripts/browser_walk.py`'s job, and it decides from the captures.
//
//   node scripts/browser_walk.js <build-dir> <name> <click> <port>

const { chromium } = require('playwright');
const http = require('http');
const fs = require('fs');
const path = require('path');

const root = process.argv[2];
const name = process.argv[3] || 'walk';
const click = process.argv[4] || '';
const port = Number(process.argv[5] || 8121);

const MAP = path.join(__dirname, '..', 'games', 'headoverheels', 'assets',
                      'levels', 'world.json');

// How long to hold a key before giving up on it, and how often to look while
// holding. Polling matters: a door is reached long before fourteen seconds, and
// walking into a wall for the rest of it teaches us nothing.
const HOLD_MS = Number(process.env.HOLD_MS || 12000);
const POLL_MS = Number(process.env.POLL_MS || 1200);

const KEYS = {
  north: 'ArrowUp', south: 'ArrowDown',
  east: 'ArrowRight', west: 'ArrowLeft',
  up: 'ArrowUp', down: 'ArrowDown',
};
const REVERSE = {
  north: 'south', south: 'north', east: 'west', west: 'east',
  up: 'down', down: 'up',
};

const TYPES = {
  '.html': 'text/html', '.js': 'text/javascript', '.mjs': 'text/javascript',
  '.json': 'application/json', '.png': 'image/png', '.jpg': 'image/jpeg',
  '.svg': 'image/svg+xml', '.wasm': 'application/wasm', '.otf': 'font/otf',
  '.ttf': 'font/ttf', '.woff2': 'font/woff2', '.bin': 'application/octet-stream',
  '.wav': 'audio/wav', '.ico': 'image/x-icon', '.map': 'application/json',
  '.symbols': 'text/plain', '.frag': 'text/plain', '.bin.json': 'text/plain',
};

function serve(dir) {
  return new Promise((resolve) => {
    const server = http.createServer((req, res) => {
      const rel = decodeURIComponent(req.url.split('?')[0]);
      let file = path.join(dir, rel === '/' ? 'index.html' : rel);
      if (!fs.existsSync(file) || fs.statSync(file).isDirectory()) {
        if (fs.existsSync(path.join(file, 'index.html'))) {
          file = path.join(file, 'index.html');
        } else {
          res.writeHead(404);
          res.end('not found');
          return;
        }
      }
      res.writeHead(200, {
        'Content-Type': TYPES[path.extname(file)] || 'application/octet-stream',
      });
      fs.createReadStream(file).pipe(res);
    });
    server.listen(port, () => resolve(server));
  });
}

/** The rooms reachable from the start, and the hops that visit all of them. */
function plan(world) {
  const rooms = world.rooms;
  const seen = new Set([world.startRoom]);
  const routes = { [world.startRoom]: [] };
  const queue = [world.startRoom];
  while (queue.length) {
    const id = queue.shift();
    for (const exit of rooms[id].exits) {
      if (exit.isLocked) continue;
      if (!rooms[exit.room] || seen.has(exit.room)) continue;
      seen.add(exit.room);
      routes[exit.room] = routes[id].concat([{ from: id, direction: exit.direction }]);
      queue.push(exit.room);
    }
  }

  // An Euler tour of the spanning tree: down to every child, back up between
  // them. A plain list of unvisited targets cannot work, because the next hop
  // depends on where the party is standing, and after one hop it is not where the
  // next route starts. Computed, not guessed.
  const sequence = [];
  const visit = (id) => {
    for (const exit of rooms[id].exits) {
      if (exit.isLocked) continue;
      const child = exit.room;
      if (!rooms[child] || !routes[child]) continue;
      if (routes[child].length !== routes[id].length + 1) continue;
      sequence.push({ from: id, direction: exit.direction, to: child, away: true });
      visit(child);
      const back = rooms[child].exits.find(
        (e) => !e.isLocked && e.room === id);
      if (back) {
        sequence.push({ from: child, direction: back.direction, to: id, away: false });
      }
    }
  };
  visit(world.startRoom);

  return { reachable: [...seen].sort(), sequence };
}

async function main() {
  const world = JSON.parse(fs.readFileSync(MAP, 'utf8'));
  const { reachable, sequence } = plan(world);
  const dir = path.join(__dirname, '..', 'build', 'browser');
  fs.mkdirSync(dir, { recursive: true });

  const server = await serve(root);
  const browser = await chromium.launch({ args: ['--use-gl=swiftshader'] });
  // The same viewport browser_check.js uses, and the same one the click
  // coordinates were found in. At 1000x720 the click that starts the game lands
  // somewhere else, the game never starts, and every key does nothing -- which is
  // what twenty hops of 0.00% looked like.
  const viewport = (process.env.VIEWPORT || '1280x800').split('x').map(Number);
  const page = await browser.newPage({
    viewport: { width: viewport[0], height: viewport[1] },
  });
  const errors = [];
  page.on('console', (m) => {
    if (m.type() === 'error') errors.push(m.text());
  });
  page.on('pageerror', (e) => errors.push(String(e)));

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
  // Long enough for the world to arrive before the first step.
  await page.waitForTimeout(Number(process.env.LOAD_MS || 14000));

  const shot = async (tag) => {
    const file = path.join(dir, `${name}_${tag}.png`);
    await page.screenshot({ path: file });
    return path.basename(file);
  };

  /** Holds a key for a while and captures the frame either side.
   *
   * No screenshots while the key is down. Polling every two seconds meant one
   * screenshot per poll during the hold, and the party did not move a single
   * pixel across twenty hops -- screenshotting a Flutter canvas repeatedly is
   * expensive enough to starve the game's frames. The early exit was a nice idea
   * and it cost the entire walk.
   */
  const hold = async (key, tag) => {
    const before = await shot(`${tag}_before`);
    await page.keyboard.down(key);
    await page.waitForTimeout(HOLD_MS);
    await page.keyboard.up(key);
    await page.waitForTimeout(400);
    const settled = await shot(`${tag}_after`);
    return { before, settled, heldMs: HOLD_MS };
  };

  // Wait for the room to stop arriving.
  //
  // Without this the very first "hold a key and see a fifth of the frame change"
  // is the room loading, not a door. It reported OK for that reason once, which is
  // the worst kind of green: a gate that passed while proving nothing.
  const settle = async (tag) => {
    const a = await shot(`settle_${tag}_a`);
    await page.waitForTimeout(Number(process.env.SETTLE_MS || 4000));
    const b = await shot(`settle_${tag}_b`);
    return { a, b };
  };
  const settled = await settle('start');

  const walk = [];
  let current = world.startRoom;
  let step = 0;

  for (const hop of sequence) {
    const tag = `hop${String(step++).padStart(2, '0')}`;
    const result = await hold(KEYS[hop.direction], tag);
    walk.push({ tag, from: hop.from, direction: hop.direction, to: hop.to,
                away: hop.away, ...result });
    current = hop.to;
  }

  const visited = [world.startRoom];
  for (const hop of walk) {
    if (!visited.includes(hop.to)) visited.push(hop.to);
  }

  fs.writeFileSync(path.join(dir, `${name}.json`), JSON.stringify({
    start: world.startRoom,
    settled,
    reachable,
    sequence: sequence.length,
    visited,
    walk,
    errors: errors.slice(0, 10),
  }, null, 2));

  console.log(`planned ${reachable.length} reachable rooms`);
  console.log(`walked ${walk.filter((w) => !w.skipped).length} hops`);
  console.log(`recorded ${walk.length} steps in build/browser/${name}.json`);

  await browser.close();
  server.close();
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});