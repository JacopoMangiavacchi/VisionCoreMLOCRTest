//
//  ViewController.swift
//  VisionCoreMLOCRTest
//
//  Created by Jacopo Mangiavacchi on 8/29/17.
//  Copyright © 2017 Jacopo. All rights reserved.
//

import UIKit
import TesseractOCR
import Vision


class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, G8TesseractDelegate {
    
    internal var requests = [VNRequest]()
    
    fileprivate var selectedImage: UIImage! {
        didSet {
            imageView?.image = selectedImage
            DispatchQueue.global().async {
                //OCR Entire main image
                let recognizedText = self.OCRImage(image: self.selectedImage)
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "OCR",
                                                  message: recognizedText,
                                                  preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                    self.present(alert, animated: true)
                }
                
                
                //Vision Detection of text area in the main image using CoreGraphics
                if let cgImage = self.selectedImage.cgImage {
                    let imageRequestsHandler = VNImageRequestHandler(cgImage: cgImage, orientation: CGImagePropertyOrientation.right, options: [.properties : ""])
                    do {
                        try imageRequestsHandler.perform(self.requests)
                    } catch {
                        print(error)
                    }
                }
                
                //Vision Detection of text area in the main image using CoreImage
                if let ciImage = CIImage(image: self.selectedImage) {
                    let imageToAnalyis = ciImage.oriented(forExifOrientation: Int32(self.selectedImage.imageOrientation.rawValue))
                    let imageRequestsHandler = VNImageRequestHandler(ciImage: imageToAnalyis, orientation: CGImagePropertyOrientation.left /*CGImagePropertyOrientation(rawValue: UInt32(self.selectedImage.imageOrientation.rawValue))! */, options: [.properties : ""])
                    do {
                        try imageRequestsHandler.perform(self.requests)
                    } catch {
                        print(error)
                    }
                }
            }
        }
    }
    
    
    func OCRImage(image: UIImage) -> String {
        let tesseract:G8Tesseract = G8Tesseract(language:"eng")
        tesseract.delegate = self
        tesseract.charWhitelist = "ABCDEFGHIJKLMNOPQRSTUVXYWZ01234567890"
        tesseract.image = image
        tesseract.recognize()
        
        print(tesseract.recognizedText)
        
        return tesseract.recognizedText
    }

    
    func startTextDetection() {
        let textRequest = VNDetectTextRectanglesRequest(completionHandler: self.detectTextHandler)
        textRequest.reportCharacterBoxes = false
        self.requests = [textRequest]
    }
    
    
    func detectTextHandler(request: VNRequest, error: Error?) {
        guard let observations = request.results as? [VNTextObservation] else {
            print("no result or wrong cast")
            return
        }
        
        DispatchQueue.main.async() {
//            // Show boxes as subview
//            self.imageView.subviews.forEach({ (s) in
//                s.removeFromSuperview()
//            })
//            for box in observations {
//                let view = self.CreateBoxView(withColor: UIColor.green)
//                view.frame = self.transformRect(fromRect: box.boundingBox, toViewRect: self.imageView)
//                self.imageView.addSubview(view)
//            }
            
            // draw on a transparent image the text boxes
            UIGraphicsBeginImageContextWithOptions(self.selectedImage.size, false, 0)

            let context = UIGraphicsGetCurrentContext()
            context?.setStrokeColor(UIColor.green.cgColor)
            context?.translateBy(x: 0, y: self.selectedImage.size.height)
            context?.scaleBy(x: 1, y: -1)
            //context?.draw(self.selectedImage.cgImage!, in: CGRect(origin: .zero, size: self.selectedImage.size)) //must rotate !!!!!

            for textObservation in observations {
                let rect: CGRect = {
                    var rect = CGRect()
                    rect.origin.x = textObservation.boundingBox.origin.x * self.selectedImage.size.width
                    rect.origin.y = textObservation.boundingBox.origin.y * self.selectedImage.size.height
                    rect.size.width = textObservation.boundingBox.size.width * self.selectedImage.size.width
                    rect.size.height = textObservation.boundingBox.size.height * self.selectedImage.size.height
                    return rect
                }()

                print(textObservation)
                print(rect)
                context?.stroke(rect, width: 5)
            }

            let drawnImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()

            
            
            // Redraw grapichs context
            UIGraphicsBeginImageContextWithOptions(self.selectedImage.size, true, 0)

            self.selectedImage.draw(in: CGRect(origin: .zero, size: self.selectedImage.size))
            drawnImage?.draw(in: CGRect(origin: .zero, size: self.selectedImage.size))
            
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()

            
            self.imageView.image = newImage
        }
    }

    
    //Convert Vision Frame to UIKit Frame
    func transformRect(fromRect: CGRect , toViewRect :UIView) -> CGRect {
        var toRect = CGRect()
        toRect.size.width = fromRect.size.width * toViewRect.frame.size.width
        toRect.size.height = fromRect.size.height * toViewRect.frame.size.height
        toRect.origin.y =  (toViewRect.frame.height) - (toViewRect.frame.height * fromRect.origin.y )
        toRect.origin.y  = toRect.origin.y -  toRect.size.height
        toRect.origin.x =  fromRect.origin.x * toViewRect.frame.size.width
        
        return toRect
    }
    
    
    func CreateBoxView(withColor : UIColor) -> UIView {
        let view = UIView()
        view.layer.borderColor = withColor.cgColor
        view.layer.borderWidth = 5
        view.backgroundColor = UIColor.clear
        return view
    }
    
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBAction func selectImage(sender: Any) {
        let picker = UIImagePickerController()
        picker.delegate = self
        
        let alert = UIAlertController(title: "Photo",
                                      message: "Take a new Picture or select one form Library",
                                      preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Camera", style: .default) { _ in
            picker.sourceType = .camera
            self.present(picker, animated: true)
        })
        alert.addAction(UIAlertAction(title: "Photo Library", style: .default) { _ in
            picker.sourceType = .photoLibrary
            self.present(picker, animated: true)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        self.present(alert, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        startTextDetection()
    }
    
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage
            else { fatalError("no image from image picker") }
        
        selectedImage = image
        
    }
    
    func shouldCancelImageRecognitionForTesseract(tesseract: G8Tesseract!) -> Bool {
        return false; // return true if you need to interrupt tesseract before it finishes
    }
}
