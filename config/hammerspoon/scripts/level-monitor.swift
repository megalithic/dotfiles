#!/usr/bin/swift
//
// level-monitor.swift - Monitor microphone input levels via AVAudioEngine
//
// Uses AVAudioEngine with an input tap to read audio levels in real-time.
// Outputs normalized RMS level (0.0-1.0) to stdout every ~50ms.
//
// Usage:
//   level-monitor.swift           # Continuous monitoring
//   level-monitor.swift --once    # Single reading
//
// The script handles mic muting gracefully - outputs 0.0 when muted.
//

import AVFoundation
import Foundation

// MARK: - Audio Level Monitor

class AudioLevelMonitor {
    private let engine = AVAudioEngine()
    private var isRunning = false
    private var lastLevel: Float = 0.0
    
    // Smoothing factor for level changes (0.0 = no smoothing, 1.0 = frozen)
    private let smoothing: Float = 0.3
    
    init?() {
        // Request microphone permission
        if #available(macOS 10.14, *) {
            let status = AVCaptureDevice.authorizationStatus(for: .audio)
            if status == .notDetermined {
                // Request permission synchronously (blocks)
                let semaphore = DispatchSemaphore(value: 0)
                AVCaptureDevice.requestAccess(for: .audio) { _ in
                    semaphore.signal()
                }
                semaphore.wait()
            }
            
            if AVCaptureDevice.authorizationStatus(for: .audio) != .authorized {
                fputs("Error: Microphone access denied\n", stderr)
                return nil
            }
        }
    }
    
    /// Calculate RMS level from audio buffer
    private func calculateRMS(_ buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData else { return 0.0 }
        
        let channelCount = Int(buffer.format.channelCount)
        let frameLength = Int(buffer.frameLength)
        
        guard frameLength > 0 else { return 0.0 }
        
        var sum: Float = 0.0
        
        // Average across all channels
        for channel in 0..<channelCount {
            let data = channelData[channel]
            for frame in 0..<frameLength {
                let sample = data[frame]
                sum += sample * sample
            }
        }
        
        let rms = sqrt(sum / Float(frameLength * channelCount))
        return rms
    }
    
    /// Convert RMS to normalized level (0.0-1.0)
    /// Maps -60dB to 0dB range to 0.0 to 1.0
    private func normalizeLevel(_ rms: Float) -> Float {
        guard rms > 0.00001 else { return 0.0 }  // Silence threshold
        
        // Convert to dB: 20 * log10(rms)
        let db = 20.0 * log10(rms)
        
        // Map -60dB to 0dB -> 0.0 to 1.0
        let minDb: Float = -60.0
        let maxDb: Float = 0.0
        let normalized = (db - minDb) / (maxDb - minDb)
        
        return max(0.0, min(1.0, normalized))
    }
    
    /// Start monitoring with callback
    func start(onLevel: @escaping (Float) -> Void) -> Bool {
        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        
        // Install tap on input node
        // Use a small buffer size for responsive updates (~50ms at 44.1kHz)
        let bufferSize: AVAudioFrameCount = 2048
        
        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: format) { [weak self] buffer, _ in
            guard let self = self else { return }
            
            let rms = self.calculateRMS(buffer)
            let level = self.normalizeLevel(rms)
            
            // Apply smoothing
            let smoothedLevel = self.lastLevel * self.smoothing + level * (1.0 - self.smoothing)
            self.lastLevel = smoothedLevel
            
            onLevel(smoothedLevel)
        }
        
        do {
            try engine.start()
            isRunning = true
            return true
        } catch {
            fputs("Error starting audio engine: \(error)\n", stderr)
            return false
        }
    }
    
    /// Stop monitoring
    func stop() {
        if isRunning {
            engine.inputNode.removeTap(onBus: 0)
            engine.stop()
            isRunning = false
        }
    }
    
    /// Run continuous monitoring, outputting to stdout
    func runContinuous() {
        var lastOutputTime = Date()
        let outputInterval: TimeInterval = 0.05  // 50ms between outputs
        
        guard start(onLevel: { level in
            let now = Date()
            if now.timeIntervalSince(lastOutputTime) >= outputInterval {
                print(String(format: "%.3f", level))
                fflush(stdout)
                lastOutputTime = now
            }
        }) else {
            exit(1)
        }
        
        // Keep running until terminated
        signal(SIGINT) { _ in exit(0) }
        signal(SIGTERM) { _ in exit(0) }
        
        RunLoop.current.run()
    }
    
    /// Get single level reading
    func readOnce() -> Float? {
        var result: Float?
        let semaphore = DispatchSemaphore(value: 0)
        
        guard start(onLevel: { level in
            if result == nil {
                result = level
                semaphore.signal()
            }
        }) else {
            return nil
        }
        
        // Wait up to 500ms for a reading
        let timeout = DispatchTime.now() + .milliseconds(500)
        if semaphore.wait(timeout: timeout) == .timedOut {
            stop()
            return 0.0
        }
        
        stop()
        return result
    }
}

// MARK: - Main

let args = CommandLine.arguments

guard let monitor = AudioLevelMonitor() else {
    exit(1)
}

if args.contains("--once") {
    if let level = monitor.readOnce() {
        print(String(format: "%.3f", level))
    } else {
        print("0.000")
    }
} else {
    monitor.runContinuous()
}
