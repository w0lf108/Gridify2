# Gridify

<div align="center">
  <img src="https://img.shields.io/badge/platform-iOS-lightgrey.svg" alt="Platform: iOS">
  <img src="https://img.shields.io/badge/Swift-5.9-orange.svg" alt="Swift 5.9">
  <img src="https://img.shields.io/badge/SwiftUI-5.0-blue.svg" alt="SwiftUI 5.0">
</div>

Create beautiful photo collages with ease. Gridify is a modern iOS app that lets you arrange your photos into customizable grid layouts and export them as high-quality images.

## ✨ Features

### 📐 Multiple Layout Options
Choose from various grid configurations:
- **1×3** - Perfect for panoramic shots
- **2×2** - Classic four-photo grid
- **2×3** - Six photos in a compact layout
- **2×4** - Eight photos for more content
- **3×3** - Nine photos in a balanced square

### 🎨 Customization Options

#### Aspect Ratios
Export your collages in multiple aspect ratios:
- **Square (1:1)** - Perfect for Instagram posts
- **Portrait 3:4** - Classic portrait orientation
- **Portrait 4:5** - Instagram-friendly portrait
- **Portrait 2:3** - Standard photo ratio
- **Portrait 9:16** - Instagram Stories & Reels
- **Landscape 16:9** - Widescreen format
- **Ultra-wide 21:9** - Cinematic format

#### Styling Controls
- **Spacing**: Adjust gaps between photos (0-24 points)
- **Corner Radius**: Round the corners of each photo (1-30 points)
- **Background Color**: Choose from presets or pick a custom color
  - Presets: Black, White, Gray, Green, Red, Yellow
  - Custom color picker for unlimited options

### 🖼️ Image Management
- **Add Photos**: Tap any cell to select a photo from your library
- **Adjust Images**: Pan and pinch to zoom images within cells for perfect framing
- **Replace Photos**: Tap any filled cell to replace the image

### 📤 High-Quality Export
- Export at **2000×2000 pixels** (or equivalent based on aspect ratio)
- Save directly to your Photos library
- Maintains high image quality for social media and printing
- Proper core graphics rendering with optimized performance

## 🏗️ Architecture

### Project Structure

```
Gridify2/
├── CollageEditorView.swift  # Main editor interface
├── CollageRenderer.swift    # Core Graphics rendering engine
├── Models.swift             # Data models
└── ContentView.swift        # Layout selection screen
```

### Key Components

#### `CollageEditorView`
The main editing interface featuring:
- Grid preview with real-time updates
- Styling controls (spacing, corner radius, colors)
- Aspect ratio selector
- Photo picker integration
- Export functionality

#### `CollageRenderer`
High-performance rendering engine that:
- Uses Core Graphics for pixel-perfect output
- Handles aspect ratio calculations
- Applies styling (spacing, corner radius, background)
- Supports custom image scaling and positioning
- Properly manages graphics state for clipping

#### `CollageCell`
Observable model for each grid cell:
- Stores the photo image
- Tracks image transformations (scale, offset)
- Manages cell dimensions

#### `CollageLayout`
Defines grid templates:
- Rows and columns configuration
- Layout identifiers and names

## 🚀 Getting Started

### Prerequisites
- Xcode 15.0 or later
- iOS 17.0 or later
- Swift 5.9 or later

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd Gridify2
```

2. Open the project in Xcode:
```bash
open Gridify2.xcodeproj
```

3. Build and run on your device or simulator

### Usage

1. **Launch the app** and browse available layouts
2. **Select a layout** that fits your needs
3. **Tap cells** to add photos from your library
4. **Customize the appearance**:
   - Adjust spacing between photos
   - Set corner radius for rounded edges
   - Choose a background color
   - Select your preferred aspect ratio
5. **Fine-tune images** by selecting cells and using pan/zoom gestures
6. **Tap Export** to save to your Photos library

## 🔧 Technical Details

### Rendering Pipeline
1. User configures layout and styling in SwiftUI interface
2. On export, parameters are passed to `CollageRenderer`
3. Core Graphics context is created at target resolution
4. Each cell is rendered with:
   - Calculated position based on grid layout
   - Applied spacing between cells
   - Corner radius clipping (if applicable)
   - Image transformations (scale, offset)
5. Final composite is saved to Photos library

### Graphics State Management
The renderer uses proper graphics state management to ensure clean rendering:
```swift
cgContext.saveGState()    // Save before clipping
cgContext.clip()          // Apply clipping
// ... draw image ...
cgContext.restoreGState() // Restore state
```

This prevents clipping from accumulating across cells and ensures each cell renders independently.

## 🐛 Known Issues & Fixes

### Recently Fixed
- ✅ **Export clipping bug**: Fixed graphics state management to properly isolate clipping between cells
- ✅ **Corner radius defaults**: Set minimum corner radius to 1 to prevent rendering issues

## 📱 Permissions

The app requires the following permissions:
- **Photo Library Access** (Add Only): To save exported collages
- **Photo Library Access** (Read): To select photos for the collage

## 🎯 Future Enhancements

Potential features for future releases:
- [ ] Additional layout templates (3×4, 4×4, custom layouts)
- [ ] Filters and effects
- [ ] Text overlay support
- [ ] Stickers and decorations
- [ ] Templates and themes
- [ ] Direct sharing to social media
- [ ] Collage history and favorites

## 📄 License

[Add your license here]

## 👤 Author

Created by Huan Nguyen

## 🙏 Acknowledgments

Built with SwiftUI and Core Graphics for iOS
