import Foundation
import UIKit
import AVFoundation
import Vision

class VisionViewController: ViewController {
    var request: VNRecognizeTextRequest!
    // Temporal string tracker
    let idTracker = StringTracker()
    
    override func viewDidLoad() {
        // Set up vision request before letting ViewController set up the camera
        // so that it exists when the first buffer is received.
        request = VNRecognizeTextRequest(completionHandler: recognizeTextHandler)

        super.viewDidLoad()
    }
    
    // MARK: - Text recognition
    
    // Vision recognition handler.
    func recognizeTextHandler(request: VNRequest, error: Error?) {
        var ids = [String]()
        guard let results = request.results as? [VNRecognizedTextObservation] else {
            return
        }
        
        let maximumCandidates = 1
        var stringToCheck = ""
        for visionResult in results {
            guard let candidate = visionResult.topCandidates(maximumCandidates).first else { continue }
            stringToCheck += candidate.string
            if let result = stringToCheck.extractID() {
                ids.append(result.1)
            }
        }
        
        // Log any found numbers.
        idTracker.logFrame(strings: ids)
        
        // Check if we have any temporally stable numbers.
        if let sureNumber = idTracker.getStableString() {
            showString(string: sureNumber)
            idTracker.reset(string: sureNumber)
        }
    }
    
    override func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            // Configure for running in real-time.
            request.recognitionLevel = .fast
            // Language correction won't help recognizing. It also
            // makes recognition slower.
            request.usesLanguageCorrection = false
            // Only run on the region of interest for maximum speed.
            request.regionOfInterest = regionOfInterest
            
            let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: textOrientation, options: [:])
            do {
                try requestHandler.perform([request])
            } catch {
                print(error)
            }
        }
    }
}
