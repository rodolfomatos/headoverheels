#!/usr/bin/env python3
"""
Playwright script to analyze the online MSX version of Head over Heels.
Captures gameplay, extracts timing, documents mechanics.
"""
import asyncio
import json
import os
from pathlib import Path
from playwright.async_api import async_playwright

OUTPUT_DIR = Path(__file__).parent / "docs" / "RESEARCH" / "playwright-capture"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

MSX_URL = "https://www.file-hunter.com/Homebrew/?id=headoverheels"

async def analyze_game():
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=False)  # visible for debugging
        context = await browser.new_context(
            viewport={"width": 1280, "height": 720},
            record_video_dir=str(OUTPUT_DIR / "video"),
        )
        page = await context.new_page()
        
        # Enable console logging from page
        page.on("console", lambda msg: print(f"[CONSOLE] {msg.type}: {msg.text}"))
        page.on("pageerror", lambda err: print(f"[PAGE ERROR] {err}"))
        
        print(f"Navigating to {MSX_URL}...")
        await page.goto(MSX_URL, wait_until="networkidle", timeout=60000)
        
        # Wait for emulator to load
        await page.wait_for_timeout(5000)
        
        # Try to find the emulator canvas/iframe
        frames = page.frames
        print(f"Found {len(frames)} frames")
        for i, frame in enumerate(frames):
            print(f"  Frame {i}: {frame.url}")
        
        # The MSX emulator might be in an iframe or canvas
        # Let's explore the DOM
        emulator_info = await page.evaluate("""
            () => {
                const canvases = document.querySelectorAll('canvas');
                const iframes = document.querySelectorAll('iframe');
                const embeds = document.querySelectorAll('embed, object');
                return {
                    canvases: Array.from(canvases).map(c => ({width: c.width, height: c.height, id: c.id, class: c.className})),
                    iframes: Array.from(iframes).map(f => ({src: f.src, width: f.width, height: f.height})),
                    embeds: Array.from(embeds).map(e => ({src: e.src, type: e.type}))
                };
            }
        """)
        print(f"Emulator detection: {json.dumps(emulator_info, indent=2)}")
        
        # If there's a canvas, we can capture frames
        if emulator_info['canvases']:
            canvas = page.locator('canvas').first
            await canvas.screenshot(path=str(OUTPUT_DIR / "emulator-initial.png"))
            print("Captured initial emulator screenshot")
        
        # Try to interact - send key presses to start game
        # Common keys: Space, Enter, arrows
        await page.keyboard.press("Space")
        await page.wait_for_timeout(2000)
        await page.keyboard.press("Enter")
        await page.wait_for_timeout(2000)
        
        # Capture a few frames during attract mode / gameplay
        for i in range(10):
            if emulator_info['canvases']:
                await page.locator('canvas').first.screenshot(
                    path=str(OUTPUT_DIR / f"frame-{i:03d}.png")
                )
            await page.wait_for_timeout(500)
        
        # Try to extract any JavaScript game state if accessible
        game_state = await page.evaluate("""
            () => {
                // Try to find global game/emulator objects
                const globals = {};
                for (const key of Object.keys(window)) {
                    if (key.toLowerCase().includes('game') || 
                        key.toLowerCase().includes('emul') ||
                        key.toLowerCase().includes('msx') ||
                        key.toLowerCase().includes('head')) {
                        globals[key] = typeof window[key];
                    }
                }
                return globals;
            }
        """)
        print(f"Potential game globals: {json.dumps(game_state, indent=2)}")
        
        await context.close()
        await browser.close()
        
        print(f"Output saved to {OUTPUT_DIR}")

if __name__ == "__main__":
    asyncio.run(analyze_game())