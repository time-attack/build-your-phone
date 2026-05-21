<div align="center">

# build-your-phone

### iOS skills for [GStack](https://github.com/garrytan/gstack) — the missing half of Garry Tan's AI coding setup.

**🏆 1st Place — YC GStack × GBrain Hackathon · May 16, 2026 · San Francisco**

*Hosted by Y Combinator with [HogAi](https://thehog.ai), [Transpose VC](https://transposevc.com), [AskJo](https://askjo.ai), and [GBrain](https://gbrain.io). Prize: a YC interview and a 1:1 working session with [Garry Tan](https://x.com/garrytan).*

---

*"Build and ship something real in 12 hours."*

</div>

## The story

GStack is incredibly powerful. It's Garry Tan's exact Claude Code setup — 23 skills that turn the model into a CEO, a designer, an engineering manager, a QA tester. It is **excellent** at the web. It is **silent** about iOS.

Before the hackathon I asked Garry directly if iOS was something he was interested in for GStack. He couldn't give me a solid answer since he was not a big iOS developer.


I went anyway. I'd been writing SwiftUI long enough to know exactly what was missing: there is no headless browser for a phone. You can't `curl` a SwiftUI button. The accessibility tree is locked inside the device. Every existing iOS automation tool — XCUITest, IDB, Appium — assumes a human is the one writing the test, not an LLM staring at a screenshot deciding what to do next.

So I built the missing half. Five skills that give a Claude agent the same grip on an iPhone that `/browse` gives it on a website: source-aware, vision-driven, fully closed-loop. Read the app's Swift code → generate a debug bridge inside the binary → drive the running app over USB → screenshot, tap, verify, fix, repeat.

When Garry called my name for first place at the hackathon I was shocked that I won since I was not too confident about its value haha

---

## What it is

**`build-your-phone`** is a collection of five GStack-compatible skills that extend Claude Code with first-class iOS development capability. Drop them next to your existing GStack skills and your agent suddenly knows how to QA, fix, redesign, and resync a SwiftUI app running on a real iPhone or in the Simulator — with zero human intervention.

| Skill | What it does |
|---|---|
| **[`/ios-qa`](./ios-qa)** | Reads your Swift source, generates an embedded HTTP debug bridge into your app, builds, deploys, then runs a vision-driven agent loop — *screenshot → identify → decide → tap → verify → repeat* — to systematically find bugs. Works on a real device over USB (CoreDevice IPv6 tunnel) **or** in the Simulator (via `idb` + a custom 4ms Swift tap binary). |
| **[`/ios-fix`](./ios-fix)** | Takes a bug from `/ios-qa`, reads the source to understand *why* it broke, writes the minimal fix, rebuilds, redeploys, then reproduces the original repro steps on the device to prove the bug is gone. Find → fix → verify. The loop is closed. |
| **[`/ios-sync`](./ios-sync)** | Wipes and regenerates all `DebugBridgeGenerated/` files — fresh action keys for every `@Observable` ViewModel function in your app. Run this whenever you add a new button, screen, or ViewModel. |
| **[`/ios-clean`](./ios-clean)** | Surgically removes every trace of the debug bridge — `StateServer`, `DebugOverlay`, all accessors, all `#if DEBUG` wiring in `ContentView` and `App` files. Ship-ready in one command. |
| **[`/ios-design-review`](./ios-design-review)** | Visual audit. Walks every screen, screenshots each one, and evaluates against Apple HIG, your project's `DESIGN.md`, spacing, typography, contrast, and accessibility — then files a report with annotated evidence. |

---

## Why this is hard (and why nothing else does it)

A web browser is a gift to LLM agents. The DOM is text. `document.querySelector` is a function call. Chrome DevTools Protocol is an HTTP server. An LLM can read what's on the page, decide what to do, and act — all in the same language.

An iPhone is the opposite. The screen is pixels. The widgets are SwiftUI views compiled into a sandboxed binary. The OS doesn't expose the view hierarchy. Accessibility labels exist but you can't query them from outside the app. Even the existing tools fight you:

- **XCUITest** is for humans writing scripted tests, not agents making decisions.
- **`idb`** can see the accessibility tree on Simulator but is blind on real devices, and its taps are 150ms+ HID events.
- **WebDriver / Appium** is too heavy and too brittle for an agent loop.

`build-your-phone` solves this by **injecting the API directly into the app**:

```
┌─────────────────────────────────────────────────────────────┐
│  Claude Code  (the agent)                                   │
│                                                              │
│  ┌────────── DEVICE MODE ──────────┐  ┌── SIMULATOR ──┐    │
│  │  curl -6 http://[IPv6]:9999/*   │  │  sim_tap (4ms) │    │
│  │  via CoreDevice USB tunnel       │  │  idb fallback  │    │
│  └─────────────┬───────────────────┘  └────────┬───────┘    │
└────────────────┼─────────────────────────────────┼──────────┘
                 │                                 │
       ┌─────────▼─────────────────────────────────▼─────────┐
       │  YOUR SwiftUI APP (running on real iPhone or Sim)   │
       │                                                      │
       │  ┌────────────────────────────────────────────────┐ │
       │  │  DebugBridgeGenerated/  (injected by /ios-qa)  │ │
       │  │                                                 │ │
       │  │  • StateServer.swift   — embedded HTTP server  │ │
       │  │  • DebugOverlay.swift  — visualizes taps        │ │
       │  │  • <VM>Accessor.swift  — one per @Observable   │ │
       │  │  • action keys for every ViewModel function    │ │
       │  └────────────────────────────────────────────────┘ │
       │                                                      │
       │  Endpoints:                                          │
       │    GET  /screenshot   → base64 PNG                  │
       │    GET  /elements     → accessibility tree (JSON)   │
       │    POST /tap          → inject tap at {x,y}         │
       │    POST /type         → keyboard input              │
       │    POST /swipe        → gesture                     │
       │    GET  /state/{key}  → read @Observable property   │
       │    POST /state/{key}  → invoke ViewModel func       │
       │    GET  /health       → liveness                    │
       └──────────────────────────────────────────────────────┘
```

Everything is `#if DEBUG`. Release builds contain none of it. `/ios-clean` removes the last trace in one command.

---

## The trick: action keys

SwiftUI toolbar buttons (`.toolbar { Button("Save") {...} }`) **cannot be tapped programmatically**. They wrap in `UIKitBarItemHost`. `accessibilityActivate()` returns `true` and does nothing. `sendActions(.touchUpInside)` does nothing. The private `_targets` API crashes the app. There is no working tap. This is a SwiftUI architectural limitation, not a bug.

I lost two hours to this during the hackathon before I figured out the fix: **don't tap the button — call the ViewModel function directly.**

For every `func` on every `@Observable` ViewModel, `/ios-qa` generates an *action key* — a debug-only HTTP endpoint that invokes the function natively:

```swift
// For: func toggleUnit()
server.registerWrite("ProfileVM_toggleUnit") { _ in
    instance.toggleUnit()
    return true
}

// For: func addItem(_ item: Item) — JSON injection
server.registerWrite("CartVM_addItem") { value in
    let item = try! JSONDecoder().decode(Item.self, from: value.data(using: .utf8)!)
    instance.addItem(item)
    return true
}
```

The agent gets a complete, programmatic mirror of every state mutation the UI could ever cause — **instant, never-fails, no tap targeting required**. Taps are reserved for testing the taps themselves (navigation, focus, button existence).

This single insight turned a 20-minute QA run with seven mid-test rebuilds into a 4-minute run with zero rebuilds.

---

## Quick start

### 1. Install the skills

Drop the five directories into `~/.claude/skills/` alongside your other GStack skills:

```bash
git clone https://github.com/time-attack/build-your-phone.git
cp -R build-your-phone/ios-* ~/.claude/skills/
```

### 2. Prereqs

- macOS with Xcode 16+
- A SwiftUI app using `@Observable` ViewModels (iOS 17+)
- For device mode: an iPhone connected over USB (CoreDevice — *not* iproxy)
- For simulator mode: `brew install idb-companion && pip3 install fb-idb`

### 3. Run

```
/ios-qa
```

That's it. The skill auto-detects whether a real device is connected or whether to use the Simulator, reads your Swift source, generates the debug bridge, builds, deploys, runs through a vision-driven test plan covering every screen, and produces a structured bug report with evidence.

Then:

```
/ios-fix
```

…to actually fix what it found. Reproduction → fix → verification, all on-device, all without you touching anything.

---

## Modes

### Device Mode (real iPhone over USB)

Built around Apple's **CoreDevice tunnel** — the IPv6 USB transport that replaced `usbmuxd`. The `StateServer` listens on `:9999` inside the app. Claude talks to it via:

```bash
curl -6 "http://[fdac:e671:bcd7::1]:9999/elements"
```

The brackets and `-6` are non-negotiable. `iproxy` does *not* work with CoreDevice and actively interferes — kill it.

### Simulator Mode

No debug bridge, no rebuild. Uses `idb` for the accessibility tree and a hand-rolled Swift binary (`sim_tap`, compiled on first run) that drives the Simulator via the macOS Accessibility API for **4ms taps** vs IDB's 150ms. Real HID events visible on screen — perfect for live demos.

Both modes share the same agent loop. Both are exposed under a single `/ios-qa` invocation. The skill picks the right one for you.

### Demo Mode

Say *"demo"* or *"show me"* and the agent stops cheating. Every action goes through the UI — tap the +, tap the field, type the name, tap Save. Screenshots between actions. Narration. Bug callouts. Speed does not matter; visual impact does. This is the mode that won the hackathon.

### Rapid Mode

Say *"rapid"* or *"speed run"*. Sonnet for everything, batched state reads, no narration, no screenshots except for evidence. Optimized purely for time-to-bug.

---

## What's in the box

```
build-your-phone/
├── ios-qa/                  # The big one — read source, build bridge, find bugs
│   ├── SKILL.md
│   ├── templates/           # StateServer, DebugOverlay, accessor templates
│   └── demo-app-prompt.md   # Reference SwiftUI app to QA against
│
├── ios-fix/                 # Autonomous fixer — closes the loop
│   ├── SKILL.md.tmpl
│   └── demo-app-prompt.md
│
├── ios-sync/                # Resync templates + regenerate all action keys
│   └── SKILL.md
│
├── ios-clean/               # Strip every trace of the debug bridge
│   └── SKILL.md
│
└── ios-design-review/       # Visual audit against HIG / DESIGN.md
    └── SKILL.md
```

---

## A note on Garry's answer

He said he didn't know enough to give a good answer. He was being honest. iOS isn't his thing — the web is.

But the bet underneath GStack is bigger than the web. The bet is that if you give an LLM the right primitives — a typed read of the world and a typed write of the world — it will out-engineer most humans on most tasks. The web already had those primitives (the DOM, fetch, the URL bar). The phone didn't. So I built them.

12 hours later, first place. Thanks for the prize, Garry. See you at the working session.

---

## Sources & links

- [GStack × GBrain Hackathon — Y Combinator](https://events.ycombinator.com/GStack)
- [Y Combinator on X — hackathon announcement](https://x.com/ycombinator/status/2051754739831026114)
- [garrytan/gstack — the original 23 skills](https://github.com/garrytan/gstack)
- [Inside Garry Tan's AI Coding Setup — YC Startup Library](https://www.ycombinator.com/library/OW-inside-garry-tan-s-ai-coding-setup)
- [GBrain — persistent memory for AI agents](https://gbrain.io)

---

<div align="center">

**Built in 12 hours · Won 1st place · Now ships as your iOS agent.**

</div>
