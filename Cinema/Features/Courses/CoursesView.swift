import SwiftUI
import AVKit

// MARK: - Catalog

struct CoursesView: View {
    @Environment(CinemaStore.self) private var store

    private var owned: [Course] { store.courses.filter { $0.isOwned } }
    private var available: [Course] { store.courses.filter { !$0.isOwned } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let current = store.courseInProgress, let next = current.nextLesson {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Continue learning")
                        NavigationLink(value: Route.lesson(course: current.id, lesson: next.id)) {
                            ContinueLearningCard(course: current, lesson: next)
                        }
                        .buttonStyle(.plain)
                    }
                }

                if !owned.isEmpty {
                    SectionHeader(title: "My courses")
                    ForEach(owned) { course in
                        NavigationLink(value: Route.course(course.id)) {
                            CourseRow(course: course)
                        }
                        .buttonStyle(.plain)
                    }
                }

                if !available.isEmpty {
                    SectionHeader(title: "More from #Cinema")
                    ForEach(available) { course in
                        NavigationLink(value: Route.course(course.id)) {
                            CourseRow(course: course)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Courses")
    }
}

struct ContinueLearningCard: View {
    let course: Course
    let lesson: Lesson

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Theme.gradient(course.paletteIndex)
                Image(systemName: "play.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 72, height: 72)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                Text(course.title)
                    .font(.cinema(12, weight: .semibold))
                    .foregroundStyle(Theme.textTertiary)
                    .lineLimit(1)
                Text(lesson.title)
                    .font(.cinema(16, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(2)
                ProgressView(value: course.progress)
                    .tint(Theme.red)
                Text("\(course.completedCount) of \(course.lessons.count) lessons · \(lesson.minutes) min")
                    .font(.cinema(12))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .cardStyle()
    }
}

struct CourseRow: View {
    let course: Course

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Theme.gradient(course.paletteIndex)
                Image(systemName: course.symbol)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 84, height: 84)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
                Text(course.title)
                    .font(.cinema(16, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.leading)
                Text("\(course.lessons.count) lessons · \(course.totalMinutes) min · \(course.level)")
                    .font(.cinema(12))
                    .foregroundStyle(Theme.textSecondary)
                if course.isOwned {
                    if course.isComplete {
                        Label("Complete", systemImage: "rosette")
                            .font(.cinema(12, weight: .semibold))
                            .foregroundStyle(Theme.success)
                    } else {
                        ProgressView(value: course.progress)
                            .tint(Theme.red)
                    }
                } else {
                    Pill(text: course.price, icon: "lock.fill")
                }
            }
            Spacer(minLength: 0)
        }
        .cardStyle(padding: 12)
    }
}

// MARK: - Course detail

struct CourseDetailView: View {
    let courseID: UUID
    @Environment(CinemaStore.self) private var store
    @State private var isBuying = false

    var body: some View {
        Group {
            if let course = store.course(courseID) {
                content(course)
            } else {
                EmptyStateView(title: "Course not found", message: "It may have been removed.", icon: "book.closed")
            }
        }
        .cinemaScreen()
        .navigationBarTitleDisplayMode(.inline)
    }

    private func content(_ course: Course) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ZStack(alignment: .bottomLeading) {
                    Theme.gradient(course.paletteIndex)
                        .frame(height: 190)
                    Image(systemName: course.symbol)
                        .font(.system(size: 90, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.15))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.trailing, 20)
                        .padding(.bottom, 40)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(course.instructor) · \(course.level)")
                            .font(.cinema(13, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.85))
                        Text(course.title)
                            .font(.cinema(24, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .padding(18)
                }
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                Text(course.subtitle)
                    .font(.cinema(16))
                    .foregroundStyle(Theme.textSecondary)

                HStack(spacing: 10) {
                    Pill(text: "\(course.lessons.count) lessons", icon: "play.rectangle.fill")
                    Pill(text: "\(course.totalMinutes) min", icon: "clock.fill")
                    Pill(text: "Skill level \(course.skillLevel)", icon: "stairs")
                }

                if course.isOwned {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("\(Int(course.progress * 100))% complete")
                                .font(.cinema(15, weight: .semibold))
                                .foregroundStyle(Theme.textPrimary)
                            Spacer()
                            Text("\(course.completedCount)/\(course.lessons.count)")
                                .font(.cinema(13))
                                .foregroundStyle(Theme.textSecondary)
                        }
                        ProgressView(value: course.progress)
                            .tint(Theme.red)
                    }
                    .cardStyle()
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Lesson 1 is free. Unlock the rest, the assignments and your certificate.")
                            .font(.cinema(14))
                            .foregroundStyle(Theme.textSecondary)
                        Button {
                            isBuying = true
                            Task {
                                await store.buyCourse(course.id)
                                isBuying = false
                            }
                        } label: {
                            if isBuying {
                                ProgressView().tint(.white)
                            } else {
                                Text("Enroll for \(course.price)")
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(isBuying)
                        Text("Pro members get one course included.")
                            .font(.cinema(12))
                            .foregroundStyle(Theme.textTertiary)
                    }
                    .cardStyle()
                }

                if course.isComplete {
                    certificate(course)
                }

                SectionHeader(title: "Lessons")
                ForEach(Array(course.lessons.enumerated()), id: \.element.id) { index, lesson in
                    let unlocked = course.isOwned || index == 0
                    if unlocked {
                        NavigationLink(value: Route.lesson(course: course.id, lesson: lesson.id)) {
                            lessonRow(index: index, lesson: lesson, unlocked: true)
                        }
                        .buttonStyle(.plain)
                    } else {
                        lessonRow(index: index, lesson: lesson, unlocked: false)
                    }
                }

                Button {
                    store.showToast("Joined the course group in Community")
                } label: {
                    Label("Join the course group", systemImage: "person.3.fill")
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            .padding(Theme.gutter)
        }
    }

    private func lessonRow(index: Int, lesson: Lesson, unlocked: Bool) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(lesson.isComplete ? Theme.success : Theme.surfaceRaised)
                    .frame(width: 34, height: 34)
                if lesson.isComplete {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                } else if !unlocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textTertiary)
                } else {
                    Text("\(index + 1)")
                        .font(.cinema(14, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(lesson.title)
                    .font(.cinema(15, weight: .semibold))
                    .foregroundStyle(unlocked ? Theme.textPrimary : Theme.textTertiary)
                    .multilineTextAlignment(.leading)
                Text("\(lesson.minutes) min · includes a filming assignment")
                    .font(.cinema(12))
                    .foregroundStyle(Theme.textTertiary)
            }
            Spacer(minLength: 0)
            if unlocked {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Theme.red)
            }
        }
        .cardStyle(padding: 12)
    }

    private func certificate(_ course: Course) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "rosette")
                .font(.system(size: 40))
                .foregroundStyle(Theme.warning)
            Text("Certificate of completion")
                .font(.cinema(18, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Text("\(store.profile.name) · \(course.title)")
                .font(.cinema(14))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
            Text("Badge added to your community profile.")
                .font(.cinema(12))
                .foregroundStyle(Theme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .cardStyle()
        .overlay(
            RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                .stroke(Theme.warning.opacity(0.6), lineWidth: 1.5)
        )
    }
}

// MARK: - Lesson

struct LessonView: View {
    let courseID: UUID
    let lessonID: UUID

    @Environment(CinemaStore.self) private var store
    @State private var player: AVPlayer?
    @State private var showCamera = false
    @State private var practice = false

    var body: some View {
        Group {
            if let course = store.course(courseID),
               let index = course.lessons.firstIndex(where: { $0.id == lessonID }) {
                content(course: course, index: index)
            } else {
                EmptyStateView(title: "Lesson not found", message: "It may have been removed.", icon: "play.slash")
            }
        }
        .cinemaScreen()
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { player?.pause() }
    }

    private func content(course: Course, index: Int) -> some View {
        let lesson = course.lessons[index]
        let next: Lesson? = index + 1 < course.lessons.count ? course.lessons[index + 1] : nil

        return ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ZStack {
                    if let player {
                        VideoPlayer(player: player)
                    } else {
                        Theme.gradient(course.paletteIndex)
                        Button {
                            if let url = lesson.videoURL {
                                let newPlayer = AVPlayer(url: url)
                                player = newPlayer
                                newPlayer.play()
                            }
                        } label: {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 64))
                                .foregroundStyle(.white.opacity(0.9))
                        }
                    }
                }
                .aspectRatio(16.0 / 9.0, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                VStack(alignment: .leading, spacing: 6) {
                    Text("Lesson \(index + 1) of \(course.lessons.count) · \(lesson.minutes) min")
                        .font(.cinema(13, weight: .semibold))
                        .foregroundStyle(Theme.red)
                    Text(lesson.title)
                        .font(.cinema(24, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text(lesson.summary)
                        .font(.cinema(15))
                        .foregroundStyle(Theme.textSecondary)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("KEY TAKEAWAYS")
                        .font(.cinema(12, weight: .bold))
                        .foregroundStyle(Theme.red)
                    ForEach(lesson.takeaways, id: \.self) { item in
                        Label(item, systemImage: "checkmark.circle")
                            .font(.cinema(15))
                            .foregroundStyle(Theme.textPrimary)
                    }
                }
                .cardStyle()

                VStack(alignment: .leading, spacing: 12) {
                    Label("Your assignment", systemImage: "video.fill")
                        .font(.cinema(17, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text(lesson.assignment)
                        .font(.cinema(15))
                        .foregroundStyle(Theme.textSecondary)
                    Text("The script loads on the teleprompter. Send the take to your coach for notes or to editing for a finished post.")
                        .font(.cinema(12))
                        .foregroundStyle(Theme.textTertiary)
                    HStack(spacing: 10) {
                        Button("Film it") {
                            practice = false
                            showCamera = true
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        Button("Practice") {
                            practice = true
                            showCamera = true
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                }
                .cardStyle()
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                        .stroke(Theme.red.opacity(0.4), lineWidth: 1)
                )

                if course.isOwned {
                    Button {
                        store.setLesson(lesson.id, in: course.id, complete: !lesson.isComplete)
                    } label: {
                        Label(lesson.isComplete ? "Completed" : "Mark complete", systemImage: lesson.isComplete ? "checkmark.circle.fill" : "circle")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }

                if let next, course.isOwned {
                    NavigationLink(value: Route.lesson(course: course.id, lesson: next.id)) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Up next")
                                    .font(.cinema(12, weight: .semibold))
                                    .foregroundStyle(Theme.textTertiary)
                                Text(next.title)
                                    .font(.cinema(15, weight: .semibold))
                                    .foregroundStyle(Theme.textPrimary)
                            }
                            Spacer()
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 26))
                                .foregroundStyle(Theme.red)
                        }
                        .cardStyle()
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(Theme.gutter)
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraView(idea: assignmentIdea(lesson), practiceMode: practice)
        }
    }

    private func assignmentIdea(_ lesson: Lesson) -> Idea {
        Idea(
            title: "Assignment: \(lesson.title)",
            hook: lesson.assignmentScript,
            category: .dayInLife,
            shots: [lesson.assignment],
            script: lesson.assignmentScript,
            targetSeconds: 30,
            whyItWorks: lesson.summary
        )
    }
}
