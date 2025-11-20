//
//  ContentView.swift
//  Gridify2
//
//  Created by Huan Nguyen on 21/11/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // App Title
                VStack(spacing: 8) {
                    Image(systemName: "square.grid.3x3")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    Text("Gridify")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("Create beautiful photo collages")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                // Layout Templates
                VStack(alignment: .leading, spacing: 16) {
                    Text("Choose a Layout")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ForEach(CollageLayout.defaultLayouts) { layout in
                        NavigationLink(destination: CollageEditorView(layout: layout)) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(layout.name)
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                    Text("\(layout.rows) rows × \(layout.columns) columns")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(uiColor: .systemGray6))
                            .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal)
                    }
                }
                
                Spacer()
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    ContentView()
}
