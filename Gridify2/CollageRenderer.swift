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
        backgroundColor: UIColor = .white
    ) -> UIImage? {
        // Don't scale spacing and corner radius - use them directly
        // The spacing and corner radius are in points, which works for both preview and export
        // Calculate cell size accounting for spacing
        let totalSpacingWidth = spacing * CGFloat(columns - 1)
        let totalSpacingHeight = spacing * CGFloat(rows - 1)
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
                
                // Calculate base cell position (grid-based, no scaling)
                let cellX = CGFloat(col) * (cellWidth + spacing)
                let cellY = CGFloat(row) * (cellHeight + spacing)
                
                let cellRect = CGRect(
                    x: cellX,
                    y: cellY,
                    width: cellWidth,
                    height: cellHeight
                )
                
                // Create rounded rect path if corner radius is set
                let path: CGPath
                if cornerRadius > 0 {
                    path = UIBezierPath(
                        roundedRect: cellRect,
                        cornerRadius: cornerRadius
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
                    let cellAspect = cellWidth / cellHeight
                    
                    var drawRect = cellRect
                    
                    if imageAspect > cellAspect {
                        // Image is wider - fit to height, center horizontally
                        let scaledWidth = cellHeight * imageAspect
                        let xOffset = (cellWidth - scaledWidth) / 2
                        drawRect = CGRect(
                            x: cellRect.origin.x + xOffset,
                            y: cellRect.origin.y,
                            width: scaledWidth,
                            height: cellHeight
                        )
                    } else {
                        // Image is taller - fit to width, center vertically
                        let scaledHeight = cellWidth / imageAspect
                        let yOffset = (cellHeight - scaledHeight) / 2
                        drawRect = CGRect(
                            x: cellRect.origin.x,
                            y: cellRect.origin.y + yOffset,
                            width: cellWidth,
                            height: scaledHeight
                        )
                    }
                    
                    // Apply user's image scale
                    let userImageScale = cell.imageScale
                    let scaledDrawWidth = drawRect.width * userImageScale
                    let scaledDrawHeight = drawRect.height * userImageScale
                    
                    // Apply user's image offset directly (no scaling needed)
                    let offsetX = cell.imageOffsetX
                    let offsetY = cell.imageOffsetY
                    
                    // Adjust draw rect for scale and offset
                    let finalDrawRect = CGRect(
                        x: drawRect.origin.x + offsetX - (scaledDrawWidth - drawRect.width) / 2,
                        y: drawRect.origin.y + offsetY - (scaledDrawHeight - drawRect.height) / 2,
                        width: scaledDrawWidth,
                        height: scaledDrawHeight
                    )
                    
                    // Save graphics state before clipping
                    cgContext.saveGState()
                    
                    // Clip to rounded rect if corner radius is set
                    if cornerRadius > 0 {
                        cgContext.addPath(path)
                        cgContext.clip()
                    }
                    
                    // Draw the image with transforms
                    image.draw(in: finalDrawRect)
                    
                    // Restore graphics state (removes clipping)
                    cgContext.restoreGState()
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

