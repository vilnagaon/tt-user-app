import SwiftUI

struct EditTeaProfileView: View {
    @Environment(SupabaseManager.self) private var supabase
    @Environment(\.dismiss) private var dismiss

    @State private var favoriteTypes: Set<String>
    @State private var brewingMethod: String
    @State private var frequency: String
    @State private var caffeinePreference: String
    @State private var taste: TastePreferences
    @State private var discoveryNotes: String
    @State private var isSaving = false
    @State private var showSaved = false

    let currentProfile: TeaProfile

    init(profile: TeaProfile) {
        self.currentProfile = profile
        _favoriteTypes = State(initialValue: Set(profile.favoriteTypes ?? []))
        _brewingMethod = State(initialValue: profile.brewingMethod ?? "")
        _frequency = State(initialValue: profile.frequency ?? "")
        _caffeinePreference = State(initialValue: profile.caffeinePreference ?? "")
        _taste = State(initialValue: profile.taste ?? TastePreferences())
        _discoveryNotes = State(initialValue: profile.discoveryNotes ?? "")
    }

    private let teaTypes = [
        ("Thé vert", "🍃"), ("Thé noir", "🫖"), ("Thé blanc", "🤍"),
        ("Matcha", "🍵"), ("Infusions fruits", "🍓"), ("Infusions plantes", "🌿"),
        ("Rooibos", "🌺"), ("Oolong", "🏮"), ("Détox", "💚"), ("Thés glacés", "🧊"),
    ]

    private let brewingMethods = ["Infusettes (sachets)", "Vrac en théière", "Infuseur individuel", "Cold brew (à froid)", "Matcha au fouet"]
    private let frequencies = ["Plusieurs fois par jour", "Quotidienne", "Plusieurs fois par semaine", "Occasionnelle", "Débutant(e)"]
    private let caffeineOptions = ["Avec théine toute la journée", "Théine le matin, sans le soir", "Sans théine uniquement", "Pas de préférence"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    typesSection
                    tasteSection
                    methodSection
                    frequencySection
                    caffeineSection
                    notesSection
                }
                .padding()
            }
            .background(Color.teatowerBg)
            .navigationTitle("Mon Tea Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: { Task { await save() } }) {
                        if isSaving {
                            ProgressView().tint(.teatowerGreen)
                        } else if showSaved {
                            Label("Sauvé", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        } else {
                            Text("Enregistrer").fontWeight(.semibold)
                        }
                    }
                    .disabled(isSaving)
                }
            }
        }
    }

    // MARK: - Types de thé

    private var typesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Quels thés aimez-vous ?", systemImage: "leaf.fill")
                .font(.teatowerHeading)
                .foregroundStyle(.teatowerGreen)

            Text("Sélectionnez tous ceux qui vous plaisent")
                .font(.teatowerCaption)
                .foregroundStyle(.teatowerMuted)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 10)], spacing: 10) {
                ForEach(teaTypes, id: \.0) { type, emoji in
                    let isSelected = favoriteTypes.contains(type)
                    Button {
                        if isSelected { favoriteTypes.remove(type) }
                        else { favoriteTypes.insert(type) }
                    } label: {
                        HStack(spacing: 8) {
                            Text(emoji)
                            Text(type)
                                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(isSelected ? Color.teatowerGreen : Color.teatowerBg)
                        .foregroundStyle(isSelected ? .white : .primary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(isSelected ? Color.teatowerGreen : Color.teatowerBorder, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .sectionCard()
    }

    // MARK: - Profil gustatif

    private var tasteSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Votre palais", systemImage: "mouth.fill")
                .font(.teatowerHeading)
                .foregroundStyle(.teatowerGreen)

            Text("Glissez les curseurs selon vos préférences")
                .font(.teatowerCaption)
                .foregroundStyle(.teatowerMuted)

            tasteSlider("🍯 Sucré", value: binding(for: \.sweet))
            tasteSlider("🍵 Amer", value: binding(for: \.bitter))
            tasteSlider("🌸 Floral", value: binding(for: \.floral))
            tasteSlider("🌶️ Épicé", value: binding(for: \.spicy))
            tasteSlider("🍑 Fruité", value: binding(for: \.fruity))
            tasteSlider("🌿 Terreux", value: binding(for: \.earthy))
        }
        .sectionCard()
    }

    private func tasteSlider(_ label: String, value: Binding<Double>) -> some View {
        VStack(spacing: 4) {
            HStack {
                Text(label)
                    .font(.system(size: 13))
                    .frame(width: 100, alignment: .leading)
                Slider(value: value, in: 0...5, step: 1)
                    .tint(.teatowerGreen)
                Text("\(Int(value.wrappedValue))/5")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.teatowerGreen)
                    .frame(width: 30)
            }
        }
    }

    private func binding(for keyPath: WritableKeyPath<TastePreferences, Int?>) -> Binding<Double> {
        Binding(
            get: { Double(taste[keyPath: keyPath] ?? 0) },
            set: { taste[keyPath: keyPath] = Int($0) }
        )
    }

    // MARK: - Méthode

    private var methodSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Comment infusez-vous ?", systemImage: "cup.and.saucer.fill")
                .font(.teatowerHeading)
                .foregroundStyle(.teatowerGreen)

            ForEach(brewingMethods, id: \.self) { method in
                Button {
                    brewingMethod = method
                } label: {
                    HStack {
                        Text(method)
                            .font(.system(size: 14))
                        Spacer()
                        if brewingMethod == method {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.teatowerGreen)
                        }
                    }
                    .padding(12)
                    .background(brewingMethod == method ? Color.teatowerGreen.opacity(0.08) : Color.teatowerBg)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
        .sectionCard()
    }

    // MARK: - Fréquence

    private var frequencySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("À quelle fréquence ?", systemImage: "clock.fill")
                .font(.teatowerHeading)
                .foregroundStyle(.teatowerGreen)

            ForEach(frequencies, id: \.self) { freq in
                Button {
                    frequency = freq
                } label: {
                    HStack {
                        Text(freq).font(.system(size: 14))
                        Spacer()
                        if frequency == freq {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.teatowerGreen)
                        }
                    }
                    .padding(12)
                    .background(frequency == freq ? Color.teatowerGreen.opacity(0.08) : Color.teatowerBg)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
        .sectionCard()
    }

    // MARK: - Caféine

    private var caffeineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Et la théine ?", systemImage: "bolt.fill")
                .font(.teatowerHeading)
                .foregroundStyle(.teatowerGreen)

            ForEach(caffeineOptions, id: \.self) { option in
                Button {
                    caffeinePreference = option
                } label: {
                    HStack {
                        Text(option).font(.system(size: 14))
                        Spacer()
                        if caffeinePreference == option {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.teatowerGreen)
                        }
                    }
                    .padding(12)
                    .background(caffeinePreference == option ? Color.teatowerGreen.opacity(0.08) : Color.teatowerBg)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
        .sectionCard()
    }

    // MARK: - Notes

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Notes personnelles", systemImage: "pencil")
                .font(.teatowerHeading)
                .foregroundStyle(.teatowerGreen)

            Text("Allergies, préférences, ou tout ce que votre sommelier devrait savoir")
                .font(.teatowerCaption)
                .foregroundStyle(.teatowerMuted)

            TextEditor(text: $discoveryNotes)
                .frame(minHeight: 80)
                .padding(8)
                .background(Color.teatowerBg)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.teatowerBorder))
        }
        .sectionCard()
    }

    // MARK: - Save

    private func save() async {
        isSaving = true

        let profile = TeaProfile(
            favoriteTypes: Array(favoriteTypes).sorted(),
            favoriteProducts: currentProfile.favoriteProducts,
            brewingMethod: brewingMethod.isEmpty ? nil : brewingMethod,
            frequency: frequency.isEmpty ? nil : frequency,
            taste: taste,
            caffeinePreference: caffeinePreference.isEmpty ? nil : caffeinePreference,
            discoveryNotes: discoveryNotes.isEmpty ? nil : discoveryNotes
        )

        do {
            try await supabase.updateTeaProfile(profile)
            showSaved = true
            try? await Task.sleep(for: .seconds(1.5))
            dismiss()
        } catch {
            print("Save failed: \(error)")
        }

        isSaving = false
    }
}

// MARK: - Section Card Modifier

extension View {
    func sectionCard() -> some View {
        self
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
