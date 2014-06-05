//
//  ViewController.swift
//  FacePasteSwift
//
//  Created by Jack Wu on 2014-06-05.
//  Copyright (c) 2014 Jack Wu. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, FaceDetectorDelegate {
                            
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
        workingImage = info[UIImagePickerControllerOriginalImage] as UIImage
        imageView.image = workingImage
        
        let detector = FaceDetector.sharedDetector
        detector.delegate = self
        detector.detectFacesInImage(workingImage);
    }
    
    func faceDetectorDidFinishDetecingWith(image: UIImage, faces: Array<Face>)  {
        println("Found \(faces.count) faces")
        imageView.image = image;
    }
}

