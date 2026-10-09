import SwiftUI
import AVFoundation

struct CameraView: View {
    let idea: Idea?
    @State var practiceMode: Bool

    @Environment(\.dismiss) private var dismiss
    @State private var camera = CameraModel()
    @State private var showTeleprompter = true
    @State private var showGuides = true
    @State private var speed: Double = 32
    @State private var recordStart: Date?
    @State private var simulatedRecording = false
    @State private var showEditRequest = false
    @State private var showPracticeResult = false
    @State private var recordedURL: URL?

    init(idea: Idea?, practiceMode: Bool) {
        self.idea = idea
        self._practiceMode = State(initialValue: practiceMode)
    }

    private var isSimulated: Bool { !camera.isAvailable || !camera.isAuthorized }
    private var isRecording: Bool { isSimulated ? simulatedRecording : camera.isRecording }
    private var script: String {
        idea?.script ?? "Say hi, tell viewers who you help and where, then give them one tip they can use today. End with what to comment for more."
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if isSimulated {
                simulatedBackground
            } else {
                CameraPreview(session: camera.session)
                    .ignoresSafeArea()
            }

            if showGuides {
                FramingGuides()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            VStack(spacing: 0) {
                topBar
                if showTeleprompter {
                    TeleprompterView(script: script, isScrolling: isRecording, startDate: recordStart, speed: speed)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                }
                Spacer()
                bottomControls
            }
        }
        .statusBarHidden()
        .onAppear { camera.start() }
        .onDisappear { camera.stop() }
        .onChange(of: camera.lastRecordingURL) { _, url in
            guard let url else { return }
            recordedURL = url
            finishedRecording()
        }
        .sheet(isPresented: $showEditRequest) {
            EditRequestView(idea: idea, recordedURL: recordedURL, sourceLabel: "Your new recording") {
                dismiss()
            }
        }
        .sheet(isPresented: $showPracticeResult) {
            PracticeResultView {
                showPracticeResult = false
                practiceMode = false
            } onDone: {
                dismiss()
            }
            .presentationDetents([.medium, .large])
        }
    }

    // MARK: Pieces

    private var simulatedBackground: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0x2A2A30), .black], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack(spacing: 10) {
                Image(systemName: "person.crop.rectangle")
                    .font(.system(size: 64))
                    .foregroundStyle(.white.opacity(0.25))
                Text(camera.isAuthorized || camera.isAvailable == false ? "Camera not available here" : "Camera access needed")
                    .font(.cinema(15, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))
                Text("Run on an iPhone to record. You can still try the flow.")
                    .font(.cinema(13))
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            circleButton("xmark") { dismiss() }
            Spacer()
            if practiceMode {
                Pill(text: "Practice", icon: "figure.mind.and.body", color: Theme.warning.opacity(0.9), textColor: .black)
            }
            if isRecording, let recordStart {
                TimelineView(.periodic(from: recordStart, by: 1)) { context in
                    let seconds = Int(context.date.timeIntervalSince(recordStart))
                    Pill(text: String(format: "%d:%02d", seconds / 60, seconds % 60), icon: "record.circle", color: Theme.red, textColor: .white)
                }
            }
            Spacer()
            circleButton(showTeleprompter ? "text.bubble.fill" : "text.bubble") { showTeleprompter.toggle() }
            circleButton(showGuides ? "square.grid.3x3.fill" : "square.grid.3x3") { showGuides.toggle() }
            circleButton("arrow.triangle.2.circlepath.camera") { camera.flipCamera() }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var bottomControls: some View {
        VStack(spacing: 16) {
            if showTeleprompter && !isRecording {
                HStack(spacing: 10) {
                    Image(systemName: "tortoise.fill")
                    Slider(value: $speed, in: 15...60)
                        .tint(Theme.red)
                    Image(systemName: "hare.fill")
                }
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.7))
                .padding(.horizontal, 40)
            }

            if let idea, !isRecording {
                Text("Target: \(idea.targetSeconds) seconds")
                    .font(.cinema(13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.75))
            }

            Button(action: toggleRecording) {
                ZStack {
                    Circle()
                        .stroke(.white, lineWidth: 4)
                        .frame(width: 82, height: 82)
                    RoundedRectangle(cornerRadius: isRecording ? 8 : 34, style: .continuous)
                        .fill(Theme.red)
                        .frame(width: isRecording ? 34 : 68, height: isRecording ? 34 : 68)
                }
                .animation(.spring(duration: 0.25), value: isRecording)
            }
            .accessibilityLabel(isRecording ? "Stop recording" : "Start recording")

            if let message = camera.errorMessage {
                Text(message)
                    .font(.cinema(12))
                    .foregroundStyle(Theme.warning)
            }
        }
        .padding(.bottom, 24)
    }

    private func circleButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(.black.opacity(0.45), in: Circle())
        }
    }

    // MARK: Actions

    private func toggleRecording() {
        if isSimulated {
            if simulatedRecording {
                simulatedRecording = false
                recordedURL = nil
                finishedRecording()
            } else {
                recordStart = Date()
                simulatedRecording = true
            }
            return
        }
        if !camera.isRecording { recordStart = Date() }
        camera.toggleRecording()
    }

    private func finishedRecording() {
        recordStart = nil
        if practiceMode {
            showPracticeResult = true
        } else {
            showEditRequest = true
        }
    }
}

// MARK: - Preview layer

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {}

    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            // layerClass guarantees this cast.
            layer as! AVCaptureVideoPreviewLayer
        }
    }
}

// MARK: - Teleprompter

struct TeleprompterView: View {
    let script: String
    let isScrolling: Bool
    let startDate: Date?
    let speed: Double

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !isScrolling)) { context in
            let elapsed = startDate.map { context.date.timeIntervalSince($0) } ?? 0
            Text(script)
                .font(.cinema(22, weight: .semibold))
                .foregroundStyle(.white)
                .lineSpacing(6)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .offset(y: 40 - CGFloat(elapsed * speed))
        }
        .frame(height: 170, alignment: .top)
        .clipped()
        .padding(.vertical, 10)
        .background(.black.opacity(0.5), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(alignment: .top) {
            // Eye line marker: read here to keep eye contact with the lens.
            Capsule()
                .fill(Theme.red)
                .frame(width: 40, height: 3)
                .padding(.top, 6)
        }
    }
}

// MARK: - Framing guides

struct FramingGuides: View {
    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            Path { path in
                for fraction in [1.0 / 3.0, 2.0 / 3.0] {
                    path.move(to: CGPoint(x: w * fraction, y: 0))
                    path.addLine(to: CGPoint(x: w * fraction, y: h))
                    path.move(to: CGPoint(x: 0, y: h * fraction))
                    path.addLine(to: CGPoint(x: w, y: h * fraction))
                }
            }
            .stroke(.white.opacity(0.18), lineWidth: 1)

            // Safe zone: platforms cover the bottom with captions and buttons.
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.red.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [6, 6]))
                .frame(width: w * 0.82, height: h * 0.62)
                .position(x: w / 2, y: h * 0.45)
        }
    }
}

// MARK: - Practice result

struct PracticeResultView: View {
    let onRecordForReal: () -> Void
    let onDone: () -> Void

    private struct Note: Identifiable {
        let icon: String
        let title: String
        let detail: String
        var id: String { title }
    }

    private var notes: [Note] {
        [
            Note(icon: "metronome.fill", title: "Pace", detail: "158 words a minute. Slow down slightly, aim for 140 to 150."),
            Note(icon: "text.badge.xmark", title: "Filler words", detail: "4 'um's. Pause instead of filling the gap."),
            Note(icon: "eye.fill", title: "Eye contact", detail: "You looked at the lens 72% of the time. Read from the red line at the top."),
            Note(icon: "bolt.fill", title: "Hook", detail: "Your first line landed in 1.4 seconds. Nice.")
        ]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Coach notes")
                        .font(.cinema(24, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Practice takes are not saved and do not use credits.")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                    ForEach(notes) { note in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: note.icon)
                                .foregroundStyle(Theme.red)
                                .frame(width: 28)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(note.title)
                                    .font(.cinema(15, weight: .semibold))
                                    .foregroundStyle(Theme.textPrimary)
                                Text(note.detail)
                                    .font(.cinema(14))
                                    .foregroundStyle(Theme.textSecondary)
                            }
                        }
                        .cardStyle(padding: 14)
                    }
                    Button("Record for real", action: onRecordForReal)
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.top, 6)
                    Button("Done", action: onDone)
                        .buttonStyle(SecondaryButtonStyle())
                }
                .padding(Theme.gutter)
            }
            .cinemaScreen()
        }
    }
}
