import SwiftUI

/// Second premium usage, the day after the interview: capture what actually
/// happened in the room. What lands here feeds the next preparation, which is
/// what turns one purchase into the next.
struct InterviewDebriefSheet: View {
    @Environment(\.dismiss) private var dismiss

    let initialDebrief: InterviewDebrief?
    let onSave: (InterviewDebrief) -> Void

    @State private var difficultQuestions: String = ""
    @State private var whatWorked: String = ""

    private var canSave: Bool {
        !difficultQuestions.trimmed.isEmpty || !whatWorked.trimmed.isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(light: .rgb(222, 248, 244), dark: LegitimaColors.darkBackgroundTop),
                        Color(light: .rgb(245, 239, 231), dark: LegitimaColors.darkBackgroundBottom)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        JustifiedText(
                            "À chaud, ce que vous notez maintenant sert de matière à votre prochaine préparation.",
                            color: LegitimaColors.muted
                        )

                        field(
                            title: "Quelles questions vous ont mis en difficulté ?",
                            placeholder: "Les questions auxquelles vous n'aviez pas de réponse prête…",
                            text: $difficultQuestions
                        )

                        field(
                            title: "Qu'est-ce qui a bien fonctionné ?",
                            placeholder: "Les moments où votre récit a porté…",
                            text: $whatWorked
                        )

                        Button(action: save) {
                            Text("Enregistrer mon débrief")
                                .legitimaPrimaryLabel()
                        }
                        .disabled(!canSave)
                        .opacity(canSave ? 1 : 0.5)
                    }
                    .frame(maxWidth: 720)
                    .padding(22)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Débrief d'entretien")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
        .onAppear {
            difficultQuestions = initialDebrief?.difficultQuestions ?? ""
            whatWorked = initialDebrief?.whatWorked ?? ""
        }
    }

    private func field(
        title: String,
        placeholder: String,
        text: Binding<String>
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundColor(LegitimaColors.ink)

            PlaceholderTextEditor(
                placeholder: placeholder,
                text: text,
                primaryColor: LegitimaColors.ink,
                minHeight: 110
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(LegitimaColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: LegitimaRadius.card))
    }

    private func save() {
        onSave(
            InterviewDebrief(
                difficultQuestions: difficultQuestions.trimmed,
                whatWorked: whatWorked.trimmed,
                recordedAt: .now
            )
        )
        dismiss()
    }
}
