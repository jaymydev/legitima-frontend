import PhotosUI
import SwiftUI
import UniformTypeIdentifiers
import UIKit

private struct EditableCVStep: Identifiable {
    let id = UUID()
    var text: String
}

private enum CVImportFlowState {
    case sourceSelection
    case extracting
    case review
}

struct CVImportFlowSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var flowState: CVImportFlowState = .sourceSelection
    @State private var isShowingFileImporter = false
    @State private var isShowingCamera = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var extractedSteps: [EditableCVStep] = []
    /// Les lignes non modifiées, gardées à part : elles servent à remplir des
    /// balises, où l'intitulé et la société doivent rester séparés.
    @State private var extractedExperiences: [CVExperienceRow] = []
    @State private var extractedRawText = ""
    @State private var errorMessage: String?

    private let cvImportService = CVImportService()
    let onUseSummary: (String) -> Void
    var onUseExperiences: ([CVExperienceRow]) -> Void = { _ in }
    /// La matière complète — lignes et texte brut — pour qui veut la garder.
    /// Un seul appel plutôt que deux : la matière se stocke d'un bloc.
    var onUseMaterial: (CVMaterial) -> Void = { _ in }
    var introText: String = "Nous allons extraire les étapes les plus utiles de votre parcours. Vous pourrez tout corriger avant de continuer."
    var applyButtonTitle: String = "Utiliser ces étapes"
    var reviewFootnote: String = "Vous pourrez encore ajuster ce texte dans l'écran précédent avant de continuer."

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(light: .rgb(207, 252, 249), dark: LegitimaColors.darkBackgroundTop),
                        Color(light: .rgb(237, 243, 243), dark: LegitimaColors.darkBackgroundBottom)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        switch flowState {
                        case .sourceSelection:
                            sourceSelectionContent
                        case .extracting:
                            extractingContent
                        case .review:
                            reviewContent
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 28)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        if flowState == .review {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                flowState = .sourceSelection
                            }
                        } else {
                            dismiss()
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(LegitimaColors.ink)
                    }
                }
            }
        }
        .fileImporter(
            isPresented: $isShowingFileImporter,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: false
        ) { result in
            Task {
                await handlePDFSelection(result)
            }
        }
        .onChange(of: selectedPhoto) { _, newValue in
            guard let newValue else { return }

            Task {
                await handlePhotoSelection(newValue)
            }
        }
        .sheet(isPresented: $isShowingCamera) {
            CameraCaptureView(
                onImagePicked: { image in
                    isShowingCamera = false
                    Task {
                        await handleCapturedImage(image)
                    }
                },
                onCancel: {
                    isShowingCamera = false
                }
            )
            .ignoresSafeArea()
        }
    }

    private var sourceSelectionContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Importer votre CV")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(LegitimaColors.ink)

                Text(introText)
                    .font(.subheadline)
                    .foregroundColor(LegitimaColors.muted)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Vous pouvez importer un PDF, prendre une photo du CV ou choisir une image depuis votre photothèque. Nous extrairons ensuite les expériences avant que vous puissiez les corriger.")
                    .font(.footnote)
                    .foregroundColor(LegitimaColors.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            illustrationCard

            VStack(spacing: 14) {
                sourceButton(
                    icon: "doc.text",
                    title: "Choisir un PDF"
                ) {
                    errorMessage = nil
                    isShowingFileImporter = true
                }

                PhotosPicker(
                    selection: $selectedPhoto,
                    matching: .images
                ) {
                    sourceButtonLabel(
                        icon: "photo.on.rectangle",
                        title: "Choisir une image"
                    )
                }
                .buttonStyle(.plain)

                sourceButton(
                    icon: "camera",
                    title: "Prendre une photo"
                ) {
                    guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
                        errorMessage = CVImportServiceError.noCameraAvailable.localizedDescription
                        return
                    }

                    errorMessage = nil
                    isShowingCamera = true
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundColor(.red)
            }

            Button("Plus tard") {
                dismiss()
            }
            .font(.headline)
            .foregroundColor(LegitimaColors.accent)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 4)
        }
    }

    private var extractingContent: some View {
        VStack(spacing: 18) {
            ProgressView()
                .tint(LegitimaColors.accent)
                .scaleEffect(1.2)

            Text("Préparation de votre résumé")
                .font(.title3.weight(.semibold))
                .foregroundColor(LegitimaColors.ink)

            Text("Nous extrayons les étapes les plus utiles pour comprendre votre trajectoire.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(LegitimaColors.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .background(LegitimaColors.surface)
        .cornerRadius(LegitimaRadius.hero)
        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 6)
        .padding(.top, 80)
    }

    private var reviewContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Vérifiez les étapes retenues")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(LegitimaColors.ink)

                Text("Nous avons extrait les étapes les plus utiles pour comprendre votre trajectoire.")
                    .font(.subheadline)
                    .foregroundColor(LegitimaColors.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: 12) {
                ForEach(Array(extractedSteps.indices), id: \.self) { index in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1).")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(LegitimaColors.accent)
                            .frame(width: 22, alignment: .leading)

                        TextField("", text: $extractedSteps[index].text)
                            .textInputAutocapitalization(.sentences)
                            .foregroundColor(LegitimaColors.ink)
                    }
                    .padding(14)
                    .background(LegitimaColors.field)
                    .overlay(
                        RoundedRectangle(cornerRadius: LegitimaRadius.control)
                            .stroke(LegitimaColors.fieldBorder, lineWidth: 1)
                    )
                    .cornerRadius(LegitimaRadius.control)
                }
            }
            .padding(16)
            .background(LegitimaColors.surface)
            .cornerRadius(LegitimaRadius.card)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)

            Text(reviewFootnote)
                .font(.footnote)
                .foregroundColor(LegitimaColors.muted)

            Button(action: useImportedSummary) {
                Text(applyButtonTitle)
                    .legitimaPrimaryLabel()
            }

            Button("Choisir un autre document") {
                withAnimation(.easeInOut(duration: 0.2)) {
                    errorMessage = nil
                    flowState = .sourceSelection
                }
            }
            .font(.headline)
            .foregroundColor(LegitimaColors.accent)
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private var illustrationCard: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(light: .rgb(231, 246, 244), dark: .rgb(30, 42, 41)))
                    .frame(width: 180, height: 180)

                RoundedRectangle(cornerRadius: LegitimaRadius.card)
                    .fill(LegitimaColors.surfaceStrong)
                    .frame(width: 102, height: 138)
                    .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)

                VStack(alignment: .leading, spacing: 8) {
                    Text("CV")
                        .font(.title3.weight(.bold))
                        .foregroundColor(LegitimaColors.accent)

                    ForEach(0..<5, id: \.self) { _ in
                        Capsule()
                            .fill(Color(light: .rgb(227, 233, 233), dark: .rgb(55, 63, 64)))
                            .frame(width: 54, height: 6)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(LegitimaColors.surface)
        .cornerRadius(LegitimaRadius.hero)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
    }

    private func sourceButton(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            sourceButtonLabel(icon: icon, title: title)
        }
        .buttonStyle(.plain)
    }

    private func sourceButtonLabel(icon: String, title: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .foregroundColor(LegitimaColors.accent)
                .frame(width: 24, height: 24)

            Text(title)
                .font(.headline)
                .foregroundColor(LegitimaColors.ink)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundColor(LegitimaColors.muted)
        }
        .padding(18)
        .background(LegitimaColors.surface)
        .cornerRadius(LegitimaRadius.card)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }

    private func handlePDFSelection(_ result: Result<[URL], Error>) async {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            await extractUsingSource {
                let accessGranted = url.startAccessingSecurityScopedResource()
                defer {
                    if accessGranted {
                        url.stopAccessingSecurityScopedResource()
                    }
                }

                return try await cvImportService.extractSummary(fromPDFAt: url)
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    private func handlePhotoSelection(_ item: PhotosPickerItem) async {
        await extractUsingSource {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                throw CVImportServiceError.unreadableDocument
            }

            return try await cvImportService.extractSummary(from: image, originalData: data)
        }

        await MainActor.run {
            selectedPhoto = nil
        }
    }

    private func handleCapturedImage(_ image: UIImage) async {
        await extractUsingSource {
            try await cvImportService.extractSummary(from: image)
        }
    }

    private func extractUsingSource(
        _ task: @escaping () async throws -> CVImportResult
    ) async {
        await MainActor.run {
            errorMessage = nil
            withAnimation(.easeInOut(duration: 0.2)) {
                flowState = .extracting
            }
        }

        do {
            let result = try await task()

            await MainActor.run {
                extractedSteps = result.steps.map { EditableCVStep(text: $0) }
                extractedExperiences = result.experiences
                extractedRawText = result.rawText
                withAnimation(.easeInOut(duration: 0.2)) {
                    flowState = .review
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                withAnimation(.easeInOut(duration: 0.2)) {
                    flowState = .sourceSelection
                }
            }
        }
    }

    private func useImportedSummary() {
        let cleanedSteps = extractedSteps
            .map { $0.text.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let summary = cleanedSteps.map { "• \($0)" }.joined(separator: "\n")
        onUseSummary(summary)
        onUseExperiences(extractedExperiences)
        onUseMaterial(CVMaterial(rawText: extractedRawText, experiences: extractedExperiences))
        dismiss()
    }
}
