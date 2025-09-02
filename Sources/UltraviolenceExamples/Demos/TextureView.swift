import SwiftUI
import Ultraviolence
import UltraviolenceUI

struct TextureView: View {
    var texture: MTLTexture
    var slice: Int = 0

    var body: some View {
        RenderView {
            try RenderPass {
                try BillboardRenderPipeline(texture: texture, slice: slice)
            }
        }
    }
}
