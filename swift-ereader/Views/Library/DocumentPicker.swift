import SwiftUI
import UniformTypeIdentifiers

class DocumentPickerHelper: NSObject, UIDocumentPickerDelegate {
    static let shared = DocumentPickerHelper()
    var onPick: (([URL]) -> Void)?

    func present(from viewController: UIViewController?, onPick: @escaping ([URL]) -> Void) {
        self.onPick = onPick
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf, .epub], asCopy: true)
        picker.allowsMultipleSelection = true
        picker.delegate = self
        viewController?.present(picker, animated: true)
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        onPick?(urls)
        onPick = nil
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        onPick = nil
    }
}

extension View {
    func openDocumentPicker(onPick: @escaping ([URL]) -> Void) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            return
        }
        // Walk to the topmost presented controller
        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }
        DocumentPickerHelper.shared.present(from: topVC, onPick: onPick)
    }
}
