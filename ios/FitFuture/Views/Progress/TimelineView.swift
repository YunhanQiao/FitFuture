import SwiftUI

struct TimelineView: View {
    @ObservedObject var vm: DashboardViewModel
    @State private var selectedCheckIn: CheckIn?

    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 2) {
                    ForEach(vm.checkIns) { checkIn in
                        CheckInThumbnailView(checkIn: checkIn)
                            .onTapGesture { selectedCheckIn = checkIn }
                    }
                }
            }
            .background(Color.black)
            .navigationTitle("Progress")
            .sheet(item: $selectedCheckIn) { checkIn in
                CheckInDetailView(checkIn: checkIn, futureSelfURL: vm.futureSelfURL)
            }
        }
    }
}

private struct CheckInThumbnailView: View {
    let checkIn: CheckIn

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Color.gray.opacity(0.2)
                .aspectRatio(1, contentMode: .fit)
            Text("W\(checkIn.weekNumber)")
                .font(.caption.bold())
                .foregroundStyle(.white)
                .padding(4)
                .background(.black.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .padding(4)
        }
    }
}

private struct CheckInDetailView: View {
    let checkIn: CheckIn
    let futureSelfURL: URL?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack {
                Text("Week \(checkIn.weekNumber)")
                    .font(.title.bold())
                // TODO: Load and display full-size photo + split comparison vs future self
            }
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
}
