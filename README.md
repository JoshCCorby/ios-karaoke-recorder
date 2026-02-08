# iOS Karaoke Recorder

A minimal, **correct** reference implementation for simultaneous audio playback and recording on iOS using `AVAudioEngine`.

Build vocal practice and karaoke apps with confidence — no hacks, no workarounds, no lies.

---

## What This Does

✅ Plays a **local backing track** (MP3, WAV, etc.)  
✅ Records **microphone input in real time**  
✅ Handles both simultaneously with a single, stable audio engine  
✅ Survives interruptions (calls, Siri, route changes)  
✅ Stores recordings locally with predictable file naming  
✅ Plays back recorded takes immediately  

---

## What This Doesn't Do

❌ Record system audio (iOS forbids this)  
❌ Integrate with YouTube, Spotify, or Apple Music  
❌ Enable background recording  
❌ Apply effects, pitch correction, or mixing  
❌ Provide workarounds for OS restrictions  

**Why?** iOS audio is sandboxed by design. This project respects those boundaries rather than fight them.

---

## Why This Exists

iOS audio examples tend to be either **too simple to be useful** or **complex and quietly broken**.

This repo is a **reference implementation** that aims for:

- ✔️ Minimal, focused scope
- ✔️ Explicit, documented constraints  
- ✔️ Correct, stable behaviour
- ✔️ Readable, hackable code
- ✔️ Zero third-party audio libraries

If you're building an iOS audio app, this should save you hours of debugging.

---

## Core Architecture

### Audio Engine Setup

- **One `AVAudioEngine`** for both playback and recording
- **One `AVAudioSession`** configured for `.playAndRecord`
- **Shared clock** — mic and speaker stay in sync
- **Input and output nodes** wired to the main mixer

### Recording

- Taps into the input node to capture microphone data
- Records to a PCM buffer in real time
- Writes to local storage with consistent format (44.1 kHz, 16-bit)
- Non-destructive — original backing track is never modified

### Playback

- Loads backing track from a local file
- Plays through the audio engine's output node
- Can run simultaneously with recording
- Survives route changes (headphones ↔ speaker)

---

## Getting Started

### Requirements

- iOS 13+
- Xcode 14+
- Swift 5.5+

### Build & Run

```bash
git clone https://github.com/JoshCCorby/ios-karaoke-recorder.git
cd ios-karaoke-recorder
open ios-karaoke-recorder.xcodeproj
```

Then select your device or simulator and hit **Run** (⌘R).

### Add a Backing Track

1. Drag an MP3 or WAV file into Xcode's file navigator
2. Ensure it's added to the app target
3. Update the filename in the code (see `AudioEngine.swift`)
4. Run the app

---

## How It Works

### 1. Configure the Audio Session

```swift
let session = AVAudioSession.sharedInstance()
try session.setCategory(.playAndRecord, mode: .default, options: [])
try session.setActive(true)
```

This tells iOS: *"I want to play audio AND listen to the mic at the same time."*

### 2. Set Up the Engine

```swift
let engine = AVAudioEngine()
let inputNode = engine.inputNode
let outputNode = engine.outputNode
let mixer = engine.mainMixerNode

// Wire: input → mixer → output
// Wire: file player → mixer → output
```

### 3. Record the Microphone

```swift
let format = inputNode.outputFormat(forBus: 0)!
inputNode.installTap(onBus: 0, bufferSize: 4096, format: format) { buffer, _ in
    // Capture mic data here
}
```

### 4. Play the Backing Track

```swift
let audioFile = try AVAudioFile(forReading: url)
let playerNode = AVAudioPlayerNode()
engine.attach(playerNode)
engine.connect(playerNode, to: mixer, format: format)
playerNode.load(audioFile, audioTime: nil)
try engine.start()
playerNode.play()
```

---

## Platform Constraints (By Design)

iOS enforces strict audio sandboxing:

| What You Want | iOS Says | This Project Says |
|---|---|---|
| Record Spotify | ❌ No | Accept it |
| Tap YouTube audio | ❌ No | Accept it |
| Mix multiple apps | ❌ No | Accept it |
| Access mic + other sources | ✅ Yes | Do this instead |

**Bottom line:** This project works *with* iOS, not against it.

---

## Interruption Handling

The app gracefully handles:

- **Phone calls** — audio session is interrupted, engine pauses
- **Siri activation** — similar pause/resume cycle
- **Headphone insertion** — audio route changes are detected and handled
- **App backgrounding** — audio engine stops cleanly

See `AudioEngine.swift` for the full interrupt handler.

---

## File Structure

```
ios-karaoke-recorder/
├── AudioEngine.swift           # Core AVAudioEngine setup
├── RecordingManager.swift      # Recording logic
├── PlaybackManager.swift       # Playback logic
├── ContentView.swift           # SwiftUI interface
├── AppDelegate.swift           # App lifecycle
└── Assets/
    └── backing-track.wav       # Example backing track
```

---

## Testing

- Test on a **real device** — simulator audio routing is unreliable
- Try headphones and speaker mode
- Trigger a fake call (⌘⇧H in simulator, then call yourself)
- Record a take, then play it back

---

## Known Limitations

- ⚠️ Simulator audio is not reliable — use a real device
- ⚠️ Only one backing track at a time (by design)
- ⚠️ No audio effects or processing (out of scope)
- ⚠️ No cloud sync (out of scope for v1)

---

## Tech Stack

- **Language:** Swift
- **Framework:** AVFoundation (`AVAudioEngine`, `AVAudioSession`, `AVAudioFile`)
- **UI:** SwiftUI
- **Platform:** iOS 13+
- **Dependencies:** None (standard library only)

---

## Project Status

🚀 **Actively maintained**

Current focus:
1. Core audio graph correctness
2. Stable interruption handling
3. Clear, documented code

Future:
- UI polish
- Recording metadata (duration, date, etc.)
- Recording trimming/playback controls

---

## Contributing

Found a bug? Have a suggestion? Issues and PRs are welcome.

Please include:
- iOS version
- Device (iPhone 13, simulator, etc.)
- Steps to reproduce
- Expected vs. actual behaviour

---

## License

MIT License — use this code however you like, for commercial or personal projects.

---

## Useful Resources

- [AVAudioEngine Reference](https://developer.apple.com/documentation/avfoundation/avaudioengine)
- [Configuring Your App's Audio Session](https://developer.apple.com/documentation/avfoundation/avaudiosession)
- [Recording Audio](https://developer.apple.com/documentation/avfoundation/avcapture)
- [Apple's Audio Session Programming Guide](https://developer.apple.com/library/archive/documentation/Audio/Conceptual/AudioSessionProgrammingGuide/)

---

**Questions?** Open an issue or check the code — it's written to be readable.
