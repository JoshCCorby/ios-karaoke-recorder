import Foundation

/// Pure, side-effect-free time formatting shared by the UI and covered by unit tests.
enum TimeFormatting {
    /// Formats a duration as `mm:ss`. Negative or non-finite values clamp to `00:00`.
    static func minutesSeconds(_ time: TimeInterval) -> String {
        guard time.isFinite, time > 0 else { return "00:00" }
        let totalSeconds = Int(time)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
