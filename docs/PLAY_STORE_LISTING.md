# Play Store Listing — Head over Heels

## App Information

**Package Name:** `com.ambrosio.headoverheels`
**Version:** 1.0.0 (1)
**Category:** Game — Puzzle
**Content Rating:** Everyone 10+ (Fantasy Violence)

---

## Short Description (80 chars max)

Classic 1987 isometric puzzle-platformer reimagined for Android. Dual-character mechanics!

---

## Full Description (4000 chars max)

**Head over Heels** brings the legendary 1987 isometric puzzle-platformer to Android with modern touch controls, enhanced visuals, and the complete original adventure.

### THE CLASSIC REIMAGINED
Originally released on ZX Spectrum, Commodore 64, and Amstrad CPC, Head over Heels was a masterpiece of British game design. Now experience it on your phone with controls built for touchscreens.

### DUAL-CHARACTER GAMEPLAY
Control **Head** and **Heels** — two distinct characters with unique abilities:
- **Head**: High jumps (2 tiles), slow walk, fires doughnuts
- **Heels**: Fast walk (4 tiles), carries items, low jump
- **Combined**: Head rides on Heels' shoulders — best of both!

Press **SWOP** to switch characters instantly. Solve puzzles by combining their abilities.

### 5 PLANETS, 21 ROOMS
Explore the complete original world:
- **Blacktooth Castle** — Medieval fortress with guards and secrets
- **Egyptus** — Ancient pyramids with traps and treasures
- **Penitentiary** — High-security prison with conveyors
- **Safari** — Jungle ruins with wild beasts
- **Book World** — Library labyrinth leading to the final showdown

### PUZZLE MECHANICS
- **Switches & Doors** — Activate switches to open paths
- **Conveyors** — Ride or fight moving floors
- **Springs** — Bounce to new heights
- **Reincarnation Fish** — Eat to create checkpoints, avoid dead ones!
- **Crowns** — Collect all 5 to defeat Blacktooth
- **Doughnuts** — Head's projectile weapon to freeze monsters
- **Bags & Keys** — Heels carries items to unlock doors
- **Hush Puppies** — Temporary monster freeze
- **Monsters & Guardians** — Patrol patterns to learn and avoid

### MODERN FEATURES
- **Touch Controls** — Virtual joystick + action buttons designed for phones
- **Adaptive Music** — Unique soundtrack per planet
- **Auto-Save** — Progress saved at every reincarnation fish
- **Haptic Feedback** — Feel every jump, hit, and pickup
- **Accessibility** — Adjustable text size, colorblind modes, control customization
- **Landscape & Portrait** — Play however you hold your device

### NO ADS, NO IAP, NO INTERNET REQUIRED
Pure single-player experience. No microtransactions. No forced online. Just you and the puzzle.

---

## Keywords (for ASO)

head over heels, isometric, puzzle, platformer, retro, classic, zx spectrum, 1987, dual character, ambrosio, blacktooth, crown, doughnut, heels, head

---

## Screenshots Required

### Phone Screenshots (1080×1920 or 1080×2340)
1. **Main Menu** — Clean Material 3 UI with Continue/New Game
2. **Gameplay — Castle** — Head in starting room, HUD visible
3. **Gameplay — Egyptus** — Pyramid interior with conveyor
4. **Character Swop** — Split screen showing Head/Heels transition
5. **Combined Mode** — Head riding Heels, both visible
6. **Boss Room** — Blacktooth Throne room with guardian
7. **Pause Menu** — Settings, Audio, Accessibility options

### Tablet Screenshots (1920×1200)
1. **Landscape Gameplay** — Full room view on tablet
2. **Split Controls** — Joystick left, buttons right

### Feature Graphic (1024×500)
- Title logo centered
- Head and Heels characters flanking
- "Classic 1987 Puzzle-Platformer" tagline
- Android/Google Play branding

### App Icon (512×512)
- Modern vector rendition of Head character
- Distinctive silhouette, works at small sizes
- Consistent with Material Design icon guidelines

---

## Privacy Policy

**Data Collected:** None
- No personal data collected
- No analytics/tracking
- No network requests
- All data stored locally (SharedPreferences for audio settings only)

**Permissions:**
- `INTERNET` — Not used (reserved for future leaderboards)
- `ACCESS_NETWORK_STATE` — Not used
- `WAKE_LOCK` — Keeps screen on during gameplay

---

## Release Checklist

- [x] App signed with release keystore
- [x] ProGuard/R8 enabled with rules
- [x] Obfuscation enabled
- [x] Debug info split for crash reporting
- [x] Version code/name in pubspec.yaml
- [x] App icon (512×512) in mipmap folders
- [x] Adaptive icon (foreground + background)
- [x] Round icon for supported launchers
- [x] Strings.xml with app_name
- [x] Backup rules configured
- [x] Data extraction rules configured
- [x] AndroidManifest.xml hardened (tools:replace, exported activities)
- [x] Network security config (cleartext disabled)
- [x] ProGuard rules for Flutter, Riverpod, Freezed, Flame, JustAudio
- [x] No debuggable=true in release
- [x] Min SDK 21 (Android 5.0)
- [x] Target SDK 34 (Android 14)
- [x] 64-bit ABIs (arm64-v8a, x86_64)

---

## Build Commands

```bash
# Build App Bundle for Play Store
make build-release-appbundle

# Build APK for testing/sideloading
make build-release-apk

# Build both
make build-release-all

# Install on connected device
make install
```

Output locations:
- App Bundle: `build/app/outputs/bundle/release/app-release.aab`
- APK: `build/app/outputs/apk/release/app-release.apk`
- Debug symbols: `build/debug_info/`

---

## Post-Launch

1. **Monitor** crash reports via Play Console
2. **Respond** to user reviews within 48 hours
3. **Update** version code in pubspec.yaml for each release
4. **Consider** adding leaderboards (requires INTERNET permission)
5. **Plan** content updates: speedrun mode, level editor, new planets