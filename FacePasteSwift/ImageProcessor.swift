//
//  ImageProcessor.swift
//  FacePasteSwift
//
//  Created by Jack Wu on 2014-06-05.
//  Copyright (c) 2014 Jack Wu. All rights reserved.
//

import UIKit

protocol ImageProcessorDelegate {
    func imageProcessorFinishedProcessingImage(image : UIImage)
}

class ImageProcessor: NSObject {
    class var sharedDetector:ImageProcessor {
        get {
            struct Static {
                static var instance : ImageProcessor? = nil
                static var token : dispatch_once_t = 0
            }
            
            dispatch_once(&Static.token) {
                Static.instance = ImageProcessor()
            }
            
            return Static.instance!
        }
    }
    
    var delegate : ImageProcessorDelegate?
    
    func replaceFacesInImage(image:UIImage, face:Face, faces:Array<Face>) {
        var faceImage : UIImage
        
        if !face.image {
            let scale = image.scale > 1.0 ? image.scale : 1.0
            let scaledRect = CGRectMake(face.bounds.origin.x * scale, face.bounds.origin.y * scale, face.bounds.size.width * scale, face.bounds.size.height * scale)
            let imageRef : CGImageRef = CGImageCreateWithImageInRect(image.CGImage, scaledRect)
            face.image = UIImage(CGImage: imageRef)
            CGImageRelease(imageRef)
        }
        faceImage = face.image!
       
        let faceCIImage = CIImage(image:faceImage)
        
        let sourceRect = CGRectMake(0, 0, face.bounds.size.width, face.bounds.size.height)
        let center = CIVector(x: CGRectGetMidX(sourceRect), y: CGRectGetMidY(sourceRect))
        let radius0 = sourceRect.size.width * 0.7 * 0.5
        let radius1 = sourceRect.size.width * 0.5
        
        radialGradient.setValue(center, forKey: kCIInputCenterKey)
        radialGradient.setValue(radius0, forKey: "inputRadius0")
        radialGradient.setValue(radius1, forKey: "inputRadius1")
        radialGradient.setValue(CIColor(color: UIColor.whiteColor()), forKey: "inputColor0")
        radialGradient.setValue(CIColor(color: UIColor.clearColor()), forKey: "inputColor1")
        
        let circle = radialGradient.valueForKey(kCIOutputImageKey) as CIImage
        
        multiplyFilter.setValue(circle, forKey: kCIInputBackgroundImageKey)
        multiplyFilter.setValue(faceCIImage, forKey: kCIInputImageKey)
        
        let fadedFace = multiplyFilter.valueForKey(kCIOutputImageKey) as CIImage
        var workingCIImage = CIImage(image:image)
        
        var transform = CGAffineTransformMakeScale(1, -1)
        transform = CGAffineTransformTranslate(transform, 0, -image.size.height)
        for f : Face in faces {
            if f.bounds == face.bounds {
                continue
            }
            let destinationRect = CGRectApplyAffineTransform(f.bounds, transform)
            scaleFilter.setValue(fadedFace, forKey: kCIInputImageKey)
            scaleFilter.setValue(destinationRect.size.width / sourceRect.size.width, forKey: kCIInputScaleKey)
            
            let scaledFace = scaleFilter.valueForKey(kCIOutputImageKey) as CIImage
            let translatedScaledFace = scaledFace.imageByApplyingTransform(CGAffineTransformMakeTranslation(destinationRect.origin.x,destinationRect.origin.y))
            
            sourceOverFilter.setValue(workingCIImage, forKey: kCIInputBackgroundImageKey)
            sourceOverFilter.setValue(translatedScaledFace, forKey: kCIInputImageKey)
            workingCIImage = sourceOverFilter.valueForKey(kCIOutputImageKey) as CIImage
        }
        let processedImage = UIImage(CIImage:workingCIImage)
        
        self.delegate?.imageProcessorFinishedProcessingImage(processedImage)
    }
    
    @lazy var multiplyFilter : CIFilter = {
        let filter = CIFilter(name: "CIMultiplyCompositing")
        filter.setDefaults()
        return filter
    }()
    
    @lazy var sourceOverFilter : CIFilter = {
        let filter = CIFilter(name: "CISourceOverCompositing")
        filter.setDefaults()
        return filter
    }()
    
    @lazy var scaleFilter : CIFilter = {
        let filter = CIFilter(name: "CILanczosScaleTransform")
        filter.setDefaults()
        return filter
    }()
    @lazy var radialGradient : CIFilter = {
        let filter = CIFilter(name: "CIRadialGradient")
        filter.setDefaults()
        return filter
    }()
}
