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
    
    enum AspectRatio: String, CaseIterable, Identifiable {
        case square = "1:1"
        case portrait34 = "3:4"
        case portrait45 = "4:5"
        case portrait23 = "2:3"
        case portrait916 = "9:16"
        case landscape = "16:9"
        case ultraWide = "21:9"
        
        var id: String { rawValue }
        
        var ratio: CGFloat {
            switch self {
            case .square: return 1.0
            case .portrait34: return 3.0 / 4.0
            case .portrait45: return 4.0 / 5.0
            case .portrait23: return 2.0 / 3.0
            case .portrait916: return 9.0 / 16.0
            case .landscape: return 16.0 / 9.0
            case .ultraWide: return 21.0 / 9.0
            }
        }
        
        var displayName: String {
            rawValue
        }
    }
    
    // Styling parameters that override layout defaults
    @State private var spacing: Double = 0
    @State private var cornerRadius: Double = 0
    @State private var backgroundColor: Color = .white
    @State private var previewSize: CGSize = .zero
    @State private var selectedAspectRatio: AspectRatio = .square
    
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
                            // Resize gesture handled separately below
                        }
                        
                        
                    }
                    .onAppear {
                        previewSize = geometry.size
                    }
                    .onChange(of: geometry.size) { oldValue, newSize in
                        previewSize = newSize
                    }
                }
                
                .aspectRatio(selectedAspectRatio.ratio, contentMode: .fit)
                .padding(.horizontal)
                
                // Styling Controls Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Styling")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    // Aspect Ratio Control
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Aspect Ratio")
                            .font(.subheadline)
                            .padding(.horizontal)
                        
                        // Horizontal scrolling picker
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(AspectRatio.allCases) { aspectRatio in
                                    Button(action: {
                                        selectedAspectRatio = aspectRatio
                                    }) {
                                        VStack(spacing: 6) {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(selectedAspectRatio == aspectRatio ? Color.blue.opacity(0.1) : Color.clear)
                                                    .frame(width: 70, height: 60)
                                                
                                                RoundedRectangle(cornerRadius: 8)
                                                    .strokeBorder(
                                                        selectedAspectRatio == aspectRatio ? Color.blue : Color.gray.opacity(0.3),
                                                        lineWidth: selectedAspectRatio == aspectRatio ? 2 : 1
                                                    )
                                                    .frame(width: 70, height: 60)
                                                
                                                // Visual representation of the ratio
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(selectedAspectRatio == aspectRatio ? Color.blue : Color.gray)
                                                    .aspectRatio(aspectRatio.ratio, contentMode: .fit)
                                                    .padding(16)
                                            }
                                            
                                            Text(aspectRatio.displayName)
                                                .font(.system(size: 12, weight: selectedAspectRatio == aspectRatio ? .semibold : .regular))
                                                .foregroundColor(selectedAspectRatio == aspectRatio ? .blue : .secondary)
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6).opacity(0.5))
                    .cornerRadius(8)
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
        
        func loadImage(for index: Int, item: PhotosPickerItem) {
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
        
        func exportCollage() {
            isExporting = true
            
            DispatchQueue.global(qos: .userInitiated).async {
                // Convert SwiftUI Color to UIColor
                let uiColor = UIColor(backgroundColor)
                
                // Calculate export size based on selected aspect ratio
                // Use high-resolution base dimension of 2000px
                let exportSize: CGSize
                let aspectRatioValue = selectedAspectRatio.ratio
                
                if aspectRatioValue >= 1.0 {
                    // Landscape or square: width is base dimension
                    exportSize = CGSize(width: 2000, height: 2000 / aspectRatioValue)
                } else {
                    // Portrait: height is base dimension
                    exportSize = CGSize(width: 2000 * aspectRatioValue, height: 2000)
                }
                
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
                    imageView(for: image)
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
        
        @ViewBuilder
        private func imageView(for image: UIImage) -> some View {
            if editMode == .adjustImage && isSelected {
                baseImageView(image)
                    .gesture(
                        DragGesture()
                            .onChanged { currentOffset = $0.translation }
                            .onEnded { value in
                                cell.imageOffsetX += value.translation.width
                                cell.imageOffsetY += value.translation.height
                                currentOffset = .zero
                            }
                    )
                    .simultaneousGesture(
                        MagnificationGesture()
                            .onChanged { currentScale = $0 }
                            .onEnded { value in
                                cell.imageScale *= value
                                currentScale = 1.0
                            }
                    )
            } else {
                baseImageView(image)
            }
        }
        
        private func baseImageView(_ image: UIImage) -> some View {
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

// MARK: - Preview
#Preview {
    NavigationView {
        CollageEditorView(layout: CollageLayout.defaultLayouts[0])
    }
}
