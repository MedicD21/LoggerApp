import PhotosUI
import SwiftUI

struct PhotoCaptureView: View {
    let container: AppContainer

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: PhotoLogViewModel
    @State private var selectedItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var cameraImageData: Data?

    init(container: AppContainer) {
        self.container = container
        _viewModel = StateObject(wrappedValue: PhotoLogViewModel(repository: container.aiRepository))
    }

    var body: some View {
        Group {
            if let response = viewModel.response {
                PhotoReviewView(container: container, response: response)
            } else {
                VStack(spacing: 18) {
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.brandSecondary.opacity(0.22), Color.brandPrimary.opacity(0.12)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 240)
                        .overlay {
                            VStack(spacing: 12) {
                                Image(systemName: "camera.macro")
                                    .font(.system(size: 42))
                                Text("Capture a meal and confirm the match before anything is logged.")
                                    .multilineTextAlignment(.center)
                                    .font(.headline)
                                    .padding(.horizontal)
                            }
                        }

                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        Label("Choose from Library", systemImage: "photo.on.rectangle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    Button {
                        showCamera = true
                    } label: {
                        Label("Take Photo", systemImage: "camera")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    if viewModel.isLoading {
                        ProgressView("Analyzing photo…")
                    }

                    Spacer()
                }
                .padding(24)
                .background(Color.brandBackground.ignoresSafeArea())
                .navigationTitle("Photo Log")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Close") { dismiss() }
                    }
                }
                .onChange(of: selectedItem) { _, newValue in
                    guard let newValue else { return }
                    Task {
                        if let data = try? await newValue.loadTransferable(type: Data.self) {
                            await viewModel.analyze(imageData: data)
                        }
                    }
                }
                .onChange(of: cameraImageData) { _, newValue in
                    guard let newValue else { return }
                    Task { await viewModel.analyze(imageData: newValue) }
                }
                .sheet(isPresented: $showCamera) {
                    CameraPickerView { imageData in
                        cameraImageData = imageData
                    }
                }
                .alert("Photo Logging Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                    Button("OK") { viewModel.errorMessage = nil }
                } message: {
                    Text(viewModel.errorMessage ?? "")
                }
            }
        }
    }
}

private struct CameraPickerView: UIViewControllerRepresentable {
    let onImage: (Data) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onImage: onImage)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let onImage: (Data) -> Void

        init(onImage: @escaping (Data) -> Void) {
            self.onImage = onImage
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage,
               let data = image.jpegData(compressionQuality: 0.85) {
                onImage(data)
            }

            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

