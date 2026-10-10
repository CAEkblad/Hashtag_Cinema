import SwiftUI

/// A Florida real estate license and the education needed to renew it.
struct LicensePlan: Codable, Equatable {
    enum Kind: String, Codable, CaseIterable, Identifiable {
        case salesAssociate, broker
        var id: String { rawValue }
        var title: String { self == .salesAssociate ? "Sales associate" : "Broker" }
        var postLicensingHours: Int { self == .salesAssociate ? 45 : 60 }
    }

    var kind: Kind = .salesAssociate
    var expires: Date = LicensePlan.nextExpiration()
    var isFirstRenewal = false
    var courses: [CECourse] = []
    var remindersOn = false

    /// Florida licenses expire March 31 or September 30.
    static func nextExpiration(from now: Date = Date()) -> Date {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: now)
        let options = [(year, 3, 31), (year, 9, 30), (year + 1, 3, 31)].compactMap { calendar.date(from: DateComponents(year: $0.0, month: $0.1, day: $0.2)) }
        return options.first { $0 >= calendar.startOfDay(for: now) } ?? now
    }

    var daysLeft: Int { Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: Date()), to: expires).day ?? 0 }

    func hours(_ category: CECourse.Category) -> Double { courses.filter { $0.category == category }.reduce(0) { $0 + $1.hours } }

    /// What's required before this renewal, by category.
    var requirements: [(category: CECourse.Category, needed: Double)] {
        if isFirstRenewal { return [(.postLicensing, Double(kind.postLicensingHours))] }
        return [(.coreLaw, 3), (.ethics, 3), (.specialty, 8)]
    }

    var totalNeeded: Double { requirements.reduce(0) { $0 + $1.needed } }
    var totalDone: Double { requirements.reduce(0) { $0 + min(hours($1.category), $1.needed) } }
}

struct CECourse: Identifiable, Codable, Equatable {
    enum Category: String, Codable, CaseIterable, Identifiable {
        case coreLaw, ethics, specialty, postLicensing
        var id: String { rawValue }
        var title: String {
            switch self {
            case .coreLaw: return "Core law"
            case .ethics: return "Ethics and business practices"
            case .specialty: return "Specialty"
            case .postLicensing: return "Post licensing"
            }
        }
    }

    var id = UUID()
    var name: String
    var hours: Double
    var category: Category
    var date: Date
}

struct LicenseView: View {
    @Environment(CinemaStore.self) private var store
    @State private var plan = LicensePlan()
    @State private var didLoad = false
    @State private var showAdd = false
    @State private var skipNextChange = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(plan.daysLeft >= 0 ? "\(plan.daysLeft) days to renew" : "Your license has expired")
                        .font(.cinema(26, weight: .heavy))
                    Text("\(plan.kind.title) license · expires \(plan.expires.formatted(.dateTime.month(.wide).day().year()))")
                        .font(.cinema(13, weight: .semibold))
                        .opacity(0.9)
                    ProgressView(value: plan.totalDone, total: max(plan.totalNeeded, 1))
                        .tint(.white)
                    Text("\(String(format: "%g", plan.totalDone)) of \(String(format: "%g", plan.totalNeeded)) hours done")
                        .font(.cinema(12, weight: .semibold))
                        .opacity(0.9)
                }
                .foregroundStyle(.white)
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(plan.daysLeft < 60 ? Theme.red : Theme.ink, in: RoundedRectangle(cornerRadius: 20, style: .continuous))

                VStack(alignment: .leading, spacing: 12) {
                    Picker("License", selection: $plan.kind) {
                        ForEach(LicensePlan.Kind.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    DatePicker("Expires", selection: $plan.expires, displayedComponents: .date)
                    Toggle("This is my first renewal", isOn: $plan.isFirstRenewal)
                        .tint(Theme.red)
                    Toggle("Remind me 90, 30 and 7 days before", isOn: $plan.remindersOn)
                        .tint(Theme.red)
                }
                .font(.cinema(14))
                .cardStyle()

                SectionHeader(title: "What you need", actionTitle: "Add course") { showAdd = true }
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(plan.requirements, id: \.category) { requirement in
                        let done = plan.hours(requirement.category)
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(requirement.category.title)
                                    .font(.cinema(14, weight: .semibold))
                                    .foregroundStyle(Theme.textPrimary)
                                Spacer()
                                Text("\(String(format: "%g", min(done, requirement.needed))) of \(String(format: "%g", requirement.needed)) hrs")
                                    .font(.cinema(13, weight: .semibold))
                                    .foregroundStyle(done >= requirement.needed ? Theme.success : Theme.red)
                            }
                            ProgressView(value: min(done, requirement.needed), total: requirement.needed)
                                .tint(done >= requirement.needed ? Theme.success : Theme.red)
                        }
                    }
                }
                .cardStyle()

                if !plan.courses.isEmpty {
                    SectionHeader(title: "Courses taken")
                    ForEach(plan.courses.sorted { $0.date > $1.date }) { course in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(course.name)
                                    .font(.cinema(14, weight: .semibold))
                                    .foregroundStyle(Theme.textPrimary)
                                Text("\(course.category.title) · \(course.date.formatted(.dateTime.month(.abbreviated).day().year()))")
                                    .font(.cinema(12))
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            Spacer()
                            Text("\(String(format: "%g", course.hours)) hrs")
                                .font(.cinema(13, weight: .semibold))
                                .foregroundStyle(Theme.textSecondary)
                        }
                        .cardStyle(padding: 14)
                        .contextMenu {
                            Button(role: .destructive) {
                                plan.courses.removeAll { $0.id == course.id }
                            } label: {
                                Label("Remove", systemImage: "trash")
                            }
                        }
                    }
                }

                Text("Florida rules as we know them: licenses expire March 31 or September 30. Before your first renewal you need post licensing (45 hours for sales associates, 60 for brokers). After that, 14 hours every 2 years: 3 core law, 3 ethics and business practices and 8 specialty. Realtors also need NAR Code of Ethics training every 3 years. Always confirm with the Florida DBPR.")
                    .font(.cinema(11))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("License and CE")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            guard !didLoad else { return }
            didLoad = true
            if plan != store.licensePlan {
                skipNextChange = true
                plan = store.licensePlan
            }
        }
        .onChange(of: plan) { old, new in
            if skipNextChange {
                skipNextChange = false
                return
            }
            let toggled = old.remindersOn != new.remindersOn
            let changed = toggled || old.expires != new.expires || old.courses != new.courses || old.isFirstRenewal != new.isFirstRenewal || old.kind != new.kind
            store.saveLicensePlan(new, reschedule: changed, quiet: !toggled)
        }
        .sheet(isPresented: $showAdd) {
            AddCourseView(defaultCategory: plan.isFirstRenewal ? .postLicensing : .specialty) { course in
                plan.courses.append(course)
            }
        }
    }
}

struct AddCourseView: View {
    @Environment(\.dismiss) private var dismiss
    var defaultCategory: CECourse.Category
    var onSave: (CECourse) -> Void

    @State private var name = ""
    @State private var hours: Double = 3
    @State private var category: CECourse.Category = .specialty
    @State private var date = Date()
    @State private var didLoad = false

    var body: some View {
        NavigationStack {
            Form {
                TextField("Course name", text: $name)
                Picker("Counts toward", selection: $category) {
                    ForEach(CECourse.Category.allCases) { Text($0.title).tag($0) }
                }
                Stepper("\(String(format: "%g", hours)) hours", value: $hours, in: 1...60, step: 1)
                DatePicker("Completed", selection: $date, in: ...Date(), displayedComponents: .date)
            }
            .navigationTitle("Add a course")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                guard !didLoad else { return }
                didLoad = true
                category = defaultCategory
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(CECourse(name: name.trimmingCharacters(in: .whitespaces), hours: hours, category: category, date: date))
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
