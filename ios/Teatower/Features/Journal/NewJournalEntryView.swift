import SwiftUI

struct NewJournalEntryView: View {
    @Environment(SupabaseManager.self) private var supabase
    @Environment(\.dismiss) private var dismiss

    @State private var teaName = ""
    @State private var rating = 3
    @State private var notes = ""
    @State private var brewTemp = 85
    @State private var brewMinutes = 3
    @State private var brewSeconds = 0
    @State private var teaGrams = 3.0
    @State private var waterMl = 250
    @State private var selectedMoods: Set<String> = []
    @State private var selectedMoment = ""
    @State private var isFavorite = false
    @State private var isSaving = false
    @State private var step = 0

    var body: some View {
        NavigationStack {
            TabView(selection: $step) {
                stepTea.tag(0)
                stepBrew.tag(1)
                stepVibes.tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .background(Color.teatowerBg)
            .navigationTitle(stepTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if step == 2 {
                        Button(action: { Task { await save() } }) {
                            if isSaving { ProgressView().tint(.teatowerGreen) }
                            else { Text("Sauver").fontWeight(.semibold) }
                        }
                        .disabled(teaName.isEmpty || isSaving)
                    } else {
                        Button("Suivant") { withAnimation { step += 1 } }
                            .disabled(step == 0 && teaName.isEmpty)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                // Step dots
                HStack(spacing: 8) {
                    ForEach(0..<3) { i in
                        Circle()
                            .fill(i == step ? Color.teatowerGreen : Color.teatowerBorder)
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.bottom, 8)
            }
        }
    }

    private var stepTitle: String {
        switch step {
        case 0: return "Le thé"
        case 1: return "L'infusion"
        case 2: return "L'ambiance"
        default: return ""
        }
    }

    // MARK: - Step 0: Tea + Rating

    private var stepTea: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Tea name
                VStack(alignment: .leading, spacing: 8) {
                    Text("Quel thé dégustez-vous ?")
                        .font(.teatowerHeading)
                        .foregroundStyle(.teatowerGreen)

                    TextField("Nom du thé ou de l'infusion", text: $teaName)
                        .font(.system(size: 16))
                        .padding()
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Rating
                VStack(spacing: 12) {
                    Text("Votre note")
                        .font(.teatowerHeading)
                        .foregroundStyle(.teatowerGreen)

                    HStack(spacing: 12) {
                        ForEach(1...5, id: \.self) { star in
                            Button {
                                withAnimation(.spring(duration: 0.2)) { rating = star }
                            } label: {
                                Image(systemName: star <= rating ? "star.fill" : "star")
                                    .font(.system(size: 36))
                                    .foregroundStyle(star <= rating ? Color(hex: "FFB300") : Color.teatowerBorder)
                                    .scaleEffect(star <= rating ? 1.1 : 1.0)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Text(ratingLabel)
                        .font(.teatowerCaption)
                        .foregroundStyle(.teatowerMuted)
                }

                // Favorite
                Toggle(isOn: $isFavorite) {
                    Label("Ajouter aux favoris", systemImage: isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(isFavorite ? .red : .primary)
                }
                .tint(.red)
                .padding()
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Notes
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes de dégustation")
                        .font(.teatowerCaption)
                        .foregroundStyle(.teatowerMuted)
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                        .padding(8)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.teatowerBorder))
                }
            }
            .padding(24)
        }
    }

    private var ratingLabel: String {
        switch rating {
        case 1: return "Pas pour moi"
        case 2: return "Bof"
        case 3: return "Correct"
        case 4: return "Très bien"
        case 5: return "Coup de coeur"
        default: return ""
        }
    }

    // MARK: - Step 1: Brewing

    private var stepBrew: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Paramètres d'infusion")
                    .font(.teatowerHeading)
                    .foregroundStyle(.teatowerGreen)

                // Temperature
                VStack(spacing: 8) {
                    HStack {
                        Text("🌡️ Température")
                            .font(.system(size: 14, weight: .semibold))
                        Spacer()
                        Text("\(brewTemp)°C")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.teatowerGreen)
                    }
                    Slider(value: Binding(get: { Double(brewTemp) }, set: { brewTemp = Int($0) }), in: 50...100, step: 5)
                        .tint(.teatowerGreen)
                    HStack {
                        Text("50°").font(.system(size: 10)).foregroundStyle(.teatowerMuted)
                        Spacer()
                        Text("Vert/Blanc").font(.system(size: 9)).foregroundStyle(.teatowerMuted)
                        Spacer()
                        Text("Noir/Infusion").font(.system(size: 9)).foregroundStyle(.teatowerMuted)
                        Spacer()
                        Text("100°").font(.system(size: 10)).foregroundStyle(.teatowerMuted)
                    }
                }
                .padding()
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Time
                VStack(spacing: 8) {
                    HStack {
                        Text("⏱️ Durée d'infusion")
                            .font(.system(size: 14, weight: .semibold))
                        Spacer()
                        Text("\(brewMinutes)m\(brewSeconds > 0 ? "\(brewSeconds)s" : "")")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.teatowerGreen)
                    }
                    HStack {
                        Stepper("Min", value: $brewMinutes, in: 0...15)
                            .labelsHidden()
                        Text("\(brewMinutes) min")
                            .frame(width: 60)
                        Stepper("Sec", value: $brewSeconds, in: 0...45, step: 15)
                            .labelsHidden()
                        Text("\(brewSeconds) sec")
                            .frame(width: 60)
                    }
                }
                .padding()
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Amounts
                HStack(spacing: 12) {
                    VStack(spacing: 8) {
                        Text("🍃 Thé").font(.system(size: 13, weight: .semibold))
                        Stepper("\(teaGrams, specifier: "%.1f")g", value: $teaGrams, in: 0.5...20, step: 0.5)
                            .font(.system(size: 13))
                    }
                    .padding()
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    VStack(spacing: 8) {
                        Text("💧 Eau").font(.system(size: 13, weight: .semibold))
                        Stepper("\(waterMl)ml", value: $waterMl, in: 100...500, step: 50)
                            .font(.system(size: 13))
                    }
                    .padding()
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(24)
        }
    }

    // MARK: - Step 2: Mood & Moment

    private var stepVibes: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Mood
                VStack(alignment: .leading, spacing: 12) {
                    Text("Comment vous sentez-vous ?")
                        .font(.teatowerHeading)
                        .foregroundStyle(.teatowerGreen)

                    FlowLayout(spacing: 8) {
                        ForEach(JournalEntry.moods, id: \.self) { mood in
                            let selected = selectedMoods.contains(mood)
                            Button {
                                if selected { selectedMoods.remove(mood) }
                                else { selectedMoods.insert(mood) }
                            } label: {
                                Text(mood)
                                    .font(.system(size: 13, weight: selected ? .bold : .regular))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(selected ? Color.teatowerGreen : .white)
                                    .foregroundStyle(selected ? .white : .primary)
                                    .clipShape(Capsule())
                                    .overlay(Capsule().stroke(selected ? Color.clear : Color.teatowerBorder))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Moment
                VStack(alignment: .leading, spacing: 12) {
                    Text("Le moment")
                        .font(.teatowerHeading)
                        .foregroundStyle(.teatowerGreen)

                    FlowLayout(spacing: 8) {
                        ForEach(JournalEntry.moments, id: \.self) { moment in
                            let selected = selectedMoment == moment
                            Button {
                                selectedMoment = selected ? "" : moment
                            } label: {
                                Text(moment)
                                    .font(.system(size: 13, weight: selected ? .bold : .regular))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(selected ? Color.teatowerBrown : .white)
                                    .foregroundStyle(selected ? .white : .primary)
                                    .clipShape(Capsule())
                                    .overlay(Capsule().stroke(selected ? Color.clear : Color.teatowerBorder))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Summary
                VStack(alignment: .leading, spacing: 8) {
                    Text("Résumé").font(.teatowerCaption).foregroundStyle(.teatowerMuted)
                    HStack {
                        Text(teaName.isEmpty ? "—" : teaName).fontWeight(.semibold)
                        Spacer()
                        Text(String(repeating: "★", count: rating)).foregroundStyle(Color(hex: "FFB300"))
                    }
                    if !notes.isEmpty {
                        Text(notes).font(.system(size: 12)).foregroundStyle(.secondary).lineLimit(2)
                    }
                    Text("\(brewTemp)°C · \(brewMinutes)m · \(teaGrams, specifier: "%.1f")g · \(waterMl)ml")
                        .font(.system(size: 12)).foregroundStyle(.teatowerBrown)
                }
                .padding()
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(24)
        }
    }

    // MARK: - Save

    private func save() async {
        isSaving = true

        let entry = JournalEntry(
            email: supabase.currentEmail,
            teaName: teaName,
            rating: rating,
            notes: notes.isEmpty ? nil : notes,
            brewTempCelsius: brewTemp,
            brewTimeSeconds: brewMinutes * 60 + brewSeconds,
            waterAmountMl: waterMl,
            teaAmountGrams: teaGrams,
            mood: selectedMoods.isEmpty ? nil : Array(selectedMoods),
            moment: selectedMoment.isEmpty ? nil : selectedMoment,
            isFavorite: isFavorite
        )

        do {
            try await supabase.client
                .from("journal_entries")
                .insert(entry)
                .execute()
            dismiss()
        } catch {
            print("Journal save failed: \(error)")
        }

        isSaving = false
    }
}
