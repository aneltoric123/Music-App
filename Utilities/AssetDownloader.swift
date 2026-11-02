//
//  AssetDownloader.swift
//  music
//
//  Created by Anel Torić on 7. 8. 2026.
//

import SwiftUI
import SwiftData
import Foundation
import UIKit

// Helper to resolve the actual file URL for a song's cover
func resolveCoverURL(for song: Song) -> URL? {
    // Assuming your naming convention is "Artist - Title.jpg"
    // matching the displayName logic but with .jpg extension
    let components = song.title.components(separatedBy: " - ")
    guard components.count >= 2 else { return nil }
    
    let baseName = "\(components[0]) - \(components[1]).jpg"
    let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    let url = docsDir.appendingPathComponent(baseName)
    
    return FileManager.default.fileExists(atPath: url.path) ? url : nil
}

extension UIImage {
    // Safe downsampling loader for file URLs
    static func downsampledImage(at url: URL, to pointSize: CGFloat, scale: CGFloat) -> UIImage? {
        let maxDimension = pointSize * scale
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimension
        ]
        
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }
}
actor ImageCache {
    static let shared = ImageCache()
    private var cache: [String: UIImage] = [:]

    func image(for url: URL?, maxPixelSize: CGFloat) async -> UIImage? {
        guard let url else { return nil }
        let key = "\(url.absoluteString)-\(Int(maxPixelSize))"
        if let cached = cache[key] { return cached }

        // Decode off the main actor (we're already in an actor context)
        guard let img = UIImage.downsampledImage(at: url, to: maxPixelSize, scale: UIScreen.main.scale) else { return nil }
        cache[key] = img
        return img
    }
}

struct AsyncCover: View {
    let song: Song
    let size: CGFloat

    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill().aspectRatio(1,contentMode: .fit)
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: min(size * 0.18, 14)))
            } else {
                RoundedRectangle(cornerRadius: min(size * 0.18, 14))
                    .fill(Color.white.opacity(0.08))
                    .frame(width: size, height: size)
                    .overlay(Image(systemName: "music.note").foregroundColor(.gray))
            }
        }
        .task(id: song.id) {
            image = await ImageCache.shared.image(for: resolveCoverURL(for: song), maxPixelSize: size)
        }
    }
}

