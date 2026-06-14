# iOS Karaoke Recorder

A small, honest reference app for vocal practice on iOS: pick a backing track, record your voice over it, and play your takes back. Built entirely on high-level AVFoundation (`AVAudioSession`, `AVAudioRecorder`, `AVAudioPlayer`) — no third-party libraries.

The app target is named **VocalPractice**.

> This README describes what the code actually does today. Where something is stubbed or not yet wired up, it's listed under [Current limitations](#current-limitations) rather than dressed up as a finished feature.

## What it does

- Lets you pick a local audio file as a backing track (via the system file importer)
- Plays the backing track through the speaker, headphones, or Bluetooth
- Records the microphone to an `.m4a` file while the backing track plays
- Saves takes to the app's Documents directory with timestamped filenames
- Lists saved takes and plays them back
- Shows a simple input level meter while recording

## What it does not do

- Capture system audio from Spotify, YouTube, or Apple Music — iOS does not permit this, by design
- Mix, add effects, or apply pitch correction
- Sync recordings to the cloud
- Mix a take against the backing track during review (takes play back on their own)

## How it's built

The app uses the high-level AVFoundation players and recorder rather than `AVAudioEngine`. Recording and playback are handled by separate objects, coordinated from the SwiftUI view.

| File | Responsibility |
| --- | --- |
| `VocalPracticeApp.swift` | `@main` SwiftUI entry point; boots the shared audio session on launch |
| `AudioSessionManager.swift` | Configures `AVAudioSession` for `.playAndRecord`; observes interruption and route-change notifications |
| `RecorderViewModel.swift` | Wraps `AVAudioRecorder`; writes `.m4a` files, runs the level meter, lists saved takes |
| `PlaybackViewModel.swift` | Wraps two `AVAudioPlayer` instances — one for the backing track, one for recorded takes |
| `ContentView.swift` | SwiftUI interface; owns both view models and the record/play controls |
| `Package.swift` | Swift Package manifest |
| `web-preview/` | A standalone web UI preview (Vite + React); not part of the iOS app |

## Requirements

- iOS 16+ (set in `Package.swift`)
- Xcode 15+
- Swift 5.9+

## Getting started

> **Note:** The repo currently ships as a Swift Package with an executable target, which does not produce a runnable iOS app bundle on its own. To run it on a device or simulator you need to add these source files to an Xcode iOS App target with an `Info.plist` (see [Current limitations](#current-limitations)). This is the next thing on the list to fix.

Once it's in an app target:

1. Clone the repo:
   ```bash
   git clone https://github.com/JoshCCorby/ios-karaoke-recorder.git
   ```
2. Add the `.swift` files to your Xcode iOS App target.
3. Add an `NSMicrophoneUsageDescription` entry to the target's `Info.plist`.
4. Build and run on a real device (see [Testing](#testing)).
5. In the app, pick a backing track, then hit record.

## How it works

### 1. Configure the audio session

`AudioSessionManager` sets the category to `.playAndRecord` so the app can play audio and capture the mic at the same time. `.defaultToSpeaker` keeps output on the speaker when no headphones are attached.

```swift
let session = AVAudioSession.sharedInstance()
try session.setCategory(.playAndRecord,
                        mode: .default,
                        options: [.defaultToSpeaker, .allowBluetooth, .allowAirPlay])
try session.setActive(true)
```

### 2. Record the microphone

`RecorderViewModel` records to AAC-encoded `.m4a` in the Documents directory. Metering is enabled so the UI can show input level.

```swift
let settings: [String: Any] = [
    AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
    AVSampleRateKey: 44100.0,
    AVNumberOfChannelsKey: 1,
    AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
]

audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
audioRecorder?.isMeteringEnabled = true
audioRecorder?.record()
```

### 3. Play the backing track

`PlaybackViewModel` loads a chosen file into an `AVAudioPlayer` and plays it. A second player handles recorded takes during review.

```swift
backingTrackPlayer = try AVAudioPlayer(contentsOf: url)
backingTrackPlayer?.prepareToPlay()
backingTrackPlayer?.play()
```

### 4. Record while playing

In `ContentView`, the record button starts recording and starts the backing track together, so your take is captured over the music. Because the session is `.playAndRecord`, both can run at once.

## iOS audio constraints

iOS sandboxes audio: an app can access its own microphone and play its own audio, but it cannot tap the output of other apps. That means there is no supported way to record Spotify, YouTube, or Apple Music. This app works within those boundaries rather than around them.

One practical consequence: when the backing track plays through the **speaker**, the microphone will pick it up and it will bleed into your recording. For a clean vocal take, **use headphones**.

## Testing

- Test on a real device — simulator microphone and routing behaviour is unreliable.
- Try both headphones and speaker output.
- Record a take, then play it back from the list.
- Trigger a phone call or Siri to observe interruption behaviour (see limitations — auto-pause/resume isn't implemented yet).

## Current limitations

These are real gaps in the current code, not design choices:

- **No runnable app target.** The project is a SwiftPM executable target with no `Info.plist`; it needs an Xcode iOS App target before it will build and run as an app.
- **Microphone permission is not requested.** There's no `requestRecordPermission` call and no `NSMicrophoneUsageDescription`. On a real app, recording will fail until both are added.
- **Interruptions are logged, not handled.** `AudioSessionManager` observes interruption and route-change notifications but only prints them — it does not pause or resume the recorder or player.
- **Take timing is approximate.** Recording and backing-track playback are started back-to-back from the view, not locked to a shared clock, so they are not sample-accurately aligned.
- **No headphone-unplug handling.** Route changes are detected but not acted on.

## Roadmap

- Add an Xcode iOS App target and `Info.plist`
- Request microphone permission on first record
- Pause/resume cleanly on interruptions and react to route changes
- Recording metadata (duration, date) and trim/playback controls

## License

MIT — see [LICENSE](LICENSE).
