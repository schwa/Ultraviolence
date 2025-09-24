// import simd
// import SwiftUI
// import UltraviolenceExampleShaders
//
// struct PBREditorView: View {
//    @Binding var selectedMaterial: MaterialPreset
//    @Binding var customMaterial: PBRMaterialNew
//    @Binding var animateLights: Bool
////    @Binding var lightIntensity: Float
////    @Binding var lightPosition: SIMD3<Float>
//
//    var body: some View {
//        Form {
//            Section("Material") {
//                Picker("Preset", selection: $selectedMaterial) {
//                    ForEach(MaterialPreset.allCases, id: \.self) { preset in
//                        Text(preset.rawValue).tag(preset)
//                    }
//                }
//
//                if selectedMaterial == .custom {
//                    customMaterialControls
//                }
//            }
//
//        }
//    }
//
//    @ViewBuilder
//    private var customMaterialControls: some View {
////        ColorPicker("Albedo", selection: $customMaterial.albedo.color)
//
//        LabeledContent("Metallic") {
//            HStack {
//                Slider(value: $customMaterial.metallic, in: 0...1)
//                Text("\(customMaterial.metallic, format: .number.precision(.fractionLength(2)))")
//                    .monospacedDigit()
//                    .frame(width: 50)
//            }
//        }
//
//        LabeledContent("Roughness") {
//            HStack {
//                Slider(value: $customMaterial.roughness, in: 0...1)
//                Text("\(customMaterial.roughness, format: .number.precision(.fractionLength(2)))")
//                    .monospacedDigit()
//                    .frame(width: 50)
//            }
//        }
//
//        LabeledContent("Ambient Occlusion") {
//            HStack {
//                Slider(value: $customMaterial.ambientOcclusion, in: 0...1)
//                Text("\(customMaterial.ambientOcclusion, format: .number.precision(.fractionLength(2)))")
//                    .monospacedDigit()
//                    .frame(width: 50)
//            }
//        }
//
//        LabeledContent("Clearcoat") {
//            HStack {
//                Slider(value: $customMaterial.clearcoat, in: 0...1)
//                Text("\(customMaterial.clearcoat, format: .number.precision(.fractionLength(2)))")
//                    .monospacedDigit()
//                    .frame(width: 50)
//            }
//        }
//
//        LabeledContent("Clearcoat Roughness") {
//            HStack {
//                Slider(value: $customMaterial.clearcoatRoughness, in: 0...1)
//                Text("\(customMaterial.clearcoatRoughness, format: .number.precision(.fractionLength(2)))")
//                    .monospacedDigit()
//                    .frame(width: 50)
//            }
//        }
//
//        // Subsurface scattering controls
//        LabeledContent("Soft Scattering") {
//            HStack {
//                Slider(value: $customMaterial.softScattering, in: 0...1)
//                Text("\(customMaterial.softScattering, format: .number.precision(.fractionLength(2)))")
//                    .monospacedDigit()
//                    .frame(width: 50)
//            }
//        }
//
//        if customMaterial.softScattering > 0 {
//            ColorPicker("Scattering Tint", selection: $customMaterial.softScatteringTint.color)
//
//            LabeledContent("Scattering Depth (RGB)") {
//                HStack {
//                    TextField("R", value: $customMaterial.softScatteringDepth.x, format: .number)
//                        .frame(width: 50)
//                    TextField("G", value: $customMaterial.softScatteringDepth.y, format: .number)
//                        .frame(width: 50)
//                    TextField("B", value: $customMaterial.softScatteringDepth.z, format: .number)
//                        .frame(width: 50)
//                }
//                .textFieldStyle(.roundedBorder)
//            }
//        }
//
//        // Emissive controls
//        ColorPicker("Emissive", selection: $customMaterial.emissive.color)
//
//        if customMaterial.emissive != .zero {
//            LabeledContent("Emissive Intensity") {
//                HStack {
//                    Slider(value: $customMaterial.emissiveIntensity, in: 0...10)
//                    Text("\(customMaterial.emissiveIntensity, format: .number.precision(.fractionLength(2)))")
//                        .monospacedDigit()
//                        .frame(width: 50)
//                }
//            }
//        }
//    }
// }
//
