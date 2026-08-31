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

    // Le découpage vient de TemplateFilling, le même que celui du PDF : le
    // trou souligné qu'on voit ici est, mot pour mot et signe pour signe,
    // celui qu'on retrouvera dans le document.
    private var rendered: AttributedString {
        var output = AttributedString()
        for segment in TemplateFilling.segments(template, filled: slots.values) {
            var piece = AttributedString(segment.text)
            switch segment.kind {
            case .literal:
                break
            case .filled:
                piece.font = .body.weight(.semibold)
                piece.foregroundColor = LegitimaColors.ink
            case .empty:
                piece.foregroundColor = LegitimaColors.accent
                piece.underlineStyle = .single
            }
            output.append(piece)
        }
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
    @State private var isImportingCV = false
    @State private var isPastingOffer = false

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
                        .stroke(LegitimaColors.fieldBorder, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: LegitimaRadius.control))

                // Le raccourci n'est proposé que là où il remplit vraiment
                // quelque chose. On ne demande jamais un CV en amont « au cas
                // où » : seulement devant un blanc qu'il peut combler.
                if SlotVocabulary.filledByCV.contains(slot) {
                    Button {
                        isImportingCV = true
                    } label: {
                        Label("Remplir depuis mon CV", systemImage: "doc.text")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(LegitimaColors.accent)
                    }
                    Text("Votre CV remplira aussi les autres blancs qu'il contient.")
                        .font(.footnote)
                        .foregroundColor(LegitimaColors.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if slot == SlotVocabulary.filledByOffer {
                    Button {
                        isPastingOffer = true
                    } label: {
                        Label("Coller l'offre d'emploi", systemImage: "doc.on.clipboard")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(LegitimaColors.accent)
                    }
                }

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
        .sheet(isPresented: $isImportingCV) {
            CVImportFlowSheet(
                onUseSummary: { _ in },
                onUseExperiences: { experiences in
                    for (name, value) in SlotAutofill.values(from: experiences) {
                        slots.set(value, for: name)
                    }
                    draft = slots.value(for: slot) ?? draft
                },
                // La matière reste sur l'appareil : elle ne repartira vers le
                // serveur que si la personnalisation est demandée.
                onUseMaterial: { material in
                    ProtectedJSONStore<CVMaterial>.cvMaterial.save(material)
                },
                introText: "Nous en tirerons vos postes, vos entreprises et votre ancienneté. Vous pourrez tout corriger.",
                applyButtonTitle: "Remplir mes réponses"
            )
        }
        .sheet(isPresented: $isPastingOffer) {
            OfferMissionPicker { mission in
                draft = mission
            }
        }
    }
}

extension String: @retroactive Identifiable {
    public var id: String { self }
}

/// Coller une annonce, puis choisir la mission qui compte.
///
/// Le découpage est fait sur l'appareil et la personne choisit : rien n'est
/// envoyé nulle part, et rien ne peut lui être attribué qu'elle n'ait retenu.
struct OfferMissionPicker: View {
    let onPick: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var offer = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Collez l'offre")
                        .font(.system(.title2, design: .rounded).weight(.bold))
                        .foregroundColor(LegitimaColors.ink)

                    Text("Nous en sortons les missions. Vous choisissez celle sur laquelle vous voulez répondre.")
                        .font(.subheadline)
                        .foregroundColor(LegitimaColors.muted)
                        .fixedSize(horizontal: false, vertical: true)

                    PlaceholderTextEditor(
                        placeholder: "Collez le texte de l'annonce",
                        text: $offer,
                        primaryColor: LegitimaColors.ink,
                        minHeight: 160
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: LegitimaRadius.control)
                            .stroke(LegitimaColors.fieldBorder, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: LegitimaRadius.control))

                    let missions = SlotAutofill.missions(in: offer)
                    if !missions.isEmpty {
                        Text("Missions trouvées")
                            .font(.caption.weight(.bold))
                            .foregroundColor(LegitimaColors.accent)

                        ForEach(missions, id: \.self) { mission in
                            Button {
                                onPick(mission)
                                dismiss()
                            } label: {
                                Text(mission)
                                    .font(.subheadline)
                                    .foregroundColor(LegitimaColors.ink)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .padding(14)
                                    .background(LegitimaColors.chip)
                                    .clipShape(RoundedRectangle(cornerRadius: LegitimaRadius.control))
                            }
                            .buttonStyle(.plain)
                        }
                    } else if !offer.isEmpty {
                        Text("Aucune mission repérée. Écrivez-la vous-même dans le champ précédent.")
                            .font(.footnote)
                            .foregroundColor(LegitimaColors.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(22)
            }
            .background(LegitimaColors.surfaceStrong.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
            }
        }
    }
}
