import SwiftUI

struct RevealView: View {
    let baselineImageData: Data
    let futureSelfURL: URL
    let onContinue: () -> Void

    @State private var revealed = false
    @State private var splitPosition: CGFloat = 0.5

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 6) {
                    Text("Your Future Self")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)
                        .opacity(revealed ? 1 : 0)
                        .animation(.easeIn(duration: 0.8).delay(0.5), value: revealed)

                    Text("This is where consistent training takes you.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                        .opacity(revealed ? 1 : 0)
                        .animation(.easeIn(duration: 0.8).delay(0.8), value: revealed)
                }
                .padding(.top, 60)
                .padding(.bottom, 24)

                // Split comparison
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        // Future Self (right)
                        AsyncImage(url: futureSelfURL) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Color.gray.opacity(0.3)
                        }
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()

                        // Today (left — sliding reveal)
                        if let uiImage = UIImage(data: baselineImageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: geo.size.width, height: geo.size.height)
                                .clipped()
                                .mask(
                                    HStack(spacing: 0) {
                                        Color.white.frame(width: geo.size.width * splitPosition)
                                        Color.clear
                                    }
                                )
                        }

                        // Divider handle
                        Rectangle()
                            .fill(.white)
                            .frame(width: 2, height: geo.size.height)
                            .offset(x: geo.size.width * splitPosition - 1)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        splitPosition = min(max(value.location.x / geo.size.width, 0.05), 0.95)
                                    }
                            )

                        // Labels
                        VStack {
                            Spacer()
                            HStack {
                                Text("TODAY")
                                    .font(.caption.bold())
                                    .foregroundStyle(.white)
                                    .padding(6)
                                    .background(.black.opacity(0.6))
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                    .padding(.leading, 12)
                                    .opacity(splitPosition > 0.15 ? 1 : 0)

                                Spacer()

                                Text("FUTURE YOU")
                                    .font(.caption.bold())
                                    .foregroundStyle(.white)
                                    .padding(6)
                                    .background(.black.opacity(0.6))
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                    .padding(.trailing, 12)
                                    .opacity(splitPosition < 0.85 ? 1 : 0)
                            }
                            .padding(.bottom, 16)
                        }
                    }
                }
                .frame(height: 440)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal, 16)
                .opacity(revealed ? 1 : 0)
                .scaleEffect(revealed ? 1 : 0.85)
                .animation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.3), value: revealed)

                Spacer()

                Button(action: onContinue) {
                    Text("Start My Journey")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
                .opacity(revealed ? 1 : 0)
                .animation(.easeIn(duration: 0.5).delay(1.2), value: revealed)
            }
        }
        .onAppear {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            revealed = true
        }
    }
}
