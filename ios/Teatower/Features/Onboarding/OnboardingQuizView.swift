import SwiftUI

/// First-time user quiz that builds the Tea Profile in 4 steps.
/// Shown once after login if tea_profile is empty.
struct OnboardingQuizView: View {
    @Environment(SupabaseManager.self) private var supabase
    @Environment(\.dismiss) private var dismiss

    @State private var step = 0
    @State private var selectedTypes: Set<String> = []
    @State private var taste = TastePreferences()
    @State private var brewingMethod = ""
    @State private var frequency = ""
    @State private var caffeinePreference = ""
    @State private var isSaving = false

    private let totalSteps = 4

    var body: some View {
        ZStack {
            Color.teatowerBg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress bar
                progressBar

                // Content
                TabView(selection: $step) {
                    stepWelcome.tag(0)
                    stepTypes.tag(1)
                    stepTaste.tag(2)
                    stepHabits.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: step)

                // Bottom navigation
                bottomNav
            }
        }
        .interactiveDismissDisabled()
    }

    // MARK: - Progress

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.teatowerBorder)
                    .frame(height: 4)
                Rectangle()
                    .fill(Color.teatowerGreen)
                    .frame(width: geo.size.width * CGFloat(step + 1) / CGFloat(totalSteps), height: 4)
                    .animation(.spring, value: step)
            }
        }
        .frame(height: 4)
    }

    // MARK: - Step 0: Welcome

    private var stepWelcome: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("🍵")
                .font(.system(size: 72))

            Text("Bienvenue chez\nTeatower")
                .font(.teatowerTitle)
                .foregroundStyle(.teatowerGreen)
                .multilineTextAlignment(.center)

            Text("En 4 questions, on crée votre\n**Tea Profile** personnalisé.")
                .font(.system(size: 17))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 12) {
                benefitRow("sparkles", "Recommandations sur mesure")
                benefitRow("trophy.fill", "Badges à collectionner")
                benefitRow("bell.fill", "Alertes sur vos thés préférés")
            }
            .padding(.top, 8)

            Spacer()
        }
        .padding(32)
    }

    private func benefitRow(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.teatowerBrown)
                .frame(width: 24)
            Text(text)
                .font(.system(size: 15))
                .foregroundStyle(.primary)
        }
    }

    // MARK: - Step 1: Tea Types

    private let teaTypes: [(String, String)] = [
        ("Thé vert", "🍃"), ("Thé noir", "🫖"), ("Matcha", "🍵"),
        ("Infusions fruits", "🍓"), ("Infusions plantes", "🌿"), ("Rooibos", "🌺"),
        ("Thé blanc", "🤍"), ("Détox", "💚"), ("Thés glacés", "🧊"), ("Oolong", "🏮"),
    ]

    private var stepTypes: some View {
        VStack(spacing: 20) {
            Text("Qu'est-ce qui vous\nfait envie ?")
                .font(.teatowerTitle)
                .foregroundStyle(.teatowerGreen)
                .multilineTextAlignment(.center)
                .padding(.top, 32)

            Text("Sélectionnez tout ce qui vous plaît")
                .font(.teatowerCaption)
                .foregroundStyle(.teatowerMuted)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 10)], spacing: 10) {
                ForEach(teaTypes, id: \.0) { name, emoji in
                    let selected = selectedTypes.contains(name)
                    Button {
                        if selected { selectedTypes.remove(name) }
                        else { selectedTypes.insert(name) }
                    } label: {
                        HStack(spacing: 8) {
                            Text(emoji).font(.system(size: 20))
                            Text(name).font(.system(size: 14, weight: selected ? .bold : .regular))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(selected ? Color.teatowerGreen : .white)
                        .foregroundStyle(selected ? .white : .primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(selected ? Color.clear : Color.teatowerBorder))
                    }
                    .buttonStyle(.plain)
                    .scaleEffect(selected ? 1.03 : 1)
                    .animation(.spring(duration: 0.2), value: selected)
                }
            }
            .padding(.horizontal, 8)

            Spacer()
        }
        .padding(24)
    }

    // MARK: - Step 2: Taste

    private var stepTaste: some View {
        VStack(spacing: 20) {
            Text("Votre palais")
                .font(.teatowerTitle)
                .foregroundStyle(.teatowerGreen)
                .padding(.top, 32)

            Text("Positionnez les curseurs selon vos goûts")
                .font(.teatowerCaption)
                .foregroundStyle(.teatowerMuted)

            VStack(spacing: 20) {
                quizSlider("🍯 Sucré", value: tasteBinding(\.sweet))
                quizSlider("🍵 Amer", value: tasteBinding(\.bitter))
                quizSlider("🌸 Floral", value: tasteBinding(\.floral))
                quizSlider("🌶️ Épicé", value: tasteBinding(\.spicy))
                quizSlider("🍑 Fruité", value: tasteBinding(\.fruity))
                quizSlider("🌿 Terreux", value: tasteBinding(\.earthy))
            }
            .padding(20)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            Spacer()
        }
        .padding(24)
    }

    private func quizSlider(_ label: String, value: Binding<Double>) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 14))
                .frame(width: 90, alignment: .leading)
            Slider(value: value, in: 0...5, step: 1) {
                EmptyView()
            } minimumValueLabel: {
                Text("0").font(.system(size: 10)).foregroundStyle(.teatowerMuted)
            } maximumValueLabel: {
                Text("5").font(.system(size: 10)).foregroundStyle(.teatowerMuted)
            }
            .tint(.teatowerGreen)

            ZStack {
                Circle()
                    .fill(Color.teatowerGreen)
                    .frame(width: 28, height: 28)
                Text("\(Int(value.wrappedValue))")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
    }

    private func tasteBinding(_ keyPath: WritableKeyPath<TastePreferences, Int?>) -> Binding<Double> {
        Binding(
            get: { Double(taste[keyPath: keyPath] ?? 3) },
            set: { taste[keyPath: keyPath] = Int($0) }
        )
    }

    // MARK: - Step 3: Habits

    private let methods = [
        ("Infusettes", "teabag", "☕"), ("Vrac en théière", "teapot", "🫖"),
        ("Infuseur", "filter", "🍵"), ("Cold brew", "cold", "🧊"), ("Matcha fouet", "matcha", "🥋"),
    ]
    private let freqs = [
        ("Chaque jour", "daily"), ("Plusieurs fois/sem.", "weekly"), ("Occasionnel", "occasional"), ("Débutant(e)", "beginner"),
    ]
    private let caffeines = [
        ("Avec théine ☀️", "with"), ("Sans théine le soir 🌙", "evening_free"), ("Jamais de théine 🚫", "never"), ("Pas de préférence 🤷", "any"),
    ]

    private var stepHabits: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Vos habitudes")
                    .font(.teatowerTitle)
                    .foregroundStyle(.teatowerGreen)
                    .padding(.top, 32)

                // Method
                VStack(alignment: .leading, spacing: 10) {
                    Text("Comment préparez-vous ?")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)

                    FlowLayout(spacing: 8) {
                        ForEach(methods, id: \.1) { label, key, emoji in
                            chipButton("\(emoji) \(label)", isSelected: brewingMethod == label) {
                                brewingMethod = label
                            }
                        }
                    }
                }

                // Frequency
                VStack(alignment: .leading, spacing: 10) {
                    Text("À quelle fréquence ?")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)

                    FlowLayout(spacing: 8) {
                        ForEach(freqs, id: \.1) { label, _ in
                            chipButton(label, isSelected: frequency == label) {
                                frequency = label
                            }
                        }
                    }
                }

                // Caffeine
                VStack(alignment: .leading, spacing: 10) {
                    Text("Et la théine ?")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)

                    FlowLayout(spacing: 8) {
                        ForEach(caffeines, id: \.1) { label, _ in
                            chipButton(label, isSelected: caffeinePreference == label) {
                                caffeinePreference = label
                            }
                        }
                    }
                }

                Spacer(minLength: 80)
            }
            .padding(24)
        }
    }

    private func chipButton(_ label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: isSelected ? .bold : .regular))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(isSelected ? Color.teatowerGreen : .white)
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(isSelected ? Color.clear : Color.teatowerBorder))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Bottom Navigation

    private var bottomNav: some View {
        HStack {
            if step > 0 {
                Button {
                    withAnimation { step -= 1 }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Retour")
                    }
                    .font(.system(size: 15))
                    .foregroundStyle(.teatowerMuted)
                }
            }

            Spacer()

            if step < totalSteps - 1 {
                Button {
                    withAnimation { step += 1 }
                } label: {
                    HStack(spacing: 4) {
                        Text(step == 0 ? "C'est parti" : "Suivant")
                        Image(systemName: "chevron.right")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.teatowerGreen)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                }
            } else {
                Button(action: { Task { await saveProfile() } }) {
                    HStack(spacing: 6) {
                        if isSaving {
                            ProgressView().tint(.white)
                        } else {
                            Text("Créer mon profil")
                            Image(systemName: "sparkles")
                        }
                    }
                    .font(.system(size: 15, weight: .bold))
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(Color.teatowerGreen)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                }
                .disabled(isSaving)
            }
        }
        .padding(20)
        .background(.white.shadow(.drop(color: .black.opacity(0.05), radius: 8, y: -4)))
    }

    // MARK: - Save

    private func saveProfile() async {
        isSaving = true

        let profile = TeaProfile(
            favoriteTypes: Array(selectedTypes).sorted(),
            favoriteProducts: nil,
            brewingMethod: brewingMethod.isEmpty ? nil : brewingMethod,
            frequency: frequency.isEmpty ? nil : frequency,
            taste: taste,
            caffeinePreference: caffeinePreference.isEmpty ? nil : caffeinePreference,
            discoveryNotes: nil
        )

        do {
            try await supabase.updateTeaProfile(profile)
            // Mark source_app = true
            try await supabase.client
                .from("audience")
                .update(["source_app": true])
                .eq("email", value: supabase.currentEmail ?? "")
                .execute()
            dismiss()
        } catch {
            print("Onboarding save failed: \(error)")
        }

        isSaving = false
    }
}
