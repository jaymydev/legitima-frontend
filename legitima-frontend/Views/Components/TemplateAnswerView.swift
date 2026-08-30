import SwiftUI

/// Un gabarit affiché avec ses blancs.
///
/// Un blanc rempli se lit comme le reste de la phrase, en gras. Un blanc vide
/// s'affiche par son libellé — « votre réalisation » — souligné et en couleur,
/// pour qu'on voie que c'est à soi de le mettre et non que la variable a raté.
///
/// Le texte n'est pas tapable ligne à ligne : les blancs restants sont proposés
/// en pastilles sous la réponse, ce qui donne une cible large et évite de courir
/// après un mot au milieu d'un paragraphe.
struct TemplateAnswerView: View {
    let template: String
    @EnvironmentObject private var slots: SlotStore
    @State private var editing: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(rendered)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)

            let remaining = slots.unfilled(in: template)
            if !remaining.isEmpty {
                RecruitmentFlowLayout(spacing: 8) {
                    ForEach(remaining, id: \.self) { slot in
                        Button {
                            editing = slot
                        } label: {
                            Label(SlotVocabulary.label(for: slot), systemImage: "square.and.pencil")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(LegitimaColors.accent)
                                .padding(.horizontal, 11)
                                .padding(.vertical, 7)
                                .background(LegitimaColors.chip)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .sheet(item: $editing) { slot in
            SlotEditorSheet(slot: slot)
                .environmentObject(slots)
        }
    }

    private var rendered: AttributedString {
        var output = AttributedString()
        var remainder = Substring(template)

        while let open = remainder.firstIndex(of: "<"),
              let close = remainder[open...].firstIndex(of: ">") {
            output.append(AttributedString(String(remainder[..<open])))

            let name = String(remainder[remainder.index(after: open)..<close])
            var piece: AttributedString
            if let filled = slots.value(for: name) {
                piece = AttributedString(filled)
                piece.font = .body.weight(.semibold)
                piece.foregroundColor = LegitimaColors.ink
            } else {
                piece = AttributedString(SlotVocabulary.label(for: name))
                piece.foregroundColor = LegitimaColors.accent
                piece.underlineStyle = .single
            }
            output.append(piece)
            remainder = remainder[remainder.index(after: close)...]
        }

        output.append(AttributedString(String(remainder)))
        return output
    }
}

/// Remplir un blanc, une fois. Il se remplit alors partout, et pour les fois
/// suivantes.
struct SlotEditorSheet: View {
    let slot: String
    @EnvironmentObject private var slots: SlotStore
    @Environment(\.dismiss) private var dismiss
    @State private var draft = ""

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text(SlotVocabulary.label(for: slot).capitalizedFirst)
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundColor(LegitimaColors.ink)

                Text("Vous ne le saisirez qu'une fois. Il se remplira partout, y compris dans vos prochaines préparations.")
                    .font(.subheadline)
                    .foregroundColor(LegitimaColors.muted)
                    .fixedSize(horizontal: false, vertical: true)

                if SlotVocabulary.neverSpoken.contains(slot) {
                    Label(
                        "Cette information ne sera jamais écrite dans une réponse. Elle vous sert à vous, pas à ce que vous direz.",
                        systemImage: "lock.fill"
                    )
                    .font(.footnote)
                    .foregroundColor(LegitimaColors.muted)
                    .fixedSize(horizontal: false, vertical: true)
                }

                PlaceholderTextEditor(
                    placeholder: "Écrivez ici",
                    text: $draft,
                    primaryColor: LegitimaColors.ink,
                    minHeight: 120
                )
                // Ce qu'on écrit ici s'insère au milieu d'une phrase. Laisser le
                // clavier mettre une majuscule donnait « j'ai fait La refonte du
                // site », ce qui se voit immédiatement à la lecture.
                .textInputAutocapitalization(.never)
                .overlay(
                    RoundedRectangle(cornerRadius: LegitimaRadius.control)
                        .stroke(LegitimaColors.hairline, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: LegitimaRadius.control))

                Text("Cette information reste sur votre téléphone.")
                    .font(.footnote)
                    .foregroundColor(LegitimaColors.muted)

                Spacer(minLength: 0)

                Button {
                    slots.set(draft, for: slot)
                    dismiss()
                } label: {
                    Text("Enregistrer").legitimaPrimaryLabel()
                }
            }
            .padding(22)
            .background(LegitimaColors.surfaceStrong.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
            }
        }
        .onAppear { draft = slots.value(for: slot) ?? "" }
    }
}

extension String: @retroactive Identifiable {
    public var id: String { self }
}

extension String {
    var capitalizedFirst: String {
        guard let first else { return self }
        return first.uppercased() + dropFirst()
    }
}
