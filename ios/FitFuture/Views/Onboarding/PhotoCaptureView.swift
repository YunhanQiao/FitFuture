import SwiftUI
import PhotosUI

struct PhotoCaptureView: View {
    @ObservedObject var vm: OnboardingViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedPhoto: PhotosPickerItem?

    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 8) {
                Text("Take Your Photo")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                Text("Stand 6–8 feet away, full body visible.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding(.top, 60)

            // Preview
            if let data = vm.capturedImageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 380)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            } else {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.white.opacity(0.06))
                    .frame(height: 380)
                    .overlay {
                        VStack(spacing: 12) {
                            Image(systemName: "person.fill")
                                .font(.system(size: 80))
                                .foregroundStyle(.white.opacity(0.15))
                            Text("Full-body photo\nface to feet")
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.white.opacity(0.3))
                        }
                    }
            }

            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                Label("Choose Photo", systemImage: "photo.on.rectangle")
                    .font(.headline)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .onChange(of: selectedPhoto) { item in
                Task { vm.capturedImageData = try? await item?.loadTransferable(type: Data.self) }
            }

            Spacer()

            Button {
                if case .authenticated(let user) = authViewModel.authState {
                    Task { await vm.uploadPhotoAndAdvance(user: user) }
                }
            } label: {
                Group {
                    if vm.isUploading {
                        ProgressView().tint(.black)
                    } else {
                        Text("Use This Photo")
                            .font(.headline)
                            .foregroundStyle(.black)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(vm.capturedImageData == nil ? .white.opacity(0.3) : .white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(vm.capturedImageData == nil || vm.isUploading)
            .padding(.bottom, 48)
        }
        .padding(.horizontal, 24)
        .background(Color.black.ignoresSafeArea())
    }
}
