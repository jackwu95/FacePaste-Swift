//
//  ViewController.swift
//  FacePasteSwift
//
//  Created by Jack Wu on 2014-06-05.
//  Copyright (c) 2014 Jack Wu. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, FaceDetectorDelegate, ImageProcessorDelegate {
                            
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        imageView.contentMode = UIViewContentMode.ScaleAspectFit
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBOutlet var imageView : UIImageView
    
    @lazy var imagePicker : UIImagePickerController = {
        println("Creating image picker")
        return UIImagePickerController()
    }()
    
    var workingImage : UIImage!
    var buttons : Array<UIButton> = []
    var detectedFaces : Array<Face>!
    
    @IBAction func pickFromAlbum(sender : UIBarButtonItem) {
        imagePicker.delegate = self
        imagePicker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        self.presentViewController(imagePicker, animated: true, completion: nil)
    }

    @IBAction func pickFromCamera(sender : UIBarButtonItem) {
        imagePicker.delegate = self
        imagePicker.sourceType = UIImagePickerControllerSourceType.Camera
        self.presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController!, didFinishPickingMediaWithInfo info: NSDictionary!) {
        self.dismissViewControllerAnimated(true, completion: nil)
        
        for b : UIButton in buttons {
            b.removeFromSuperview()
        }
        buttons.removeAll(keepCapacity: false)
        
        workingImage = info[UIImagePickerControllerOriginalImage] as UIImage
        imageView.image = workingImage
        
        let detector = FaceDetector.sharedDetector
        detector.delegate = self
        detector.detectFacesInImage(workingImage)
    }
    
    func faceDetectorDidFinishDetecingWith(image: UIImage, faces: Array<Face>)  {
        println("Found \(faces.count) faces")
        imageView.image = image;
        detectedFaces = faces
        
        // Set up some face buttons

        let frameOfResizedImage = imageView.frameOfResizedImage()
        let sizeOfImage = imageView.image.size
        let scale = frameOfResizedImage.size.width / sizeOfImage.width
        let scaleTransform = CGAffineTransformMakeScale(scale, scale)
        
        var i = 0
        for face:Face in faces {
            let adjustedBounds : CGRect = {
                var adjusted = face.bounds
                adjusted.origin.x += frameOfResizedImage.origin.x / scale
                adjusted.origin.y += frameOfResizedImage.origin.y / scale
                return adjusted
            }()
            let frame = CGRectApplyAffineTransform(adjustedBounds, scaleTransform)
            
            let button : UIButton = {
                let button = UIButton(frame: frame)
                button.addTarget(self, action: Selector("faceButtonPressed:"), forControlEvents: UIControlEvents.TouchUpInside)
                button.layer.borderWidth = 2
                button.layer.borderColor = UIColor.whiteColor().CGColor
                button.layer.cornerRadius = button.bounds.width/2
                button.tag = i++
                return button
            } ()
            
            self.view.addSubview(button)
            self.buttons.append(button)
        }
    }
    
    func faceButtonPressed(sender: UIButton) {
        let processor = ImageProcessor.sharedDetector
        processor.delegate = self
        let face = detectedFaces[sender.tag]
        processor.replaceFacesInImage(workingImage, face: face, faces: detectedFaces)
    }
    
    func imageProcessorFinishedProcessingImage(image: UIImage)  {
        imageView.image = image
    }
}

extension UIImageView {
    func frameOfResizedImage () -> CGRect {
        if (!image) {
            return CGRectZero
        }
        
        var rect : CGRect = CGRectZero
        switch contentMode {
        case UIViewContentMode.ScaleAspectFit :
            let imageRatio = image.size.width / image.size.height
            let viewRatio = bounds.size.width / bounds.size.height
            
            if (imageRatio < viewRatio) {
                let scale = bounds.size.height / image.size.height
                let width = scale * image.size.width
                let offset = 0.5 * (bounds.size.width - width)
                rect = CGRect(x: offset, y: 0, width: width, height: bounds.size.height)
            }
            else {
                let scale = bounds.size.width / image.size.width
                let height = scale * image.size.height
                let offset = 0.5 * (bounds.size.height - height)
                rect = CGRect(x: 0, y: offset, width: bounds.size.width, height: height)
            }
        default :
            println("Content Mode unsupported")
        }
        return rect
    }
}

