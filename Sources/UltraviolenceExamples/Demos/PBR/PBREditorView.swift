import simd
import SwiftUI
import UltraviolenceExampleShaders

struct PBREditorView: View {
    @Binding var selectedMaterial: MaterialPreset
    @Binding var customMaterial: PBRMaterial
    @Binding var animateLights: Bool
//    @Binding var lightIntensity: Float
//    @Binding var lightPosition: SIMD3<Float>

    var body: some View {
        Form {
            Section("Material") {
                Picker("Preset", selection: $selectedMaterial) {
                    ForEach(MaterialPreset.allCases, id: \.self) { preset in
                        Text(preset.rawValue).tag(preset)
                    }
                }

                if selectedMaterial == .custom {
                    customMaterialControls
                }
            }

            Section("Lighting") {
                Toggle("Animate Lights", isOn: $animateLights)
//
//                if !animateLights {
//                    LabeledContent("Intensity") {
//                        HStack {
//                            Slider(value: $lightIntensity, in: 0...50)
//                            Text("\(lightIntensity, format: .number.precision(.fractionLength(1)))")
//                                .monospacedDigit()
//                                .frame(width: 50)
//                        }
//                    }
//
//                    LabeledContent("Position") {
//                        HStack {
//                            TextField("X", value: $lightPosition.x, format: .number)
//                            TextField("Y", value: $lightPosition.y, format: .number)
//                            TextField("Z", value: $lightPosition.z, format: .number)
//                        }
//                        .textFieldStyle(.roundedBorder)
//                    }
//                }
            }
        }
//        .onChange(of: lightIntensity) {
//            if !animateLights, !lights.isEmpty {
//                lights[0].intensity = lightIntensity
//            }
//        }
//        .onChange(of: lightPosition) {
//            if !animateLights, !lights.isEmpty {
//                lights[0].position = lightPosition
//            }
//        }
    }

    @ViewBuilder
    private var customMaterialControls: some View {
        ColorPicker("Albedo", selection: $customMaterial.albedo.color)

        LabeledContent("Metallic") {
            HStack {
                Slider(value: $customMaterial.metallic, in: 0...1)
                Text("\(customMaterial.metallic, format: .number.precision(.fractionLength(2)))")
                    .monospacedDigit()
                    .frame(width: 50)
            }
        }

        LabeledContent("Roughness") {
            HStack {
                Slider(value: $customMaterial.roughness, in: 0...1)
                Text("\(customMaterial.roughness, format: .number.precision(.fractionLength(2)))")
                    .monospacedDigit()
                    .frame(width: 50)
            }
        }

        LabeledContent("Ambient Occlusion") {
            HStack {
                Slider(value: $customMaterial.ao, in: 0...1)
                Text("\(customMaterial.ao, format: .number.precision(.fractionLength(2)))")
                    .monospacedDigit()
                    .frame(width: 50)
            }
        }

        LabeledContent("Clearcoat") {
            HStack {
                Slider(value: $customMaterial.clearcoat, in: 0...1)
                Text("\(customMaterial.clearcoat, format: .number.precision(.fractionLength(2)))")
                    .monospacedDigit()
                    .frame(width: 50)
            }
        }

        LabeledContent("Clearcoat Roughness") {
            HStack {
                Slider(value: $customMaterial.clearcoatRoughness, in: 0...1)
                Text("\(customMaterial.clearcoatRoughness, format: .number.precision(.fractionLength(2)))")
                    .monospacedDigit()
                    .frame(width: 50)
            }
        }

        // Subsurface scattering controls
        LabeledContent("Soft Scattering") {
            HStack {
                Slider(value: $customMaterial.softScattering, in: 0...1)
                Text("\(customMaterial.softScattering, format: .number.precision(.fractionLength(2)))")
                    .monospacedDigit()
                    .frame(width: 50)
            }
        }

        if customMaterial.softScattering > 0 {
            ColorPicker("Scattering Tint", selection: $customMaterial.softScatteringTint.color)

            LabeledContent("Scattering Depth (RGB)") {
                HStack {
                    TextField("R", value: $customMaterial.softScatteringDepth.x, format: .number)
                        .frame(width: 50)
                    TextField("G", value: $customMaterial.softScatteringDepth.y, format: .number)
                        .frame(width: 50)
                    TextField("B", value: $customMaterial.softScatteringDepth.z, format: .number)
                        .frame(width: 50)
                }
                .textFieldStyle(.roundedBorder)
            }
        }

        // Emissive controls
        ColorPicker("Emissive", selection: $customMaterial.emissive.color)

        if customMaterial.emissive != .zero {
            LabeledContent("Emissive Intensity") {
                HStack {
                    Slider(value: $customMaterial.emissiveIntensity, in: 0...10)
                    Text("\(customMaterial.emissiveIntensity, format: .number.precision(.fractionLength(2)))")
                        .monospacedDigit()
                        .frame(width: 50)
                }
            }
        }
    }
}

enum MaterialPreset: String, CaseIterable {
    case gold = "Gold"
    case silver = "Silver"
    case copper = "Copper"
    case plastic = "Plastic"
    case rubber = "Rubber"
    case carPaint = "Car Paint"
    case lacqueredWood = "Lacquered Wood"
    case wetPlastic = "Wet Plastic"
    case wax = "Wax"
    case jade = "Jade"
    case skin = "Skin"
    case marble = "Marble"
    case custom = "Custom"

    var material: PBRMaterial {
        switch self {
        case .gold: return .gold
        case .silver: return .silver
        case .copper: return .copper
        case .plastic: return .plastic
        case .rubber: return .rubber
        case .carPaint: return .carPaint
        case .lacqueredWood: return .lacqueredWood
        case .wetPlastic: return .wetPlastic
        case .wax: return .wax
        case .jade: return .jade
        case .skin: return .skin
        case .marble: return .marble
        case .custom: return PBRMaterial()
        }
    }
}
