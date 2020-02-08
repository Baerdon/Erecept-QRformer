/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Vision view controller.
            Recognizes text using a Vision VNRecognizeTextRequest request handler in pixel buffers from an AVCaptureOutput.
            Displays bounding boxes around recognized text results in real time.
*/

import Foundation
import UIKit
import AVFoundation
import Vision

class VisionViewController: ViewController {
    var request: VNRecognizeTextRequest!
    // Temporal string tracker
    let numberTracker = StringTracker()
    
    override func viewDidLoad() {
        // Set up vision request before letting ViewController set up the camera
        // so that it exists when the first buffer is received.
        request = VNRecognizeTextRequest(completionHandler: recognizeTextHandler)

        super.viewDidLoad()
    }
    
    // MARK: - Text recognition
    
    // Vision recognition handler.
    func recognizeTextHandler(request: VNRequest, error: Error?) {
        var numbers = [String]()
        var redBoxes = [CGRect]() // Shows all recognized text lines
        var greenBoxes = [CGRect]() // Shows words that might be serials
        
        guard let results = request.results as? [VNRecognizedTextObservation] else {
            return
        }
        
        let maximumCandidates = 1
        var stringToCheck = ""
        for visionResult in results {
            guard let candidate = visionResult.topCandidates(maximumCandidates).first else { continue }
            stringToCheck += candidate.string
            //print(candidate.string)
            //tady concatenate stringy z jednotlivejch kandidátů do jednoho
            //pak ten string prohnat regexem na ID receptu
            
            // Draw red boxes around any detected text, and green boxes around
            // any detected phone numbers. The phone number may be a substring
            // of the visionResult. If a substring, draw a green box around the
            // number and a red box around the full string. If the number covers
            // the full result only draw the green box.
            var numberIsSubstring = true
            
            if let result = stringToCheck.extractPhoneNumber() {
                numbers.append(result.1)
                //candidate.string.extractPhoneNumber() {
                //print(result.1)
                let (range, number) = result
                // Number may not cover full visionResult. Extract bounding box
                // of substring.
                if let box = try? candidate.boundingBox(for: range)?.boundingBox {
                    numbers.append(number)
                    greenBoxes.append(box)
                    numberIsSubstring = !(range.lowerBound == candidate.string.startIndex && range.upperBound == candidate.string.endIndex)
                }
            }
            if numberIsSubstring {
                redBoxes.append(visionResult.boundingBox)
            }
        }
        
        // Log any found numbers.
        numberTracker.logFrame(strings: numbers)
        show(boxGroups: [(color: UIColor.red.cgColor, boxes: redBoxes), (color: UIColor.green.cgColor, boxes: greenBoxes)])
        
        // Check if we have any temporally stable numbers.
        if let sureNumber = numberTracker.getStableString() {
            showString(string: sureNumber)
            numberTracker.reset(string: sureNumber)
        }
    }
    
    override func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            // Configure for running in real-time.
            request.recognitionLevel = .fast
            // Language correction won't help recognizing phone numbers. It also
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
    
    // MARK: - Bounding box drawing
    
    // Draw a box on screen. Must be called from main queue.
    var boxLayer = [CAShapeLayer]()
    func draw(rect: CGRect, color: CGColor) {
        let layer = CAShapeLayer()
        layer.opacity = 0.5
        layer.borderColor = color
        layer.borderWidth = 1
        layer.frame = rect
        boxLayer.append(layer)
        previewView.videoPreviewLayer.insertSublayer(layer, at: 1)
    }
    
    // Remove all drawn boxes. Must be called on main queue.
    func removeBoxes() {
        for layer in boxLayer {
            layer.removeFromSuperlayer()
        }
        boxLayer.removeAll()
    }
    
    typealias ColoredBoxGroup = (color: CGColor, boxes: [CGRect])
    
    // Draws groups of colored boxes.
    func show(boxGroups: [ColoredBoxGroup]) {
        DispatchQueue.main.async {
            let layer = self.previewView.videoPreviewLayer
            self.removeBoxes()
            for boxGroup in boxGroups {
                let color = boxGroup.color
                for box in boxGroup.boxes {
                    let rect = layer.layerRectConverted(fromMetadataOutputRect: box.applying(self.visionToAVFTransform))
                    self.draw(rect: rect, color: color)
                }
            }
        }
    }
}

//My version
/*import Foundation
import UIKit
import AVFoundation
import Vision

class VisionViewController: ViewController {
	var request: VNRecognizeTextRequest!
	// Temporal string tracker
	let numberTracker = StringTracker()
    var recognizedText = ""
	
	override func viewDidLoad() {
		// Set up vision request before letting ViewController set up the camera
		// so that it exists when the first buffer is received.
        request = VNRecognizeTextRequest(completionHandler: { (request, error) in
            if let results = request.results, !results.isEmpty {
                if let requestResults = request.results as? [VNRecognizedTextObservation] {
                    self.recognizedText = ""
                    for observation in requestResults {
                        guard let candidate = observation.topCandidates(1).first else { return }
                          self.recognizedText += candidate.string
                    }
                    if let match = self.processText(text: self.recognizedText) {
                        self.showString(string: match)
                    }
                }
            }
        })
		super.viewDidLoad()
	}
	
    func processText(text: String) -> String? {
        if let r = text.extractID() {
            let res = r.1.correctString()
            //tady eště úprava těch znaků, co budou špatně
            return res
        } else {
            return nil
        }
    }
    
	// MARK: - Text recognition
	
	override func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
		if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
			// Configure for running in real-time.
			request.recognitionLevel = .fast
			// Language correction won't help recognizing IDs. It also makes recognition slower.
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
}*/
