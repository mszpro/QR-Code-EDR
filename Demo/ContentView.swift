/*
See LICENSE folder for this sample’s licensing information.

Abstract:
ContentView class that returns a `CIImage` for the current time.
*/

import SwiftUI
import CoreImage.CIFilterBuiltins

/// - Tag: ContentView
struct ContentView: View {
    
    let qrCodeStringContent: String = "testing-highlighted-qr"
    
    var body: some View {

        VStack {
            
            if #available(iOS 16.0, *) {
                if UIScreen.main.currentEDRHeadroom <= 1 {
                    Label("Current screen does not support EDR. Please test on a real iPhone, not the simulator.", systemImage: "exclamationmark.bubble")
                } else {
                    Text("EDR QR code:")
                        .font(.headline)
                    HighlightedQRCodeView(qrCodeTextContent: qrCodeStringContent,
                                          imageRenderSize: .init(width: 300, height: 300),
                                          qrCodeScaleFactor: 15)
                    .frame(width: 300, height: 300)
                }
            }
            
            Text("Here is a regular QR code")
                .font(.headline)
            Image(uiImage: generateQRCode(from: qrCodeStringContent))
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
            
        }
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

/*
 For a comparsion
 */
func generateQRCode(from string: String) -> UIImage {
    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()
    filter.message = Data(string.utf8)
    if let outputImage = filter.outputImage {
        if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
            return UIImage(cgImage: cgimg)
        }
    }
    return UIImage(systemName: "xmark.circle") ?? UIImage()
}
