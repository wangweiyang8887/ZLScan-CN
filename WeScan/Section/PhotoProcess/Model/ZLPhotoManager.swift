//
//  ZLPhotoManager.swift
//  WeScan
//
//  Created by apple on 2018/12/3.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import UIKit

class ZLPhotoManager {
    
    class func getNowTimeStampMoreBit() -> String {
        let time = Date.init()
        let nowStamp = time.timeIntervalSince1970 * 1000
        return String(format: "%.lf", nowStamp)
    }

    
    /// save model image
    ///
    /// - Parameters:
    ///   - originalImage: originalImage
    ///   - scannedImage: scannedImage
    ///   - enhancedImage: enhancedImage
    ///   - handle: call back with path
    class func saveImage(_ originalImage: UIImage, _ scannedImage: UIImage, _ enhancedImage: UIImage, handle:@escaping ((_ oriPath: String?, _ scanPath: String?, _ enhanPath: String?)->())) {
        
        var tempOriPath: String?
        var tempScanPath: String?
        var tempEnhanPath: String?
        
        let queue = DispatchQueue(label: "ZLPhotoSaveTheLocalQueue")
        let group = DispatchGroup()
        
        queue.async(group: group) {
            group.enter()
            ZLPhotoManager.saveImage(originalImage, handle: { (oriPath) in
                tempOriPath = oriPath
                group.leave()
                
            })
        }
        
        queue.async(group: group) {
            group.enter()
            ZLPhotoManager.saveImage(scannedImage, handle: { (scanPath) in
                tempScanPath = scanPath
                group.leave()
            })
        }
        
        queue.async(group: group) {
            group.enter()
            ZLPhotoManager.saveImage(enhancedImage, handle: { (enhanPath) in
                tempEnhanPath = enhanPath
                group.leave()
            })
        }
        
        group.notify(queue: queue) {
            DispatchQueue.main.async {
                handle(tempOriPath,tempScanPath,tempEnhanPath)
            }
        }
    }
    
    /// save image with path
    ///
    /// - Parameters:
    ///   - image: image
    ///   - filePath: path
    ///   - handle: call back
    class func saveImage(_ image: UIImage, filePath: String = kZLScanPhotoFileDataPath, handle:@escaping ((_ fileName: String?)->())) {
        DispatchQueue.global().async {
            if let data = image.jpegData(compressionQuality: 0.1) {
                let timeStr = getNowTimeStampMoreBit() + "\(Int(arc4random()%100000)+1)"
                let docuPath = kZLScanPhotoFileDataPath
                let manager = FileManager.default
                if !manager.fileExists(atPath: filePath) {
                    do {
                        try manager.createDirectory(atPath: docuPath, withIntermediateDirectories: true, attributes: nil)
                    } catch let error {
                        print("creat directory failed \(error.localizedDescription)")
                        DispatchQueue.main.async {
                            handle(nil)
                        }
                    }
                }
                let imagefilePath = docuPath + "/\(timeStr).png"
                let fileUrl = URL(fileURLWithPath: imagefilePath)
                do {
                    try data.write(to: fileUrl)
                    DispatchQueue.main.async {
                        handle("\(timeStr).png")
                    }
                } catch let error {
                    print("save image failed \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        handle(nil)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    handle(nil)
                }

            }
        }
    }
    
    
    /// remove local photo
    ///
    /// - Parameters:
    ///   - model: photo model
    ///   - handle: callBack
    class func removeImage(_ model: ZLPhotoModel, handle:((_ isSuccess: Bool)->())) {
        
        let originalPath = kZLScanPhotoFileDataPath + "/\(model.originalImagePath)"
        let scannedPath = kZLScanPhotoFileDataPath + "/\(model.scannedImagePath)"
        let enhancedPath = kZLScanPhotoFileDataPath + "/\(model.enhancedImagePath)"
        ZLPhotoManager.removefile(originalPath) { (isSuccess) in
            if isSuccess {
                ZLPhotoManager.removefile(scannedPath, handle: { (isSuccess) in
                    if isSuccess {
                        ZLPhotoManager.removefile(enhancedPath, handle: { (isSuccess) in
                            if isSuccess {
                                print("remove image model success")
                                handle(true)
                            } else {
                                handle(false)
                            }
                        })
                    } else {
                        handle(false)
                    }
                })
            } else {
                handle(false)
            }
        }
    }
    
    
    class func removefile(_ path: String, handle:((_ isSuccess: Bool)->())) {
        let manager = FileManager.default
        if manager.fileExists(atPath: path) {
            do {
                try manager.removeItem(atPath: path)
                handle(true)
            } catch let error {
                print("remove image failed \(error.localizedDescription)")
                handle(true)
            }
        } else {
            handle(false)
        }
    }
    
    
    /// remove all photo data
    ///
    /// - Parameter handle: callBack
    class func removeAllImage(handle:((_ isSuccess: Bool)->())) {
        let manager = FileManager.default
        if manager.fileExists(atPath: kZLScanPhotoFileDataPath) {
            do {
                try manager.removeItem(atPath: kZLScanPhotoFileDataPath)
                handle(true)
            } catch let error {
                print("remove all image failed \(error.localizedDescription)")
                handle(false)
            }
        } else {
            handle(false)
        }
    }

    class func getRectDict(_ model: ZLQuadrilateral) -> [String:[String:Double]] {
        let rectDict: [String: [String: Double]] = ["topLeft":["x":Double(model.topLeft.x),"y":Double(model.topLeft.y)],
                                       "topRight":["x":Double(model.topRight.x),"y":Double(model.topRight.y)],
                                       "bottomRight":["x":Double(model.bottomRight.x),"y":Double(model.bottomRight.y)],
                                       "bottomLeft":["x":Double(model.bottomLeft.x),"y":Double(model.bottomLeft.y)]]
        return rectDict
    }
}

