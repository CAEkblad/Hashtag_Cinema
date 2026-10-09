import SwiftUI

/// Every tool in one place, grouped by the job it does.
struct ToolsView: View {
    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                ForEach(ToolCatalog.Group.allCases) { group in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(group.title)
                            .font(.cinema(18, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(ToolCatalog.all.filter { $0.group == group }) { tool in
                                NavigationLink(value: tool.route) {
                                    VStack(alignment: .leading, spacing: 10) {
                                        Image(systemName: tool.icon)
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundStyle(Theme.red)
                                            .frame(width: 34, height: 34)
                                            .background(Theme.redSoft, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                                        Text(tool.title)
                                            .font(.cinema(14, weight: .semibold))
                                            .foregroundStyle(Theme.textPrimary)
                                            .multilineTextAlignment(.leading)
                                            .lineLimit(2, reservesSpace: true)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .cardStyle(padding: 14)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("All tools")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(value: Route.search) {
                    Image(systemName: "magnifyingglass")
                }
                .accessibilityLabel("Search")
            }
        }
    }
}
