import AVFoundation
import SwiftUI

/// Makes haptics audible in the Simulator, which has no Taptic Engine, so a screen recording
/// shows where the app gives feedback. Each kind of haptic gets its own synthesized click:
/// a crisp tick for selections, a deeper tap for impacts and a low knock for rigid stops.
/// On a real device every call is a no-op and only the actual haptic plays.
enum HapticSound {
    enum Kind { case selection, impact, rigid }

    static func play(_ kind: Kind) {
        #if targetEnvironment(simulator)
        Player.queue.async { Player.shared.play(kind) }
        #endif
    }

    /// Starts the audio engine ahead of the first haptic. Starting it takes long enough to
    /// stall a tap or a drag if it happens on the main thread when feedback first fires.
    static func warmUp() {
        #if targetEnvironment(simulator)
        Player.queue.async { _ = Player.shared }
        #endif
    }

    #if targetEnvironment(simulator)
    private final class Player {
        /// All audio work runs here, off the main thread.
        static let queue = DispatchQueue(label: "HapticSound", qos: .userInteractive)
        static let shared = Player()

        private let engine = AVAudioEngine()
        private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
        /// One node per kind so a selection tick doesn't cut off an impact still ringing.
        private var nodes: [Kind: AVAudioPlayerNode] = [:]
        private var buffers: [Kind: AVAudioPCMBuffer] = [:]

        private init() {
            try? AVAudioSession.sharedInstance().setCategory(.playback, options: .mixWithOthers)
            try? AVAudioSession.sharedInstance().setActive(true)

            //                          pitch (Hz)  length (s)  loudness
            buffers[.selection] = click(frequency: 3_200, duration: 0.012, gain: 0.35)
            buffers[.impact] = click(frequency: 1_400, duration: 0.030, gain: 0.55)
            buffers[.rigid] = click(frequency: 220, duration: 0.060, gain: 0.9)

            for kind in [Kind.selection, .impact, .rigid] {
                let node = AVAudioPlayerNode()
                engine.attach(node)
                engine.connect(node, to: engine.mainMixerNode, format: format)
                nodes[kind] = node
            }
            try? engine.start()
            nodes.values.forEach { $0.play() }
        }

        func play(_ kind: Kind) {
            guard let node = nodes[kind], let buffer = buffers[kind] else { return }
            if !engine.isRunning {
                try? engine.start()
                nodes.values.forEach { $0.play() }
            }
            // .interrupts restarts the click instead of queueing, so fast drags stay in sync.
            node.scheduleBuffer(buffer, at: nil, options: .interrupts)
        }

        /// A sine burst with an instant attack and exponential decay — the shape of a mechanical click.
        private func click(frequency: Double, duration: Double, gain: Float) -> AVAudioPCMBuffer {
            let frames = AVAudioFrameCount(format.sampleRate * duration)
            let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames)!
            buffer.frameLength = frames
            let samples = buffer.floatChannelData![0]
            for i in 0..<Int(frames) {
                let t = Double(i) / format.sampleRate
                let envelope = exp(-t / (duration / 5))
                samples[i] = gain * Float(sin(2 * .pi * frequency * t) * envelope)
            }
            return buffer
        }
    }
    #endif
}

extension View {
    /// Plays the Simulator stand-in sound whenever `trigger` changes; pair it with `.sensoryFeedback`.
    func hapticSound<T: Equatable>(_ kind: HapticSound.Kind = .selection, trigger: T) -> some View {
        onChange(of: trigger) { HapticSound.play(kind) }
    }
}
