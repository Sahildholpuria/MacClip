# MacClip 📋

A native, lightning-fast macOS clipboard history manager inspired by the Windows `Win + V` clipboard experience.

Built with **Swift**, **SwiftUI**, and **AppKit** for Apple Silicon and macOS 13+.

---

## ✨ Features

- **Customizable Global Hotkey**: Summon your clipboard history overlay anytime with your preferred shortcut:
  - `⌥ + V` (Option + V) — *Default*
  - `⌘ + Shift + V` (Command + Shift + V)
  - `⌥ + ⌘ + V` (Option + Command + V)
  - `⌃ + V` (Control + V)
  - `⌥ + Space` (Option + Space)
  *(Change via the ⚙️ Settings gear in the app or directly from the Menu Bar menu)*.
- **Image & Screenshot Support 🖼️**: Automatically records copied images and screenshots (PNG/TIFF) with high-res thumbnail previews, resolution indicators, and file sizes. Selecting an image pastes it directly into supported apps.
- **Direct Auto-Paste**: Selecting a snippet or image immediately pastes it into your previous active app (Safari, VS Code, Slack, Notes, Discord, etc.).
- **Quick Paste (`⌘1` – `⌘9`)**: Press Command + Number to instantly paste any of the top 9 recent items.
- **Live Search & Filter**: Real-time fuzzy search across all text clips and images.
- **Smart Category Detection**: Automatically identifies Images, Links, Hex Colors, Code Snippets, Emails, and Plain Text with visual badges.
- **Pinning**: Pin your most important clips so they never get pruned from history.
- **Persistent Storage**: History and images are preserved across restarts in `~/Library/Application Support/MacClip/`.
- **Menu Bar Accessory**: Clean menu bar item (`📎`) with quick access, shortcut switching, and history clearing.
- **Privacy & Lightweight**: Pure native macOS app with zero external third-party dependencies. Uses < 20MB of RAM and 0% idle CPU.

---

## ⌨️ Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| **`⌥ + V`** *(or your custom hotkey)* | Toggle Clipboard History Popup |
| **`⌘ + 1` .. `⌘ + 9`** | Instantly paste item 1 through 9 |
| **`↑` / `↓`** | Navigate through clips and images |
| **`↵`** (Return) | Paste selected item |
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
4. Once enabled, selecting any clip or image will automatically paste directly into your active cursor position!

*(Even without Accessibility permission, MacClip will still copy the item to your clipboard so you can manually press `⌘V`)*.

---

## 🛠 Building from Source

To rebuild or package updates:

```bash
cd ~/MacClip
./build_app.sh
```
