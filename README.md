# MacClip 📋

A native, lightning-fast macOS clipboard history manager inspired by the Windows `Win + V` clipboard experience.

Built with **Swift**, **SwiftUI**, and **AppKit** for Apple Silicon and macOS 13+.

---

## ✨ Features

- **Global Hotkey (`⌥ + V` / Option + V)**: Press anywhere on your Mac to summon your clipboard history overlay.
- **Direct Auto-Paste**: Selecting a snippet immediately pastes it into your previous active app (Safari, VS Code, Notes, Slack, etc.).
- **Quick Paste (`⌘1` – `⌘9`)**: Press Command + Number to instantly paste any of the top 9 recent clips.
- **Live Search & Filter**: Real-time fuzzy search across all your saved clips.
- **Smart Category Detection**: Automatically identifies Links, Hex Colors, Code Snippets, Emails, and Plain Text with visual badges.
- **Pinning**: Pin your most important clips so they never get pruned from history.
- **Persistent Storage**: History is preserved across restarts in `~/Library/Application Support/MacClip/history.json`.
- **Menu Bar Accessory**: Clean menu bar item (`📎`) with quick access, status, and unpinned history clearing.
- **Privacy & Lightweight**: Pure native macOS app with zero external third-party dependencies. Uses < 15MB of RAM and 0% idle CPU.

---

## ⌨️ Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| **`⌥ + V`** (Option + V) | Toggle Clipboard History Popup |
| **`⌘ + 1` .. `⌘ + 9`** | Instantly paste clip 1 through 9 |
| **`↑` / `↓`** | Navigate through clips |
| **`↵`** (Return) | Paste selected clip |
| **`Esc`** | Dismiss clipboard popup |
| **Click outside** | Auto-closes popup |

---

## 🚀 How to Launch

The app is already compiled and installed in your `~/Applications` folder.

### Launch via Terminal:
```bash
open ~/Applications/MacClip.app
```

Or open **Finder > Applications** (or Spotlight `⌘ Space`), search for **MacClip**, and press Enter.

---

## 🔒 Granting Accessibility Permission (for Auto-Paste)

In macOS, security requires that any app simulating keystrokes into other apps (typing `⌘V` for you) must have Accessibility permission:

1. When you first open MacClip or click **"Grant"** in the top banner, macOS will show a permission prompt.
2. If prompted, open **System Settings > Privacy & Security > Accessibility**.
3. Toggle the switch next to **MacClip** to **ON**.
4. Once enabled, selecting any clip will automatically paste directly into your active cursor position!

*(Even without Accessibility permission, MacClip will still copy the item to your clipboard so you can manually press `⌘V`)*.

---

## 🛠 Building from Source

To rebuild or package updates:

```bash
cd ~/MacClip
./build_app.sh
```

This compiles the release binary and packages `MacClip.app` inside `~/MacClip/build/`.
