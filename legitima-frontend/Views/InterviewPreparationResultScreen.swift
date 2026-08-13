import SwiftUI

struct InterviewPreparationResultScreen: View {
    @EnvironmentObject private var preparationStore: LocalPreparationStore

    let response: InterviewPreparationResponse
    let onChooseAnother: () -> Void

    @State private var exportURL: URL?
    @State private var isShowingDebrief = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(light: .rgb(222, 248, 244), dark: LegitimaColors.darkBackgroundTop),
                    Color(light: .rgb(245, 239, 231), dark: LegitimaColors.darkBackgroundMid),
                    Color(light: .rgb(235, 241, 247), dark: LegitimaColors.darkBackgroundBottom)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text(response.title)
                        .font(.system(.largeTitle, design: .rounded).weight(.bold))

                    if let daysSince = interviewDaysSince {
                        debriefCard(daysSince: daysSince)
                    }

                    if let kickoff = preparationStore.snapshot.kickoff {
                        kickoffCard(kickoff)
                    }

                    resultCard(title: "Votre ligne directrice", content: response.summary)

                    ForEach(Array(response.sections.enumerated()), id: \.offset) { _, section in
                        resultCard(title: section.title, content: section.content)
                    }

                    listCard(
                        title: "Points à faire passer",
                        icon: "quote.bubble.fill",
                        items: response.talkingPoints
                    )
                    listCard(
                        title: "Plan d’action",
                        icon: "checklist",
                        items: response.actionPlan
                    ) {
                        if let exportURL {
                            ShareLink(item: exportURL) {
                                Label("Exporter mon plan d'action", systemImage: "square.and.arrow.up")
                                    .legitimaPrimaryLabel()
                            }
                            .padding(.top, 4)
                        }
                    }

                    Button(action: onChooseAnother) {
                        Text("Préparer un autre entretien")
                            .legitimaSecondaryLabel()
                    }
                }
                .frame(maxWidth: 720)
                .padding(22)
                .frame(maxWidth: .infinity)
            }
        }
        .task(id: response) {
            exportURL = PreparationPDFExporter.writeTemporaryPDF(
                for: PreparationExportContent(
                    response: response,
                    kickoff: preparationStore.snapshot.kickoff
                )
            )
        }
        .sheet(isPresented: $isShowingDebrief) {
            InterviewDebriefSheet(
                initialDebrief: preparationStore.snapshot.debrief,
                onSave: { preparationStore.saveDebrief($0) }
            )
        }
    }

    /// The answer generated at purchase time. It belongs with the rest of the
    /// preparation rather than living only on the screen that produced it.
    private func kickoffCard(_ kickoff: PremiumKickoffResponse) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Votre première réponse défendable", systemImage: "bolt.shield.fill")
                .font(.headline)
                .foregroundColor(LegitimaColors.ink)

            VStack(alignment: .leading, spacing: 6) {
                Text("LA QUESTION QUI RISQUE DE VENIR")
                    .font(.caption.bold())
                    .foregroundColor(Color(light: .rgb(153, 60, 29), dark: .rgb(240, 153, 123)))
                JustifiedText("« \(kickoff.objection) »", color: LegitimaColors.ink)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("VOTRE RÉPONSE")
                    .font(.caption.bold())
                    .foregroundColor(LegitimaColors.accent)
                JustifiedText(kickoff.defensibleAnswer, color: LegitimaColors.muted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: LegitimaRadius.card)
                .fill(LegitimaColors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: LegitimaRadius.card)
                        .stroke(LegitimaColors.accent.opacity(0.25), lineWidth: 1)
                )
        )
    }

    private var interviewDaysSince: Int? {
        preparationStore.snapshot.interviewDate.flatMap { InterviewCountdown.daysSince($0) }
    }

    /// The day after the interview, the most useful thing on this screen is no
    /// longer the preparation itself but what the room revealed.
    @ViewBuilder
    private func debriefCard(daysSince: Int) -> some View {
        let debrief = preparationStore.snapshot.debrief
        let isRecorded = debrief?.hasContent == true

        VStack(alignment: .leading, spacing: 12) {
            Label(
                isRecorded ? "Débrief enregistré" : InterviewCountdown.pastLabel(daysSince: daysSince),
                systemImage: isRecorded ? "checkmark.seal.fill" : "bubble.left.and.text.bubble.right.fill"
            )
            .font(.headline)
            .foregroundColor(LegitimaColors.ink)

            JustifiedText(
                isRecorded
                    ? "Vos notes serviront de matière à votre prochaine préparation : les questions qui vous ont mis en difficulté seront travaillées en priorité."
                    : "Quelles questions vous ont mis en difficulté ? Ce que vous notez maintenant rendra votre prochaine préparation plus précise.",
                color: LegitimaColors.muted
            )

            Button {
                isShowingDebrief = true
            } label: {
                Text(isRecorded ? "Modifier mon débrief" : "Faire mon débrief")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .foregroundColor(isRecorded ? LegitimaColors.accent : .white)
                    .background(isRecorded ? LegitimaColors.surface : LegitimaColors.accentSurface)
                    .clipShape(RoundedRectangle(cornerRadius: LegitimaRadius.control))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: LegitimaRadius.card)
                .fill(Color(light: .rgb(255, 239, 221), dark: .rgb(46, 39, 28)))
        )
    }

    private func resultCard(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            JustifiedText(content, textStyle: .body, color: LegitimaColors.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(LegitimaColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: LegitimaRadius.card))
    }

    /// `footer` carries the export button into the action-plan card.
    ///
    /// It used to sit on its own below every card, so the gesture that takes the
    /// plan away was separated from the plan itself. Testers read the action plan
    /// as unclear partly for that reason.
    private func listCard<Footer: View>(
        title: String,
        icon: String,
        items: [String],
        @ViewBuilder footer: () -> Footer = { EmptyView() }
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                HStack(alignment: .top, spacing: 10) {
                    Text("\(index + 1)")
                        .font(.caption.bold())
                        .frame(width: 24, height: 24)
                        .background(LegitimaColors.chip)
                        .clipShape(Circle())
                    JustifiedText(item, textStyle: .body, color: LegitimaColors.muted)
                }
            }
            footer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(LegitimaColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: LegitimaRadius.card))
    }
}
