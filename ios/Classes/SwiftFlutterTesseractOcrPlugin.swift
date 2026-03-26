import Flutter
import UIKit
import SwiftyTesseract

public class SwiftFlutterTesseractOcrPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_tesseract_ocr", binaryMessenger: registrar.messenger())
        let instance = SwiftFlutterTesseractOcrPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    
          initializeTessData()
            
    
        if call.method == "extractText" {
            
            guard let args = call.arguments else {
                result("iOS could not recognize flutter arguments in method: (sendParams)")
                return
            }
            
            let params: [String : Any] = args as! [String : Any]
            let language: String? = params["language"] as? String
            var swiftyTesseract = SwiftyTesseract(language: .english)
            if let language {
                swiftyTesseract = SwiftyTesseract(language: .custom(language))
            }
            let  imagePath = params["imagePath"] as! String
            guard let image = UIImage(contentsOfFile: imagePath)else { return }
            
            swiftyTesseract.performOCR(on: image) { recognizedString in
                
                guard let extractText = recognizedString else { return }
                result(extractText)
            }
        }
    }
    
 func initializeTessData() {
    let fileManager = FileManager.default

    // Resolve Documents directory
    guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
        print("❌ Could not locate Documents directory")
        return
    }

    let destURL = documentsURL.appendingPathComponent("tessdata")

    // Resolve bundled tessdata
    guard let sourceURL = Bundle.main.resourceURL?.appendingPathComponent("tessdata") else {
        print("❌ Could not locate tessdata in bundle")
        return
    }

    let hasCopiedKey = "didCopyTessdata"

    // Copy only once (first launch)
    if !UserDefaults.standard.bool(forKey: hasCopiedKey) {
        do {
            // Extra safety: remove any partial/failed copy
            if fileManager.fileExists(atPath: destURL.path) {
                try fileManager.removeItem(at: destURL)
            }

            try fileManager.copyItem(at: sourceURL, to: destURL)

            UserDefaults.standard.set(true, forKey: hasCopiedKey)
            print("✅ tessdata copied (first launch)")
        } catch {
            print("❌ Copy failed:", error)
            return
        }
    } else {
        print("ℹ️ tessdata already prepared")
    }

    // Always set environment variable (must happen every launch)
    setenv("TESSDATA_PREFIX", destURL.path, 1)
}
}
