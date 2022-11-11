//
//  HighlightedQRCodeView.swift
//  RenderDestinationMetalView (iOS)
//
//  Created by msz on 2022/11/10.
//  Copyright © 2022 Apple. All rights reserved.
//

import SwiftUI

struct HighlightedQRCodeView: View {
    
    var qrCodeTextContent: String
    var imageRenderSize: CGSize
    var qrCodeScaleFactor: CGFloat
    
    var body: some View {
        
        // Create a Metal view with its own renderer.
        let renderer = Renderer(imageProvider: { (scaleFactor: CGFloat, headroom: CGFloat) -> CIImage? in
            
            // Generate the QR code image
            guard let qrFilter = CIFilter(name: "CIQRCodeGenerator") else {
                return nil
            }
            
            let inputData = qrCodeTextContent.data(using: .utf8)
            qrFilter.setValue(inputData, forKey: "inputMessage")
            qrFilter.setValue("H", forKey: "inputCorrectionLevel")
            
            guard let image = qrFilter.outputImage else {
                return nil
            }
            
            let sizeTransform = CGAffineTransform(scaleX: qrCodeScaleFactor, y: qrCodeScaleFactor)
            let qrImage = image.transformed(by: sizeTransform)
            
            // Generate blank fill image with the max RGB color
            let maxRGB = headroom
            guard let EDR_colorSpace = CGColorSpace(name: CGColorSpace.extendedLinearSRGB),
                  let maxFillColor = CIColor(red: maxRGB, green: maxRGB, blue: maxRGB,
                                             colorSpace: EDR_colorSpace) else {
                return nil
            }
            let fillImage = CIImage(color: maxFillColor)
            
            // Use mask filter to create final QR code image
            let maskFilter = CIFilter.blendWithMask()
            maskFilter.maskImage = qrImage
            maskFilter.inputImage = fillImage
            
            // combine highlight layer and QR image
            guard let combinedImage = maskFilter.outputImage else {
                return nil
            }
            return combinedImage.cropped(to: CGRect(x: 0, y: 0,
                                                    width: imageRenderSize.width * scaleFactor,
                                                    height: imageRenderSize.height * scaleFactor))
        })
        
        MetalView(renderer: renderer)
        
    }
    
}

struct HighlightedQRCodeView_Previews: PreviewProvider {
    static var previews: some View {
        HighlightedQRCodeView(qrCodeTextContent: "test-qr-code",
                              imageRenderSize: .init(width: 300, height: 300),
                              qrCodeScaleFactor: 12
        )
    }
}
