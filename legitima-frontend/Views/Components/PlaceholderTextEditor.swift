import SwiftUI

struct PlaceholderTextEditor: View {
    let placeholder: String
    @Binding var text: String
    let primaryColor: Color
    let minHeight: CGFloat

    var body: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $text)
                .font(.subheadline)
                .foregroundColor(primaryColor)
                .scrollContentBackground(.hidden)
                .frame(minHeight: minHeight)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)

            if text.isEmpty {
                Text(placeholder)
                    .font(.subheadline)
                    .foregroundColor(primaryColor.opacity(0.7))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 18)
                    .allowsHitTesting(false)
            }
        }
        .background(Color.white)
        .cornerRadius(12)
    }
}
