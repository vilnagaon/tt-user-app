import SwiftUI

struct JournalListView: View {
    @Environment(SupabaseManager.self) private var supabase
    @State private var entries: [JournalEntry] = []
    @State private var isLoading = true
    @State private var showNewEntry = false
    @State private var filterFavorites = false

    private var filtered: [JournalEntry] {
        filterFavorites ? entries.filter(\.isFavorite) : entries
    }

    private var groupedByMonth: [(String, [JournalEntry])] {
        let grouped = Dictionary(grouping: filtered) { entry in
            entry.createdAt?.formatted(.dateTime.month(.wide).year()) ?? "—"
        }
        return grouped.sorted { a, b in
            filtered.first { $0.createdAt?.formatted(.dateTime.month(.wide).year()) == a.key }?.createdAt ?? .distantPast >
            filtered.first { $0.createdAt?.formatted(.dateTime.month(.wide).year()) == b.key }?.createdAt ?? .distantPast
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView().padding(48)
                } else if entries.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        // Stats
                        journalStats
                            .padding(.horizontal)

                        // Filter
                        HStack {
                            filterChip("Toutes", selected: !filterFavorites) { filterFavorites = false }
                            filterChip("Favoris ♥", selected: filterFavorites) { filterFavorites = true }
                            Spacer()
                        }
                        .padding(.horizontal)

                        // Entries
                        LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                            ForEach(groupedByMonth, id: \.0) { month, monthEntries in
                                Section {
                                    ForEach(monthEntries) { entry in
                                        JournalEntryRow(entry: entry)
                                            .padding(.horizontal)
                                    }
                                } header: {
                                    Text(month)
                                        .font(.teatowerCaption)
                                        .foregroundStyle(.teatowerMuted)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal)
                                        .padding(.vertical, 6)
                                        .background(Color.teatowerBg)
                                }
                            }
                        }
                    }
                }
            }
            .background(Color.teatowerBg)
            .navigationTitle("Mon Journal")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showNewEntry = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(.teatowerGreen)
                    }
                }
            }
            .sheet(isPresented: $showNewEntry) {
                Task { await loadEntries() }
            } content: {
                NewJournalEntryView()
            }
            .refreshable { await loadEntries() }
        }
        .task { await loadEntries() }
    }

    private var journalStats: some View {
        HStack(spacing: 16) {
            statPill("\(entries.count)", label: "dégustations")
            statPill("\(entries.filter(\.isFavorite).count)", label: "favoris")
            let avg = entries.compactMap(\.rating).isEmpty ? 0 : entries.compactMap(\.rating).reduce(0, +) / entries.compactMap(\.rating).count
            statPill("\(avg)/5", label: "note moyenne")
        }
        .padding(.top, 8)
    }

    private func statPill(_ value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.system(size: 18, weight: .bold)).foregroundStyle(.teatowerGreen)
            Text(label).font(.system(size: 10)).foregroundStyle(.teatowerMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func filterChip(_ label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: selected ? .bold : .regular))
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(selected ? Color.teatowerGreen : .white)
                .foregroundStyle(selected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 48))
                .foregroundStyle(.teatowerMuted)
            Text("Votre journal de thé")
                .font(.teatowerHeading)
                .foregroundStyle(.teatowerGreen)
            Text("Notez vos dégustations, vos recettes d'infusion,\net gardez une trace de vos thés préférés.")
                .font(.teatowerBody)
                .foregroundStyle(.teatowerMuted)
                .multilineTextAlignment(.center)
            Button { showNewEntry = true } label: {
                Label("Première dégustation", systemImage: "plus")
                    .font(.system(size: 15, weight: .semibold))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.teatowerGreen)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
        }
        .padding(32)
    }

    private func loadEntries() async {
        do {
            entries = try await supabase.client
                .from("journal_entries")
                .select()
                .order("created_at", ascending: false)
                .limit(200)
                .execute()
                .value
        } catch {
            print("Journal load failed: \(error)")
        }
        isLoading = false
    }
}

struct JournalEntryRow: View {
    let entry: JournalEntry

    var body: some View {
        HStack(spacing: 12) {
            // Rating circle
            ZStack {
                Circle()
                    .fill(ratingColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                if let r = entry.rating {
                    Text("\(r)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(ratingColor)
                } else {
                    Text("?")
                        .font(.system(size: 16))
                        .foregroundStyle(.teatowerMuted)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(entry.teaName)
                        .font(.system(size: 14, weight: .semibold))
                        .lineLimit(1)
                    if entry.isFavorite {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.red)
                    }
                }

                if let brew = entry.brewSummary {
                    Text(brew)
                        .font(.system(size: 11))
                        .foregroundStyle(.teatowerBrown)
                }

                HStack(spacing: 6) {
                    if let moment = entry.moment {
                        Text(moment)
                            .font(.system(size: 10, weight: .medium))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.teatowerGreen.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    for m in (entry.mood ?? []).prefix(2) {
                        Text(m)
                            .font(.system(size: 10))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.teatowerBg)
                            .clipShape(Capsule())
                    }
                }
                .foregroundStyle(.teatowerMuted)
            }

            Spacer()

            Text(entry.createdAt?.formatted(.dateTime.day().month(.abbreviated)) ?? "")
                .font(.system(size: 11))
                .foregroundStyle(.teatowerMuted)
        }
        .padding(.vertical, 8)
    }

    private var ratingColor: Color {
        guard let r = entry.rating else { return .teatowerMuted }
        switch r {
        case 5: return .teatowerGreen
        case 4: return .teatowerBrown
        case 3: return .orange
        default: return .red
        }
    }
}
