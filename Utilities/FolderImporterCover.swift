//
//  FolderImporterCover.swift
//  music
//
//  Created by Anel Torić on 2. 9. 2026.
//

import SwiftUI
import UniformTypeIdentifiers

struct FolderImporterCover: UIViewControllerRepresentable {
    var onComplete: ([URL]) -> Void

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

            let jpgs = Self.collectJPGs(in: folder)
            print("📂 Found \(jpgs.count) JPG files in folder")

            // Copy NOW, while the scope is still held
            let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            var ok = 0
            for url in jpgs {
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


        static func collectJPGs(in directory: URL) -> [URL] {
            guard let enumerator = FileManager.default.enumerator(
                at: directory,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [],
                errorHandler: { _, _ in true }   // skip unreadable entries
            ) else { return [] }

            var results: [URL] = []
            for case let url as URL in enumerator {
                if url.pathExtension.lowercased() == "jpg" {
                    results.append(url)
                }
            }
            return results
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {}
    }
}
