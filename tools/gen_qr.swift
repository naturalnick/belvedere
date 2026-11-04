import AppKit
import CoreImage
import Vision

let destination = "https://puzzaholics.com/belvedere-assembly"
let output = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    .appendingPathComponent("assets/belvedere_assembly_qr.png")

func verify(_ url: URL) throws {
    let request = VNDetectBarcodesRequest()
    request.symbologies = [.qr]
    try VNImageRequestHandler(url: url).perform([request])
    guard request.results?.contains(where: { $0.payloadStringValue == destination }) == true else {
        throw NSError(domain: "BelvedereQR", code: 1,
                      userInfo: [NSLocalizedDescriptionKey: "QR verification failed: \(url.path)"])
    }
    print("Verified \(url.path): \(destination)")
}

func run() throws {
    if CommandLine.arguments.count > 1 {
        for path in CommandLine.arguments.dropFirst() {
            try verify(URL(fileURLWithPath: path))
        }
    } else {
        let generator = CIFilter(name: "CIQRCodeGenerator")!
        generator.setValue(Data(destination.utf8), forKey: "inputMessage")
        generator.setValue("Q", forKey: "inputCorrectionLevel")
        let qr = generator.outputImage!
        let image = CIContext().createCGImage(qr, from: qr.extent)!
        let scale = 24
        let margin = 4 * scale
        let size = image.width * scale + 2 * margin
        let canvas = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8,
                               bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
                               bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        canvas.setFillColor(CGColor(gray: 1, alpha: 1))
        canvas.fill(CGRect(x: 0, y: 0, width: size, height: size))
        canvas.interpolationQuality = .none
        canvas.draw(image, in: CGRect(x: margin, y: margin, width: image.width * scale,
                                     height: image.height * scale))
        let png = NSBitmapImageRep(cgImage: canvas.makeImage()!).representation(using: .png, properties: [:])!
        try png.write(to: output)
        try verify(output)
    }
}

do {
    try run()
} catch {
    fputs("\(error.localizedDescription)\n", stderr)
    exit(1)
}
