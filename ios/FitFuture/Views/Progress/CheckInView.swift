import SwiftUI
import PhotosUI

struct CheckInView: View {
    @ObservedObject var vm: DashboardViewModel
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var weightText = ""
    @State private var isUploading = false
    @State private var uploadSuccess = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Photo picker / preview
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    if let data = imageData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 320)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    } else {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.white.opacity(0.06))
                            .frame(height: 320)
                            .overlay {
                                VStack(spacing: 12) {
                                    Image(systemName: "camera.fill")
                                        .font(.largeTitle)
                                        .foregroundStyle(.white.opacity(0.4))
                                    Text("Tap to select photo")
                                        .foregroundStyle(.white.opacity(0.4))
                                }
                            }
                    }
                }
                .onChange(of: selectedPhoto) { item in
                    Task {
                        imageData = try? await item?.loadTransferable(type: Data.self)
                    }
                }

                // Weight field
                VStack(alignment: .leading, spacing: 6) {
                    Text("WEIGHT (KG) — OPTIONAL")
                        .font(.caption.bold())
                        .foregroundStyle(.white.opacity(0.5))
                    TextField("e.g. 78.5", text: $weightText)
                        .keyboardType(.decimalPad)
                        .foregroundStyle(.white)
                        .padding()
                        .background(.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Spacer()

                Button {
                    // TODO: upload check-in
                } label: {
                    Group {
                        if isUploading {
                            ProgressView().tint(.black)
                        } else {
                            Text("Log This Week")
                                .font(.headline)
                                .foregroundStyle(.black)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(imageData == nil ? .white.opacity(0.3) : .white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(imageData == nil || isUploading)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 24)
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Weekly Check-In")
        }
    }
}
