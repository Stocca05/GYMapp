import SwiftUI
#if canImport(UIKit)
import UIKit

/// Adatta UIImagePickerController restituendo dati JPEG senza far uscire UIKit dalla View.
struct CameraPicker: UIViewControllerRepresentable {
    let onImage: @MainActor (Data) -> Void
    let onCancel: @MainActor () -> Void

    /// Crea il controller di acquisizione quando la fotocamera è disponibile.
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let controller = UIImagePickerController(); controller.sourceType = .camera; controller.delegate = context.coordinator; return controller
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(owner: self) }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        private let owner: CameraPicker
        init(owner: CameraPicker) { self.owner = owner }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage, let data = image.jpegData(compressionQuality: 0.8) {
                Task { @MainActor in owner.onImage(data) }
            } else { Task { @MainActor in owner.onCancel() } }
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { Task { @MainActor in owner.onCancel() } }
    }
}
#else
/// Fallback per macOS o ambienti in cui UIKit non è disponibile.
struct CameraPicker: View {
    let onImage: @MainActor (Data) -> Void
    let onCancel: @MainActor () -> Void

    var body: some View {
        VStack {
            Text("Fotocamera non supportata su questo dispositivo.")
                .padding()
            Button("Annulla") {
                Task { @MainActor in onCancel() }
            }
        }
    }
}
#endif
