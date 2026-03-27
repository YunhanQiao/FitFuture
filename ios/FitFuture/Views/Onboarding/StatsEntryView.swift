import SwiftUI

struct StatsEntryView: View {
    @ObservedObject var vm: OnboardingViewModel

    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 8) {
                Text("Your Current Stats")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                Text("Helps the AI create a realistic transformation.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding(.top, 60)

            VStack(spacing: 16) {
                StatFieldView(label: "Height (cm)", placeholder: "e.g. 175", value: $vm.height, keyboard: .numberPad)
                StatFieldView(label: "Weight (kg)", placeholder: "e.g. 80", value: $vm.weight, keyboard: .decimalPad)
                StatFieldView(label: "Body Fat % (optional)", placeholder: "e.g. 22", value: $vm.bodyFat, keyboard: .decimalPad)
            }

            Spacer()

            Button {
                vm.advance()
            } label: {
                Text("Next")
                    .font(.headline)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(vm.height.isEmpty || vm.weight.isEmpty ? .white.opacity(0.3) : .white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(vm.height.isEmpty || vm.weight.isEmpty)
            .padding(.bottom, 48)
        }
        .padding(.horizontal, 24)
        .background(Color.black.ignoresSafeArea())
    }
}

private struct StatFieldView: View {
    let label: String
    let placeholder: String
    @Binding var value: String
    let keyboard: UIKeyboardType

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(.caption.bold())
                .foregroundStyle(.white.opacity(0.5))
            TextField(placeholder, text: $value)
                .keyboardType(keyboard)
                .foregroundStyle(.white)
                .padding()
                .background(.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}
