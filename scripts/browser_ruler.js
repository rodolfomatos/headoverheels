// Draws a labelled crosshair at known page coordinates over the running game.
//
// The room-in-the-corner fault produced two numbers that did not fit any
// version of the code: the view reported centring the room at (20, 68) and the
// page showed its corner at (660, 470). Screenshots do not resolve that, because
// nobody can say which pixel a coordinate in a PNG is. A ruler drawn by the
// page, in the page's own coordinates, can: the crosshair sits where the room's
// corner is, or it does not. Used to confirm the camera fix (D002).
//
// Usage: node scripts/browser_ruler.js http://127.0.0.1:8081/ out.png

const { chromium } = require('playwright');
const sleep = ms => new Promise(r => setTimeout(r, ms));
(async () => {
  const browser = await chromium.launch({ args: ['--no-sandbox'] });
  const page = await browser.newPage({ viewport: { width: 1280, height: 800 } });
  await page.goto(process.argv[2] || 'http://127.0.0.1:8081/', { waitUntil: 'load' });
  await sleep(7000);
  await page.mouse.click(640, 700);
  await sleep(2500);
  // A ruler over the Flutter view: known page coordinates, no pixel decoding.
  await page.evaluate(() => {
    const marks = [[640,400,'640,400 centro'],[660,470,'660,470 observado'],
                   [20,68,'20,68 canto do teste'],[10,34,'10,34 meio-escala']];
    for (const [x,y,label] of marks) {
      const d = document.createElement('div');
      d.style.cssText = `position:fixed;left:${x}px;top:${y}px;width:0;height:0;`+
        `border-left:2px solid #ff2d55;border-top:2px solid #ff2d55;z-index:99999;`;
      const t = document.createElement('div');
      t.textContent = label;
      t.style.cssText = `position:fixed;left:${x+4}px;top:${y-14}px;color:#ff2d55;`+
        `font:11px monospace;z-index:99999;background:#000a;padding:1px 3px;`;
      document.body.append(d,t);
    }
  });
  await page.screenshot({ path: process.argv[3] || '/tmp/ruler.png' });
  console.log('done');
  await browser.close();
})();
