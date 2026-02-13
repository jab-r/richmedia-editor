//
// TextLayerEditorSheet.swift
// RichmediaEditor
//
// Modal sheet for editing text layer properties (text, style, animation)
//

import SwiftUI

#if canImport(UIKit)

struct TextLayerEditorSheet: View {
    @Binding var layer: TextLayer
    let onSave: (TextLayer) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var editedLayer: TextLayer
    @State private var showAnimationPicker = false

    init(layer: Binding<TextLayer>, onSave: @escaping (TextLayer) -> Void) {
        self._layer = layer
        self.onSave = onSave
        self._editedLayer = State(initialValue: layer.wrappedValue)
    }

    var body: some View {
        NavigationStack {
            Form {
                textSection
                styleSection
                animationSection
                previewSection
            }
            .navigationTitle("Edit Text Layer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        onSave(editedLayer)
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showAnimationPicker) {
                AnimationPresetPicker(
                    selectedPreset: Binding(
                        get: { editedLayer.animation?.preset },
                        set: { newPreset in
                            if let preset = newPreset {
                                editedLayer.animation = TextAnimation(preset: preset)
                            }
                        }
                    ),
                    onSelect: { preset in
                        editedLayer.animation = TextAnimation(preset: preset)
                    }
                )
            }
        }
    }

    // MARK: - Sections

    private var textSection: some View {
        Section("Text") {
            TextField("Enter text", text: $editedLayer.text, axis: .vertical)
                .lineLimit(3...6)
        }
    }

    private var styleSection: some View {
        Section("Style") {
            // Font family
            Picker("Font", selection: $editedLayer.style.font) {
                Text("System").tag("System")
                Text("Georgia").tag("Georgia")
                Text("Helvetica").tag("Helvetica")
                Text("Courier").tag("Courier")
                Text("Times New Roman").tag("Times New Roman")
            }

            // Font size
            HStack {
                Text("Size")
                Spacer()
                Stepper("\(Int(editedLayer.style.size))pt", value: $editedLayer.style.size, in: 10...48, step: 2)
            }

            // Text color
            ColorPicker("Color", selection: Binding(
                get: { Color(hex: editedLayer.style.color) },
                set: { editedLayer.style.color = $0.toHex() ?? "#FFFFFF" }
            ))

            // Formatting toggles
            Toggle("Bold", isOn: $editedLayer.style.bold)
            Toggle("Italic", isOn: $editedLayer.style.italic)
            Toggle("Underline", isOn: $editedLayer.style.underline)

            // Alignment
            Picker("Align", selection: $editedLayer.style.align) {
                Label("Left", systemImage: "text.alignleft").tag(TextAlignment.left)
                Label("Center", systemImage: "text.aligncenter").tag(TextAlignment.center)
                Label("Right", systemImage: "text.alignright").tag(TextAlignment.right)
            }
            .pickerStyle(.segmented)
        }
    }

    private var animationSection: some View {
        Section("Animation") {
            if let animation = editedLayer.animation {
                HStack {
                    VStack(alignment: .leading) {
                        Text(animation.preset.displayName)
                            .font(.body)
                        Text(animation.preset.category.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button("Change") {
                        showAnimationPicker = true
                    }
                }

                // Animation timing
                HStack {
                    Text("Delay")
                    Spacer()
                    Stepper("\(String(format: "%.1f", editedLayer.animation?.delay ?? 0))s",
                           value: Binding(
                            get: { editedLayer.animation?.delay ?? 0 },
                            set: { editedLayer.animation?.delay = $0 }
                           ),
                           in: 0...5, step: 0.1)
                }

                HStack {
                    Text("Duration")
                    Spacer()
                    Stepper("\(String(format: "%.1f", editedLayer.animation?.duration ?? 0.8))s",
                           value: Binding(
                            get: { editedLayer.animation?.duration ?? 0.8 },
                            set: { editedLayer.animation?.duration = $0 }
                           ),
                           in: 0.1...3, step: 0.1)
                }

                // Loop option for looping presets
                if animation.preset.category == .loop {
                    Toggle("Loop", isOn: Binding(
                        get: { editedLayer.animation?.loop ?? false },
                        set: { editedLayer.animation?.loop = $0 }
                    ))
                }

                Button("Remove Animation", role: .destructive) {
                    editedLayer.animation = nil
                }
            } else {
                Button("Add Animation") {
                    showAnimationPicker = true
                }
            }
        }
    }

    private var previewSection: some View {
        Section("Preview") {
            HStack {
                Spacer()
                previewText
                Spacer()
            }
            .frame(height: 100)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }

    @ViewBuilder
    private var previewText: some View {
        let baseText = Text(editedLayer.text.isEmpty ? "Preview" : editedLayer.text)
            .font(fontForStyle(editedLayer.style))
            .foregroundColor(Color(hex: editedLayer.style.color))
            .bold(editedLayer.style.bold)
            .italic(editedLayer.style.italic)
            .underline(editedLayer.style.underline)

        if let animation = editedLayer.animation {
            AnimationRenderer.animated(layer: editedLayer, content: baseText)
        } else {
            baseText
        }
    }

    // MARK: - Helpers

    private func fontForStyle(_ style: TextLayerStyle) -> Font {
        let size = style.size
        switch style.font {
        case "Georgia":
            return .custom("Georgia", size: size)
        case "Helvetica":
            return .custom("Helvetica", size: size)
        case "Courier":
            return .custom("Courier", size: size)
        case "Times New Roman":
            return .custom("Times New Roman", size: size)
        default:
            return .system(size: size)
        }
    }
}

#endif
