//
//  CollageEditorView.swift
//  Gridify2
//
//  Created by Huan Nguyen on 21/11/25.
//

import SwiftUI
import PhotosUI
import UIKit
import Combine

struct CollageEditorView: View {
    let layout: CollageLayout
    @StateObject private var viewModel: CollageEditorViewModel
    @State private var selectedCellIndex: Int?
    @State private var showPhotoPicker = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isExporting = false
    @State private var editMode: EditMode = .addPhoto
    
    enum EditMode {
        case addPhoto
        case resizeCell
        case adjustImage
        case adjustSize
    }
    
    // Styling parameters that override layout defaults
    @State private var spacing: Double = 0
    @State private var cornerRadius: Double = 0
    @State private var backgroundColor: Color = .white
    @State private var previewSize: CGSize = .zero
    
    init(layout: CollageLayout) {
        self.layout = layout
        _viewModel = StateObject(wrappedValue: CollageEditorViewModel(layout: layout))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header with Mode Toggle
                VStack(spacing: 12) {
                    HStack {
                        Text("Layout: \(layout.name)")
                            .font(.headline)
                        Spacer()
                    }
                    
                    // Mode Toggle
                    Picker("Edit Mode", selection: $editMode) {
                        Label("Add Photos", systemImage: "photo").tag(EditMode.addPhoto)
                        Label("Resize", systemImage: "arrow.up.left.and.arrow.down.right").tag(EditMode.resizeCell)
                        Label("Adjust Image", systemImage: "hand.draw").tag(EditMode.adjustImage)
                        Label("Sliders", systemImage: "slider.horizontal.3").tag(EditMode.adjustSize)
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Collage Preview Grid
                GeometryReader { geometry in
                    let availableWidth = geometry.size.width
                    let availableHeight = geometry.size.height
                    let totalSpacingWidth = spacing * CGFloat(layout.columns - 1)
                    let totalSpacingHeight = spacing * CGFloat(layout.rows - 1)
                    let cellWidth = (availableWidth - totalSpacingWidth) / CGFloat(layout.columns)
                    let cellHeight = (availableHeight - totalSpacingHeight) / CGFloat(layout.rows)
                    
                    ZStack {
                        // Grid background
                        backgroundColor
                        
                        // Cells
                        ForEach(Array(viewModel.cells.enumerated()), id: \.element.id) { index, cell in
                            let row = index / layout.columns
                            let col = index % layout.columns
                            
                            // Calculate cell position with spacing
                            let xPosition = CGFloat(col) * (cellWidth + spacing) + cellWidth / 2
                            let yPosition = CGFloat(row) * (cellHeight + spacing) + cellHeight / 2
                            
                            // Apply individual cell scaling
                            let scaledWidth = cellWidth * cell.widthScale
                            let scaledHeight = cellHeight * cell.heightScale
                            
                            CollageCellView(
                                cell: cell,
                                width: scaledWidth,
                                height: scaledHeight,
                                cornerRadius: cornerRadius,
                                isSelected: selectedCellIndex == index,
                                editMode: editMode
                            )
                            .position(x: xPosition, y: yPosition)
                            .onTapGesture {
                                selectedCellIndex = index
                                if editMode == .addPhoto {
                                    showPhotoPicker = true
                                }
                            }
                            .gesture(
                                editMode == .resizeCell && selectedCellIndex == index ?
                                DragGesture()
                                    .onChanged { value in
                                        // Calculate new scale based on drag
                                        let widthChange = value.translation.width / cellWidth
                                        let heightChange = value.translation.height / cellHeight
                                        
                                        // Update cell dimensions (clamped between 0.5 and 1.5)
                                        let newWidthScale = max(0.5, min(1.5, cell.widthScale + widthChange * 0.01))
                                        let newHeightScale = max(0.5, min(1.5, cell.heightScale + heightChange * 0.01))
                                        
                                        viewModel.cells[index].widthScale = newWidthScale
                                        viewModel.cells[index].heightScale = newHeightScale
                                    }
                                : nil
                            )
                        }
                    }
                    .onAppear {
                        previewSize = geometry.size
                    }
                    .onChange(of: geometry.size) { oldValue, newSize in
                        previewSize = newSize
                    }
                }
                .aspectRatio(CGFloat(layout.columns) / CGFloat(layout.rows), contentMode: .fit)
                .padding(.horizontal)
                
                // Styling Controls Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Styling")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    // Spacing Control
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Spacing")
                                .font(.subheadline)
                            Spacer()
                            Text("\(Int(spacing))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                        
                        Slider(value: $spacing, in: 0...24, step: 1)
                            .padding(.horizontal)
                    }
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6).opacity(0.5))
                    .cornerRadius(8)
                    .padding(.horizontal)
                    
                    // Corner Radius Control
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Corner Radius")
                                .font(.subheadline)
                            Spacer()
                            Text("\(Int(cornerRadius))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                        
                        Slider(value: $cornerRadius, in: 0...30, step: 1)
                            .padding(.horizontal)
                    }
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6).opacity(0.5))
                    .cornerRadius(8)
                    .padding(.horizontal)
                    
                    // Background Color Quick Pick
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Background Color")
                            .font(.subheadline)
                            .padding(.horizontal)
                        
                        // Color preset grid
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ColorPresetButton(color: .black, selectedColor: $backgroundColor, label: "Black")
                            ColorPresetButton(color: .white, selectedColor: $backgroundColor, label: "White")
                            ColorPresetButton(color: .gray, selectedColor: $backgroundColor, label: "Gray")
                            ColorPresetButton(color: .green, selectedColor: $backgroundColor, label: "Green")
                            ColorPresetButton(color: .red, selectedColor: $backgroundColor, label: "Red")
                            ColorPresetButton(color: .yellow, selectedColor: $backgroundColor, label: "Yellow")
                        }
                        .padding(.horizontal)
                        
                        // Custom color picker
                        HStack {
                            Text("Custom")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            ColorPicker("", selection: $backgroundColor, supportsOpacity: false)
                                .labelsHidden()
                            Spacer()
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6).opacity(0.5))
                    .cornerRadius(8)
                    .padding(.horizontal)
                    
                    // Cell Dimensions Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Cell Controls")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        // Mode-specific instructions
                        Group {
                            if editMode == .addPhoto {
                                Text("Switch to other modes to customize cells")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else if editMode == .resizeCell {
                                Text("Tap a cell, then drag to resize or use sliders below")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else if editMode == .adjustImage {
                                Text("Tap a cell with an image, then pan & pinch to adjust")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Use sliders to adjust cell dimensions")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal)
                        
                        if let selectedIndex = selectedCellIndex, selectedIndex < viewModel.cells.count {
                            let cell = viewModel.cells[selectedIndex]
                            
                            VStack(spacing: 16) {
                                // Cell Size Controls (shown in resizeCell and adjustSize modes)
                                if editMode == .resizeCell || editMode == .adjustSize {
                                    VStack(spacing: 12) {
                                        Text("Cell \(selectedIndex + 1) Size")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.horizontal)
                                        
                                        // Width Scale Control
                                        VStack(alignment: .leading, spacing: 8) {
                                            HStack {
                                                Text("Width")
                                                    .font(.subheadline)
                                                Spacer()
                                                Text("\(Int(cell.widthScale * 100))%")
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                            }
                                            .padding(.horizontal)
                                            
                                            Slider(value: Binding(
                                                get: { cell.widthScale },
                                                set: { newValue in
                                                    viewModel.cells[selectedIndex].widthScale = newValue
                                                }
                                            ), in: 0.5...1.5, step: 0.1)
                                                .padding(.horizontal)
                                        }
                                        
                                        // Height Scale Control
                                        VStack(alignment: .leading, spacing: 8) {
                                            HStack {
                                                Text("Height")
                                                    .font(.subheadline)
                                                Spacer()
                                                Text("\(Int(cell.heightScale * 100))%")
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                            }
                                            .padding(.horizontal)
                                            
                                            Slider(value: Binding(
                                                get: { cell.heightScale },
                                                set: { newValue in
                                                    viewModel.cells[selectedIndex].heightScale = newValue
                                                }
                                            ), in: 0.5...1.5, step: 0.1)
                                                .padding(.horizontal)
                                        }
                                        
                                        // Reset cell size button
                                        Button(action: {
                                            viewModel.cells[selectedIndex].widthScale = 1.0
                                            viewModel.cells[selectedIndex].heightScale = 1.0
                                        }) {
                                            HStack {
                                                Image(systemName: "arrow.counterclockwise")
                                                Text("Reset Cell Size")
                                            }
                                            .font(.subheadline)
                                            .foregroundColor(.blue)
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                                
                                // Image Position Controls (shown in adjustImage mode)
                                if editMode == .adjustImage && cell.image != nil {
                                    Divider()
                                        .padding(.horizontal)
                                    
                                    VStack(spacing: 12) {
                                        Text("Image Position")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.horizontal)
                                        
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("Zoom: \(String(format: "%.1f", cell.imageScale))x")
                                                    .font(.caption)
                                                Text("Offset: (\(Int(cell.imageOffsetX)), \(Int(cell.imageOffsetY)))")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            Spacer()
                                        }
                                        .padding(.horizontal)
                                        
                                        // Reset image position button
                                        Button(action: {
                                            viewModel.cells[selectedIndex].imageOffsetX = 0
                                            viewModel.cells[selectedIndex].imageOffsetY = 0
                                            viewModel.cells[selectedIndex].imageScale = 1.0
                                        }) {
                                            HStack {
                                                Image(systemName: "arrow.counterclockwise")
                                                Text("Reset Image Position")
                                            }
                                            .font(.subheadline)
                                            .foregroundColor(.blue)
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                            }
                            .padding(.vertical, 12)
                            .background(Color(.systemGray6).opacity(0.3))
                            .cornerRadius(8)
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6).opacity(0.5))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("Edit Collage")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: exportCollage) {
                    if isExporting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        HStack(spacing: 6) {
                            Image(systemName: "square.and.arrow.down")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Export")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                .disabled(isExporting)
            }
        }
        .photosPicker(
            isPresented: $showPhotoPicker,
            selection: $viewModel.selectedPhotoItem,
            matching: .images
        )
        .onChange(of: viewModel.selectedPhotoItem) { oldValue, newItem in
            if let index = selectedCellIndex, let newItem = newItem {
                loadImage(for: index, item: newItem)
            }
        }
        .alert("Export", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func loadImage(for index: Int, item: PhotosPickerItem) {
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    viewModel.cells[index].image = image
                    selectedCellIndex = nil
                }
            }
        }
    }
    
    private func exportCollage() {
        isExporting = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            // Convert SwiftUI Color to UIColor
            let uiColor = UIColor(backgroundColor)
            
            // Always use high-resolution export size (2000x2000)
            // But pass preview size for accurate scaling of spacing/corner radius
            let exportSize = CGSize(width: 2000, height: 2000)
            
            guard let renderedImage = CollageRenderer.renderCollage(
                cells: viewModel.cells,
                rows: layout.rows,
                columns: layout.columns,
                size: exportSize,
                spacing: spacing,
                cornerRadius: cornerRadius,
                backgroundColor: uiColor,
                previewSize: previewSize
            ) else {
                DispatchQueue.main.async {
                    alertMessage = "Failed to render collage"
                    showAlert = true
                    isExporting = false
                }
                return
            }
            
            CollageRenderer.saveToPhotoLibrary(image: renderedImage) { message in
                alertMessage = message
                showAlert = true
                isExporting = false
            }
        }
    }
}

// MARK: - CollageEditorViewModel
class CollageEditorViewModel: ObservableObject {
    @Published var cells: [CollageCell] = []
    @Published var selectedPhotoItem: PhotosPickerItem?
    
    init(layout: CollageLayout) {
        // Initialize cells for the grid
        let totalCells = layout.rows * layout.columns
        cells = (0..<totalCells).map { CollageCell(index: $0) }
    }
}

// MARK: - CollageCellView
struct CollageCellView: View {
    @ObservedObject var cell: CollageCell
    let width: CGFloat
    let height: CGFloat
    let cornerRadius: Double
    let isSelected: Bool
    let editMode: CollageEditorView.EditMode
    
    @State private var currentOffset: CGSize = .zero
    @State private var currentScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            if let image = cell.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .scaleEffect(cell.imageScale * currentScale)
                    .offset(
                        x: cell.imageOffsetX + currentOffset.width,
                        y: cell.imageOffsetY + currentOffset.height
                    )
                    .frame(width: width, height: height)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    .onTapGesture {
                        // Tap handled by parent
                    }
                    .if(editMode == .adjustImage && isSelected) { view in
                        view
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        currentOffset = value.translation
                                    }
                                    .onEnded { value in
                                        cell.imageOffsetX += value.translation.width
                                        cell.imageOffsetY += value.translation.height
                                        currentOffset = .zero
                                    }
                            )
                            .simultaneousGesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        currentScale = value
                                    }
                                    .onEnded { value in
                                        cell.imageScale *= value
                                        currentScale = 1.0
                                    }
                            )
                    }
            } else {
                // Modern Placeholder with gradient
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.blue.opacity(0.1),
                                Color.purple.opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: width, height: height)
                    .overlay(
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.blue.opacity(0.2),
                                                Color.purple.opacity(0.2)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 50, height: 50)
                                
                                Image(systemName: "photo.badge.plus")
                                    .font(.system(size: 24, weight: .medium))
                                    .foregroundStyle(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.blue,
                                                Color.purple
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }
                            
                            Text("Add Photo")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.blue.opacity(0.3),
                                        Color.purple.opacity(0.3)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
            }
            
            // Selection border and resize handles
            if isSelected {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.blue, lineWidth: 3)
                    .frame(width: width, height: height)
                
                // Show resize handles in resize mode
                if editMode == .resizeCell {
                    // Corner handles
                    ForEach(0..<4) { index in
                        ResizeHandle(position: handlePosition(index, width: width, height: height))
                    }
                }
                
                // Show pan/zoom hint in adjust image mode
                if editMode == .adjustImage && cell.image != nil {
                    VStack {
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "hand.draw")
                                .font(.system(size: 10))
                            Text("Pan & Pinch")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding(.bottom, 4)
                    }
                    .frame(width: width, height: height)
                }
            } else {
                // Border
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    .frame(width: width, height: height)
            }
        }
    }
    
    private func handlePosition(_ index: Int, width: CGFloat, height: CGFloat) -> CGPoint {
        switch index {
        case 0: return CGPoint(x: -width/2, y: -height/2) // Top-left
        case 1: return CGPoint(x: width/2, y: -height/2)  // Top-right
        case 2: return CGPoint(x: -width/2, y: height/2)  // Bottom-left
        case 3: return CGPoint(x: width/2, y: height/2)   // Bottom-right
        default: return .zero
        }
    }
}

// MARK: - ResizeHandle
struct ResizeHandle: View {
    let position: CGPoint
    
    var body: some View {
        Circle()
            .fill(Color.white)
            .frame(width: 20, height: 20)
            .overlay(
                Circle()
                    .stroke(Color.blue, lineWidth: 2)
            )
            .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
            .offset(x: position.x, y: position.y)
    }
}

// MARK: - ColorPresetButton
struct ColorPresetButton: View {
    let color: Color
    @Binding var selectedColor: Color
    let label: String
    
    var body: some View {
        VStack(spacing: 6) {
            Button(action: {
                selectedColor = color
            }) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color)
                    .frame(height: 50)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selectedColor == color ? Color.blue : Color.gray.opacity(0.3), lineWidth: selectedColor == color ? 3 : 1)
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
            }
            
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - View Extension for Conditional Modifiers
extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

#Preview {
    NavigationView {
        CollageEditorView(layout: CollageLayout.defaultLayouts[0])
    }
}

