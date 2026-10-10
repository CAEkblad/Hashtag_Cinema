import AVFoundation
import Observation
import UIKit

/// Records vertical video with the front or back camera.
/// On the Simulator there is no camera, so `isAvailable` becomes false
/// and the screen falls back to a demo preview.
@Observable
final class CameraModel: NSObject, AVCaptureFileOutputRecordingDelegate, @unchecked Sendable {
    var isAuthorized = false
    var isAvailable = true
    var isRecording = false
    var usingFrontCamera = true
    var lastRecordingURL: URL?
    var errorMessage: String?

    let session = AVCaptureSession()
    private let movieOutput = AVCaptureMovieFileOutput()
    private let sessionQueue = DispatchQueue(label: "com.hashtagcinema.camera")
    @ObservationIgnored private var videoInput: AVCaptureDeviceInput?
    @ObservationIgnored private var isConfigured = false

    func start() {
        Task {
            let videoGranted = await AVCaptureDevice.requestAccess(for: .video)
            _ = await AVCaptureDevice.requestAccess(for: .audio)
            await MainActor.run { self.isAuthorized = videoGranted }
            guard videoGranted else { return }
            let front = await MainActor.run { self.usingFrontCamera }
            sessionQueue.async {
                self.configureIfNeeded(front: front)
                if self.isConfigured && !self.session.isRunning {
                    self.session.startRunning()
                }
            }
        }
    }

    func stop() {
        sessionQueue.async {
            if self.movieOutput.isRecording { self.movieOutput.stopRecording() }
            if self.session.isRunning { self.session.stopRunning() }
        }
    }

    func flipCamera() {
        guard !isRecording else { return }
        usingFrontCamera.toggle()
        let front = usingFrontCamera
        sessionQueue.async {
            guard let current = self.videoInput,
                  let device = Self.camera(front: front),
                  let newInput = try? AVCaptureDeviceInput(device: device) else { return }
            self.session.beginConfiguration()
            self.session.removeInput(current)
            if self.session.canAddInput(newInput) {
                self.session.addInput(newInput)
                self.videoInput = newInput
            } else {
                self.session.addInput(current)
            }
            self.session.commitConfiguration()
            self.applyPortraitRotation()
        }
    }

    func toggleRecording() {
        if isRecording {
            sessionQueue.async { self.movieOutput.stopRecording() }
            return
        }
        guard isAvailable, isConfigured else { return }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("cinema-\(UUID().uuidString)")
            .appendingPathExtension("mov")
        isRecording = true
        sessionQueue.async {
            self.applyPortraitRotation()
            self.movieOutput.startRecording(to: url, recordingDelegate: self)
        }
    }

    // MARK: Setup

    private static func camera(front: Bool) -> AVCaptureDevice? {
        AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: front ? .front : .back)
    }

    private func configureIfNeeded(front: Bool) {
        guard !isConfigured else { return }
        guard let device = Self.camera(front: front),
              let input = try? AVCaptureDeviceInput(device: device) else {
            DispatchQueue.main.async { self.isAvailable = false }
            return
        }

        session.beginConfiguration()
        session.sessionPreset = .high
        if session.canAddInput(input) {
            session.addInput(input)
            videoInput = input
        }
        if let mic = AVCaptureDevice.default(for: .audio),
           let micInput = try? AVCaptureDeviceInput(device: mic),
           session.canAddInput(micInput) {
            session.addInput(micInput)
        }
        if session.canAddOutput(movieOutput) {
            session.addOutput(movieOutput)
        }
        session.commitConfiguration()
        applyPortraitRotation()
        isConfigured = true
    }

    private func applyPortraitRotation() {
        guard let connection = movieOutput.connection(with: .video) else { return }
        if connection.isVideoRotationAngleSupported(90) {
            connection.videoRotationAngle = 90
        }
    }

    // MARK: AVCaptureFileOutputRecordingDelegate

    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        let saved = FileManager.default.fileExists(atPath: outputFileURL.path)
        DispatchQueue.main.async {
            self.isRecording = false
            if saved {
                self.lastRecordingURL = outputFileURL
            } else {
                self.errorMessage = error?.localizedDescription ?? "Recording failed."
            }
        }
    }
}
