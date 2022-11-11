/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A representable container that uses a `MTKView` to periodically render a `CIImage`.
*/

import SwiftUI
import MetalKit

struct MetalView_SwiftUICompatible: UIViewRepresentable {
    
    @StateObject var renderer: Renderer
    /// - Tag: MakeView
    func makeUIView(context: Context) -> MTKView {
        let view = MTKView(frame: .zero, device: renderer.device)

        // Suggest to Core Animation, through MetalKit, how often to redraw the view.
        view.preferredFramesPerSecond = 10

        // Allow Core Image to render to the view using the Metal compute pipeline.
        view.framebufferOnly = false
        view.delegate = renderer

        if let layer = view.layer as? CAMetalLayer {
            // Enable EDR with a color space that supports values greater than SDR.
            if #available(iOS 16.0, *) {
                layer.wantsExtendedDynamicRangeContent = true
            }
            layer.colorspace = CGColorSpace(name: CGColorSpace.extendedLinearDisplayP3)
            // Ensure the render view supports pixel values in EDR.
            view.colorPixelFormat = MTLPixelFormat.rgba16Float
        }
        return view
    }
    
    func updateUIView(_ view: MTKView, context: Context) {
        configure(view: view, using: renderer)
    }
    
    private func configure(view: MTKView, using renderer: Renderer) {
        view.delegate = renderer
    }
}
