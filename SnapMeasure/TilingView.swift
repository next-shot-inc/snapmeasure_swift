//
//  TilingView.swift
//  SnapMeasure
//
//  Created by next-shot on 11/30/15.
//  Copyright © 2015 next-shot. All rights reserved.
//

import Foundation
import UIKit

class TilingView : UIView {
    var name_ : String
    var size_ : CGSize
    
    init(name: String, size: CGSize) {
        name_ = name
        size_ = size
        
        super.init(frame: CGRectMake(0,0, size.width, size.height))
        let tiledLayer = self.layer as? CATiledLayer
        tiledLayer!.levelsOfDetail = 1
        tiledLayer!.tileSize = CGSize(width: 1024,height: 1024)
    }
    
    override class func layerClass() -> AnyClass {
       return CATiledLayer.self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // to handle the interaction between CATiledLayer and high resolution screens, we need to
    // always keep the tiling view's contentScaleFactor at 1.0. UIKit will try to set it back
    // to 2.0 on retina displays, which is the right call in most cases, but since we're backed
    // by a CATiledLayer it will actually cause us to load the wrong sized tiles.
    //
    override var contentScaleFactor : CGFloat {
        set {
            super.contentScaleFactor = 1.0;
        }
        get {
            return super.contentScaleFactor
        }
    }
    
    override func drawRect(rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        
        // get the scale from the context by getting the current transform matrix, then asking
        // for its "a" component, which is one of the two scale components. We could also ask
        // for "d". This assumes (safely) that the view is being scaled equally in both dimensions.
        let scale = CGContextGetCTM(context).a
        
        let tiledLayer = self.layer as? CATiledLayer
        var tileSize = tiledLayer!.tileSize
        
        // Even at scales lower than 100%, we are drawing into a rect in the coordinate system
        // of the full image. One tile at 50% covers the width (in original image coordinates)
        // of two tiles at 100%. So at 50% we need to stretch our tiles to double the width
        // and height; at 25% we need to stretch them to quadruple the width and height; and so on.
        // (Note that this means that we are drawing very blurry images as the scale gets low.
        // At 12.5%, our lowest scale, we are stretching about 6 small tiles to fill the entire
        // original image area. But this is okay, because the big blurry image we're drawing
        // here will be scaled way down before it is displayed.)
        tileSize.width /= scale;
        tileSize.height /= scale;
        
        // calculate the rows and columns of tiles that intersect the rect we have been asked to draw
        let firstCol : Int = Int(floorf(Float(CGRectGetMinX(rect) / tileSize.width)));
        let lastCol : Int = Int(floorf(Float((CGRectGetMaxX(rect)-1) / tileSize.width)));
        let firstRow : Int = Int(floorf(Float(CGRectGetMinY(rect) / tileSize.height)));
        let lastRow : Int = Int(floorf(Float((CGRectGetMaxY(rect)-1) / tileSize.height)));
        
        for row in firstRow ... lastRow {
            for col in firstCol ... lastCol {
                
                let tile = tileForScale(scale, row:row, col:col)
                
                var tileRect = CGRectMake(
                    tileSize.width * CGFloat(col),tileSize.height * CGFloat(row),
                    tileSize.width, tileSize.height
                )
                
                // if the tile would stick outside of our bounds, we need to truncate it so as
                // to avoid stretching out the partial tiles at the right and bottom edges
                tileRect = CGRectIntersection(self.bounds, tileRect);
                
                if( tile == nil ) {
                    annotateRect(tileRect, ctx: context!)
                } else {
                    tile!.drawInRect(tileRect)
                }
            }
        }
    }
    
    func tileForScale(scale: CGFloat, row: Int, col: Int) -> UIImage? {
        // we use "imageWithContentsOfFile:" instead of "imageNamed:" here because we don't
        // want UIImage to cache our tiles
        //
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let tileName = NSString(format: "%@_%d_%d", name_, col, row)
        let tileUrl = appDelegate.applicationDocumentsDirectory.URLByAppendingPathComponent(
            tileName as String
        )
        if( tileUrl.path != nil ) {
           let tileImage = UIImage(contentsOfFile: tileUrl.path!)
           if( tileImage != nil ) {
               return tileImage
           }
        }
        
        let url = appDelegate.applicationDocumentsDirectory.URLByAppendingPathComponent(
            name_
        )
        let fullImage = UIImage(contentsOfFile: url.path!)
        if( fullImage == nil ) {
            return nil
        }
        let rawImage = normalizedImage(fullImage!)
        let imageArea = CGRectMake(
            CGFloat(col*1024), CGFloat(row*1024),
            min(CGFloat(col+1)*1024-1,size_.width-1) - CGFloat(col*1024),
            min(CGFloat(row+1)*1024-1,size_.height-1) - CGFloat(row*1024)
        )
        let subImage = CGImageCreateWithImageInRect(rawImage.CGImage, imageArea)
        if( subImage != nil ) {
            return UIImage(CGImage: subImage!)
        } else {
            return nil
        }
    }
    
    func normalizedImage(image : UIImage) -> UIImage {
        if (image.imageOrientation == UIImageOrientation.Up) {
            return image;
        }
    
       UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale);
       image.drawInRect(CGRectMake(0, 0, image.size.width, image.size.height))
       let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
       UIGraphicsEndImageContext();
       return normalizedImage
    }
    
    func annotateRect(rect: CGRect, ctx: CGContextRef) {
        let scale = CGContextGetCTM(ctx).a
        let line_width = 2.0/scale
        let font_size = 16.0/scale
        UIColor.whiteColor().set()
        NSString(format: "%0.0f", log2(scale)).drawAtPoint(
            CGPointMake(CGRectGetMinX(rect), CGRectGetMinY(rect)),
            withAttributes: [NSFontAttributeName: UIFont.boldSystemFontOfSize(font_size)]
        )
        UIColor.redColor().set()
        CGContextSetLineWidth(ctx, line_width)
        CGContextStrokeRect(ctx, rect)
    }
}
