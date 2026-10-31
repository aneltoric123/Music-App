import SwiftUI
import UniformTypeIdentifiers

struct FolderImporter: UIViewControllerRepresentable {
    var onComplete: ([URL]) -> Void   // returns the list of .mp3 URLs found

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.folder], asCopy: false)
        picker.allowsMultipleSelection = false
        picker.directoryURL = nil          // start wherever the user last was
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onComplete: onComplete)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var onComplete: ([URL]) -> Void
        init(onComplete: @escaping ([URL]) -> Void) { self.onComplete = onComplete }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let folder = urls.first else { return }
            guard folder.startAccessingSecurityScopedResource() else {
                print("❌ Could not access selected folder")
                return
            }
            defer { folder.stopAccessingSecurityScopedResource() }

            let mp3s = Self.collectMP3s(in: folder)
            print("📂 Found \(mp3s.count) MP3 files in folder")

            // Copy NOW, while the scope is still held
            let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            var ok = 0
            for url in mp3s {
                let dest = docsDir.appendingPathComponent(url.lastPathComponent)
                if !FileManager.default.fileExists(atPath: dest.path) {
                    do {
                        try FileManager.default.copyItem(at: url, to: dest)
                        ok += 1
                    } catch {
                        print("❌", url.lastPathComponent, error.localizedDescription)
                    }
                } else { ok += 1 }
            }
            print("✅ Copied \(ok) files into Documents")
            onComplete([])   // signal done; no URLs needed downstream now
        }


        static func collectMP3s(in directory: URL) -> [URL] {
            guard let enumerator = FileManager.default.enumerator(
                at: directory,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [],
                errorHandler: { _, _ in true }   // skip unreadable entries
            ) else { return [] }

            var results: [URL] = []
            for case let url as URL in enumerator {
                if url.pathExtension.lowercased() == "mp3" {
                    results.append(url)
                }
            }
            return results
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {}
    }
}
