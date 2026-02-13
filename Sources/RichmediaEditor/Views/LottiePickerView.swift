//
// LottiePickerView.swift
// RichmediaEditor
//
// File picker for importing Lottie JSON animations
//

import SwiftUI
import UniformTypeIdentifiers

#if canImport(UIKit)

struct LottiePickerView: View {
    let onSelect: (LottieAnimation) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var showFilePicker = false
    @State private var showTemplates = true

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tabs
                Picker("Source", selection: $showTemplates) {
                    Text("Templates").tag(true)
                    Text("Import").tag(false)
                }
                .pickerStyle(.segmented)
                .padding()

                if showTemplates {
                    templatesView
                } else {
                    importView
                }
            }
            .navigationTitle("Lottie Animations")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [UTType.json],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result)
            }
        }
    }

    // MARK: - Templates View

    private var templatesView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Built-in Templates")
                    .font(.headline)
                    .padding(.horizontal)

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(LottieTemplates.allTemplates, id: \.name) { template in
                        TemplateCard(template: template) {
                            if let animation = LottieTemplates.loadTemplate(template) {
                                onSelect(animation)
                                dismiss()
                            }
                        }
                    }
                }
                .padding()
            }
        }
    }

    // MARK: - Import View

    private var importView: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 100, height: 100)

                Image(systemName: "doc.badge.plus")
                    .font(.system(size: 40))
                    .foregroundStyle(.blue.gradient)
            }

            // Instructions
            VStack(spacing: 8) {
                Text("Import Lottie Animation")
                    .font(.title3)
                    .fontWeight(.semibold)

                Text("Select a .json file exported from After Effects using the Bodymovin plugin")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            // Import button
            Button(action: {
                showFilePicker = true
            }) {
                Label("Choose File", systemImage: "folder")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
            }

            Spacer()

            // Help text
            VStack(alignment: .leading, spacing: 8) {
                Text("Supported:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    Text("Lottie JSON files (.json)")
                        .font(.caption)
                }

                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    Text("Exported from After Effects + Bodymovin")
                        .font(.caption)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(12)
            .padding()
        }
    }

    // MARK: - File Import Handler

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }

            // Import Lottie animation
            if let animation = LottieImporter.importAnimation(from: url) {
                onSelect(animation)
                dismiss()
            } else {
                // TODO: Show error alert
                print("Failed to import Lottie animation")
            }

        case .failure(let error):
            print("File picker error: \(error)")
        }
    }
}

// MARK: - Template Card

struct TemplateCard: View {
    let template: LottieTemplate
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 12) {
                // Preview thumbnail (placeholder)
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                        .frame(height: 120)

                    Image(systemName: template.icon)
                        .font(.system(size: 40))
                        .foregroundStyle(.blue.gradient)
                }

                // Template info
                VStack(spacing: 4) {
                    Text(template.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)

                    Text(template.category)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(12)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Lottie Templates

struct LottieTemplate {
    let name: String
    let category: String
    let icon: String
    let filename: String
}

enum LottieTemplates {
    static let allTemplates: [LottieTemplate] = [
        LottieTemplate(name: "Confetti", category: "Celebration", icon: "party.popper", filename: "confetti"),
        LottieTemplate(name: "Sparkles", category: "Effects", icon: "sparkles", filename: "sparkles"),
        LottieTemplate(name: "Loading", category: "UI", icon: "arrow.clockwise", filename: "loading"),
        LottieTemplate(name: "Heart Beat", category: "Emoji", icon: "heart.fill", filename: "heart_beat"),
        LottieTemplate(name: "Star Burst", category: "Effects", icon: "star.fill", filename: "star_burst"),
        LottieTemplate(name: "Checkmark", category: "UI", icon: "checkmark.circle", filename: "checkmark"),
    ]

    static func loadTemplate(_ template: LottieTemplate) -> LottieAnimation? {
        // Placeholder: In production, these would be bundled JSON files
        // For now, return a simple animated structure

        let sampleLottieJSON = """
        {
          "v": "5.7.4",
          "fr": 60,
          "ip": 0,
          "op": 120,
          "w": 400,
          "h": 400,
          "nm": "\(template.name)",
          "ddd": 0,
          "assets": [],
          "layers": []
        }
        """

        return LottieAnimation(
            jsonData: sampleLottieJSON,
            name: template.name,
            duration: 2.0,
            frameRate: 60,
            loops: true
        )
    }
}

#endif
