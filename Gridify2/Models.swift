//
//  Models.swift
//  Gridify2
//
//  Created by Huan Nguyen on 21/11/25.
//

import SwiftUI
#if os(iOS) || targetEnvironment(macCatalyst)
import UIKit
#elseif canImport(AppKit)
import AppKit
typealias UIImage = NSImage
#endif
import Combine

// MARK: - CollageLayout
/// Represents a predefined collage template with rows and columns
struct CollageLayout: Identifiable {
    let id = UUID()
    let name: String
    let rows: Int
    let columns: Int
    
    static let defaultLayouts: [CollageLayout] = [
        CollageLayout(name: "1×3", rows: 1, columns: 3),
        CollageLayout(name: "2×2", rows: 2, columns: 2),
        CollageLayout(name: "2×3", rows: 2, columns: 3),
        CollageLayout(name: "2×4", rows: 2, columns: 4),
        CollageLayout(name: "3×3", rows: 3, columns: 3),
        CollageLayout(name: "3×4", rows: 3, columns: 4),
        CollageLayout(name: "4×4", rows: 4, columns: 4)
    ]
}

// MARK: - CollageCell
/// Represents a single cell in the collage grid
class CollageCell: ObservableObject, Identifiable {
    let id = UUID()
    let index: Int
    @Published var image: UIImage?
    @Published var widthScale: Double = 1.0
    @Published var heightScale: Double = 1.0
    @Published var imageOffsetX: CGFloat = 0
    @Published var imageOffsetY: CGFloat = 0
    @Published var imageScale: CGFloat = 1.0
    
    init(index: Int, image: UIImage? = nil) {
        self.index = index
        self.image = image
    }
}

