//
//  FaceDetector.swift
//  FacePasteSwift
//
//  Created by Jack Wu on 2014-06-05.
//  Copyright (c) 2014 Jack Wu. All rights reserved.
//

import UIKit

protocol FaceDetectorDelegate : NSObjectProtocol {
    func faceDetectorDidFinishDetecingWith(image:UIImage, faces:Array<Face>)
}

class FaceDetector: NSObject {
    class var sharedDetector:FaceDetector {
        get {
            struct Static {
                static var instance : FaceDetector? = nil
                static var token : dispatch_once_t = 0
            }
            
            dispatch_once(&Static.token) {
                Static.instance = FaceDetector()
            }
            
            return Static.instance!
        }
    }
    
    var delegate : FaceDetectorDelegate? = nil
    
    @lazy var detector : CIDetector = {
        let instance = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: [CIDetectorAccuracy:CIDetectorAccuracyHigh])
        return instance;
    }()
    
    func detectFacesInImage(anImage:UIImage!) {
        let ciImage : CIImage = CIImage(image: anImage)
        let features : Array = self.detector.featuresInImage(ciImage)
        var faces : Array<Face> = Array()
        
        for f : CIFaceFeature in features as Array<CIFaceFeature> {
            let face : Face = Face(newBounds: f.bounds)
            faces.append(face)
        }
        
        delegate?.faceDetectorDidFinishDetecingWith(anImage, faces: faces)
    }
}
