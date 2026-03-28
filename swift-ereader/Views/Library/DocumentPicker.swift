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
        print("🟢 Presenting picker, delegate = \(String(describing: picker.delegate))")
        viewController?.present(picker, animated: true)
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        print("📚 didPickDocumentsAt called with \(urls.count) URLs")
        onPick?(urls)
        onPick = nil
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("❌ Picker cancelled")
        onPick = nil
    }
}

extension View {
    func openDocumentPicker(onPick: @escaping ([URL]) -> Void) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            print("🔴 Could not find root view controller")
            return
        }
        // Walk to the topmost presented controller
        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }
        print("🟡 Found topVC: \(type(of: topVC))")
        DocumentPickerHelper.shared.present(from: topVC, onPick: onPick)
    }
}
