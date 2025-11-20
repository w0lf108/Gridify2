//
//  CollageRenderer.swift
//  Gridify2
//
//  Created by Huan Nguyen on 21/11/25.
//

import UIKit
import Photos

/// Helper class for rendering collage grid into a single UIImage and saving to Photo Library
class CollageRenderer {
    
    /// Renders the collage grid into a single UIImage
    /// - Parameters:
    ///   - cells: Array of collage cells with their images
    ///   - rows: Number of rows in the grid
    ///   - columns: Number of columns in the grid
    ///   - size: Output image size (default: 2000x2000)
    ///   - spacing: Spacing between cells (0-24)
    ///   - cornerRadius: Corner radius for cells (0-30)
    ///   - backgroundColor: Background color for the collage
    /// - Returns: Combined UIImage of the collage, or nil if rendering fails
    static func renderCollage(
        cells: [CollageCell],
        rows: Int,
        columns: Int,
        size: CGSize = CGSize(width: 2000, height: 2000),
        spacing: CGFloat = 0,
        cornerRadius: CGFloat = 0,
        backgroundColor: UIColor = .white,
        previewSize: CGSize = .zero
    ) -> UIImage? {
        // Scale spacing and corner radius to match preview exactly
        // The key is to maintain the same visual ratio between preview and export
        // Calculate scale factor based on the actual dimensions
        let scaleFactor: CGFloat
        if previewSize.width > 0 && previewSize.height > 0 {
            // Use the width ratio for scaling (assuming square or similar aspect ratio)
            // This ensures spacing and corner radius scale proportionally
            let previewWidth = previewSize.width
            let exportWidth = size.width
            scaleFactor = exportWidth / previewWidth
        } else {
            // Fallback: use a reasonable default
            // Typical iPhone preview width is ~350-400 points
            // Export is 2000 pixels, so scale factor is ~5-6x
            let exportMin = min(size.width, size.height)
            scaleFactor = exportMin / 375
        }
        
        // Apply scaling to maintain visual consistency
        let scaledSpacing = spacing * scaleFactor
        let scaledCornerRadius = cornerRadius * scaleFactor
        
        // Calculate cell size accounting for spacing
        let totalSpacingWidth = scaledSpacing * CGFloat(columns - 1)
        let totalSpacingHeight = scaledSpacing * CGFloat(rows - 1)
        let cellWidth = (size.width - totalSpacingWidth) / CGFloat(columns)
        let cellHeight = (size.height - totalSpacingHeight) / CGFloat(rows)
        
        // Create graphics context
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            let cgContext = context.cgContext
            
            // Draw background
            cgContext.setFillColor(backgroundColor.cgColor)
            cgContext.fill(CGRect(origin: .zero, size: size))
            
            // Draw each cell
            for (index, cell) in cells.enumerated() {
                let row = index / columns
                let col = index % columns
                
                // Apply individual cell scaling
                let scaledCellWidth = cellWidth * cell.widthScale
                let scaledCellHeight = cellHeight * cell.heightScale
                
                let cellRect = CGRect(
                    x: CGFloat(col) * (cellWidth + scaledSpacing),
                    y: CGFloat(row) * (cellHeight + scaledSpacing),
                    width: scaledCellWidth,
                    height: scaledCellHeight
                )
                
                // Create rounded rect path if corner radius is set
                let path: CGPath
                if scaledCornerRadius > 0 {
                    path = UIBezierPath(
                        roundedRect: cellRect,
                        cornerRadius: scaledCornerRadius
                    ).cgPath
                } else {
                    path = CGPath(rect: cellRect, transform: nil)
                }
                
                // Draw cell background (white)
                cgContext.addPath(path)
                cgContext.setFillColor(UIColor.white.cgColor)
                cgContext.fillPath()
                
                // Draw image if available
                if let image = cell.image {
                    // Calculate aspect-fit size to fill cell while maintaining aspect ratio
                    let imageAspect = image.size.width / image.size.height
                    let cellAspect = scaledCellWidth / scaledCellHeight
                    
                    var drawRect = cellRect
                    
                    if imageAspect > cellAspect {
                        // Image is wider - fit to height, center horizontally
                        let scaledWidth = scaledCellHeight * imageAspect
                        let xOffset = (scaledCellWidth - scaledWidth) / 2
                        drawRect = CGRect(
                            x: cellRect.origin.x + xOffset,
                            y: cellRect.origin.y,
                            width: scaledWidth,
                            height: scaledCellHeight
                        )
                    } else {
                        // Image is taller - fit to width, center vertically
                        let scaledHeight = scaledCellWidth / imageAspect
                        let yOffset = (scaledCellHeight - scaledHeight) / 2
                        drawRect = CGRect(
                            x: cellRect.origin.x,
                            y: cellRect.origin.y + yOffset,
                            width: scaledCellWidth,
                            height: scaledHeight
                        )
                    }
                    
                    // Apply user's image scale
                    let userImageScale = cell.imageScale
                    let scaledDrawWidth = drawRect.width * userImageScale
                    let scaledDrawHeight = drawRect.height * userImageScale
                    
                    // Apply user's image offset (scaled to export resolution)
                    let scaledOffsetX = cell.imageOffsetX * scaleFactor
                    let scaledOffsetY = cell.imageOffsetY * scaleFactor
                    
                    // Adjust draw rect for scale and offset
                    let finalDrawRect = CGRect(
                        x: drawRect.origin.x + scaledOffsetX - (scaledDrawWidth - drawRect.width) / 2,
                        y: drawRect.origin.y + scaledOffsetY - (scaledDrawHeight - drawRect.height) / 2,
                        width: scaledDrawWidth,
                        height: scaledDrawHeight
                    )
                    
                    // Clip to rounded rect if corner radius is set
                    if scaledCornerRadius > 0 {
                        cgContext.addPath(path)
                        cgContext.clip()
                    }
                    
                    // Draw the image with transforms
                    image.draw(in: finalDrawRect)
                    
                    // Reset clipping
                    if scaledCornerRadius > 0 {
                        cgContext.resetClip()
                    }
                } else {
                    // Draw placeholder for empty cells
                    cgContext.addPath(path)
                    cgContext.setFillColor(UIColor.lightGray.cgColor)
                    cgContext.fillPath()
                }
            }
        }
        
        return image
    }
    
    /// Saves the UIImage to the Photo Library
    /// - Parameters:
    ///   - image: The image to save
    ///   - completion: Completion handler with success/error message
    static func saveToPhotoLibrary(
        image: UIImage,
        completion: @escaping (String) -> Void
    ) {
        // Request authorization if needed
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        
        if status == .authorized {
            performSave(image: image, completion: completion)
        } else if status == .notDetermined {
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { newStatus in
                if newStatus == .authorized {
                    performSave(image: image, completion: completion)
                } else {
                    DispatchQueue.main.async {
                        completion("Photo Library access denied")
                    }
                }
            }
        } else {
            completion("Photo Library access denied")
        }
    }
    
    private static func performSave(
        image: UIImage,
        completion: @escaping (String) -> Void
    ) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }) { success, error in
            DispatchQueue.main.async {
                if success {
                    completion("Collage saved successfully!")
                } else {
                    completion("Failed to save: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }
}

