# MacClip 📋

A native, lightning-fast macOS clipboard history manager inspired by the Windows `Win + V` clipboard experience.

Built with **Swift**, **SwiftUI**, and **AppKit** for Apple Silicon and macOS 13+.

---

## ✨ Features

- **History Retention & Auto-Cleanup 🧹**: Keep storage and memory ultra-lean with configurable history size limits (`50`, `100`, `250`, `500`, `Unlimited`) and age-based auto-cleanup timers (`Never`, `24h`, `7 Days`, `30 Days`). Features live disk usage metrics, periodic background pruning, and a 1-click **"Clean Up Now"** optimization tool (*pinned clips are permanently protected*).
- **Quick Look Interactive Preview (`Space` or `⌘Y`) 🔍**: Instant interactive preview modal for any selected clip! Zoom full-resolution images with dimension badges, inspect hex colors with real-time format conversions (HEX, RGB, HSL), view and clean URLs by stripping tracking parameters (`utm_*`, `fbclid`), view text statistics (characters, words, lines), prettify raw JSON, and apply quick case transforms (UPPERCASE, lowercase, Title Case).
- **Paste as Plain Text (`⇧↵`) 📝**: Hold `Shift` while pressing `Enter` (or click `⇧↵ Plain`) to strip all rich formatting, fonts, inline styles, and web artifacts, pasting pure clean unformatted text directly into your target app.
- **Password Manager Auto-Ignore 🛡️**: Automatically respects your privacy by ignoring clips copied from sensitive password managers (1Password, Bitwarden, Apple Passwords, Keychain, KeePassXC, LastPass) or clips tagged with concealed/transient clipboard markers. Easily toggle on or off in Settings.
- **Launch at Login 🚀**: One-click toggle using native macOS `SMAppService` to automatically start MacClip seamlessly on system login.
- **Customizable Global Hotkey ⌨️**: Record and set **any custom key combination** you prefer (e.g. `⌘⇧C`, `⌃⌥Space`, `⌥⌘V`, `⌘⇧V`, etc.) with interactive live key capture, or choose from popular presets (`⌥V`, `⌘⇧V`, `⌥⌘V`, `⌃V`, `⌥Space`).
  *(Change via the ⚙️ Settings slider in the app or directly from the Menu Bar menu)*.
- **Apple Liquid Glass UI 🪟**: Translucent glass materials, specular border highlights, smooth spring animations, and amber alert glass banners.
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
| **`↑` / `↓`** | Navigate through clips and images (updates Quick Look preview live) |
| **`↵`** (Return) | Paste selected item into active app |
| **`⇧ + ↵`** (Shift + Return) | Paste selected item as **Plain Text** |
| **`Space`** or **`⌘ + Y`** | Open / close **Quick Look Preview** |
| **`Esc`** | Dismiss Quick Look preview or dismiss clipboard popup |
| **Click outside** | Auto-closes popup |

---

<img width="452" height="582" alt="image" src="https://github.com/user-attachments/assets/7aea9ece-370b-4f70-a4df-93ec5c5060d5" />


<img width="444" height="575" alt="image" src="https://github.com/user-attachments/assets/e60e1654-0f84-4a99-b203-81dcc4710cac" />


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
