//
//  ViewController.swift
//  VisionCoreMLOCRTest
//
//  Created by Jacopo Mangiavacchi on 8/29/17.
//  Copyright © 2017 Jacopo. All rights reserved.
//

import UIKit
import TesseractOCR


class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, G8TesseractDelegate {
    
    fileprivate var selectedImage: UIImage! {
        didSet {
            imageView?.image = selectedImage
            DispatchQueue.global().async {
                let tesseract:G8Tesseract = G8Tesseract(language:"eng")
                tesseract.delegate = self
                tesseract.charWhitelist = "ABCDEFGHIJKLMNOPQRSTUVXYWZ01234567890"
                tesseract.image = self.selectedImage
                tesseract.recognize()
                
                NSLog("%@", tesseract.recognizedText);
                
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "OCR",
                                                  message: tesseract.recognizedText,
                                                  preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                    self.present(alert, animated: true)
                }
            }
        }
    }
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBAction func selectImage(sender: Any) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .camera
        present(picker, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
