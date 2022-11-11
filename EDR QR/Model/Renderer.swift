/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A delegate class for this application's `MTKView`.
*/

import Metal
import MetalKit
import CoreImage

class Renderer: NSObject, MTKViewDelegate, ObservableObject {
    
    let imageProvider: (_ contentScaleFactor: CGFloat, _ headroom: CGFloat) -> CIImage? // caller delegate function to provide image data
    
    public let device: MTLDevice? = MTLCreateSystemDefaultDevice()
    
    let commandQueue: MTLCommandQueue?
    let renderContext: CIContext? // set the name, cache preferences, and low power settings
    let renderQueue = DispatchSemaphore(value: 3) // Used to wait for a previous render to complete before drawing a new frame
    
    init(imageProvider: @escaping (_ contentScaleFactor: CGFloat, _ headroom: CGFloat) -> CIImage?) {
        self.imageProvider = imageProvider
        self.commandQueue = self.device?.makeCommandQueue()
        if let commandQueue {
            self.renderContext = CIContext(mtlCommandQueue: commandQueue,
                                       options: [.name: "Renderer",
                                                 .cacheIntermediates: true,
                                                 .allowLowPower: true])
        } else {
            self.renderContext = nil
        }
        super.init()
    }
    
    func draw(in view: MTKView) {
        
        guard let commandQueue else { return }

        // wait for previous render to complete
        _ = renderQueue.wait(timeout: DispatchTime.distantFuture)
        
        if let commandBuffer = commandQueue.makeCommandBuffer() {
            
            // when command completed, single the queue to allow rendering next frame
            commandBuffer.addCompletedHandler { (_ commandBuffer)-> Swift.Void in
                self.renderQueue.signal()
            }
            
            if let drawable = view.currentDrawable {
                
                let drawSize = view.drawableSize
                let contentScaleFactor = view.contentScaleFactor
                let destination = CIRenderDestination(width: Int(drawSize.width),
                                                      height: Int(drawSize.height),
                                                      pixelFormat: view.colorPixelFormat,
                                                      commandBuffer: commandBuffer,
                                                      mtlTextureProvider: { () -> MTLTexture in
                    return drawable.texture
                })
                
                // calculate the maximum supported EDR value (headroom)
                var headroom = CGFloat(1.0)
                if #available(iOS 16.0, *) {
                    headroom = view.window?.screen.currentEDRHeadroom ?? 1.0
                }
                
                // Get the CI image to be displayed from the delegate function
                guard var image = self.imageProvider(contentScaleFactor, headroom) else {
                    return
                }

                // Center the image in the view's visible area.
                let iRect = image.extent
                let backBounds = CGRect(x: 0,
                                        y: 0,
                                        width: drawSize.width,
                                        height: drawSize.height)
                let shiftX = round((backBounds.size.width + iRect.origin.x - iRect.size.width) * 0.5)
                let shiftY = round((backBounds.size.height + iRect.origin.y - iRect.size.height) * 0.5)
                image = image.transformed(by: CGAffineTransform(translationX: shiftX, y: shiftY))
                
                // provide a background if the image is transparent
                image = image.composited(over: .gray)
                
                // Start a task that renders to the texture destination.
                guard let renderContext else { return }
                _ = try? renderContext.startTask(toRender: image, from: backBounds,
                                                  to: destination, at: CGPoint.zero)
                
                // show rendered work and commit render task
                commandBuffer.present(drawable)
                commandBuffer.commit()
            }
        }
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Respond to drawable size or orientation changes.
    }
    
}
