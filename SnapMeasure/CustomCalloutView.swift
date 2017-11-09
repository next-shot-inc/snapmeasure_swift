//
//  CustomCalloutView.swift
//  SnapMeasure
//
//  Created by Camille Dulac on 6/12/15.
//  Copyright (c) 2015 next-shot. All rights reserved.
//

//TODO: Fix callout moving the map when too high so that the whole callout is displayed
import Foundation
import UIKit
import QuartzCore

enum CalloutAnimation : Int {
    case bounce = 0, fade = 1
}

enum CalloutArrowDirection : Int {
    case down = 0, up = 1, any = 2
}

let CALLOUT_DEFAULT_CONTAINER_HEIGHT : CGFloat = 44 // height of just the main portion without arrow
let CALLOUT_SUB_DEFAULT_CONTAINER_HEIGHT : CGFloat = 52 // height of just the main portion without arrow (when subtitle is present)
let CALLOUT_MIN_WIDTH : CGFloat = 61 // minimum width of system callout
let TITLE_HMARGIN : CGFloat = 12 // the title/subtitle view's normal horizontal margin from the edges of our callout view or from the accessories
let TITLE_TOP : CGFloat = 11 // the top of the title view when no subtitle is present
let TITLE_SUB_TOP : CGFloat = 4 // the top of the title view when a subtitle IS present
let TITLE_HEIGHT : CGFloat = 21 // title height, 
let SUBTITLE_TOP : CGFloat = 28
let SUBTITLE_HEIGHT : CGFloat = 15 // subtitle height, fixed
let BETWEEN_ACCESSORIES_MARGIN : CGFloat = 7 // margin between accessories when no title/subtitle is present
let TOP_ANCHOR_MARGIN : CGFloat = 13 // all the above measurements assume a bottom anchor! if we're pointing "up" we'll need to add this top margin to everything.
let COMFORTABLE_MARGIN : CGFloat = 10 // when we try to reposition content to be visible, we'll consider this margin around your target rect



@objc protocol CustomCalloutViewDelegate : NSObjectProtocol{
    @objc optional func calloutViewClicked(_ calloutView: CustomCalloutView)
    
    @objc optional func calloutView(_ calloutView: CustomCalloutView, delayForRepositionWithSize offset: CGSize) -> TimeInterval
    
    @objc optional func calloutViewWillAppear(_ calloutView : CustomCalloutView)
    @objc optional func calloutViewDidAppear(_ calloutView : CustomCalloutView)
    @objc optional func calloutViewWillDisappear(_ calloutView : CustomCalloutView)
    @objc optional func calloutViewDidDisappear(_ calloutView : CustomCalloutView)

}

class CustomCalloutView: UIView, CAAnimationDelegate {
    var delegate : CustomCalloutViewDelegate?
    var permittedArrowDirection: CalloutArrowDirection
    var currentArrowDirection: CalloutArrowDirection?
    var constrainedInsets : UIEdgeInsets?
    var backgroundView : CalloutBackgroundView?
    
    var title, subtitle : NSString?
    var titleView, subtitleView : UIView?
    var contentView : UIView?
    var contentViewInset : UIEdgeInsets
    
    var calloutOffset : CGPoint
    
    var presentAnimation, dismissAnimation : CalloutAnimation
    
    var containerView : UIButton // for masking and interaction
    var titleLabel, subtitleLabel : UILabel?
    var popupCancelled : Bool?

    override init(frame: CGRect) {
        self.permittedArrowDirection = CalloutArrowDirection.down;
        self.presentAnimation = CalloutAnimation.bounce;
        self.dismissAnimation = CalloutAnimation.fade;
        self.containerView = UIButton()
        self.containerView.isAccessibilityElement = false;
        self.contentViewInset = UIEdgeInsetsMake(12, 12, 12, 12);
        self.calloutOffset = CGPoint(x: 0, y: 0)
        
        //[self.containerView addTarget:self action:@selector(highlightIfNecessary) forControlEvents:UIControlEventTouchDown | UIControlEventTouchDragInside];
        //[self.containerView addTarget:self action:@selector(unhighlightIfNecessary) forControlEvents:UIControlEventTouchDragOutside | UIControlEventTouchCancel | UIControlEventTouchUpOutside | UIControlEventTouchUpInside];
        
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.clear
        self.isAccessibilityElement = false;
        self.containerView.addTarget(self, action: #selector(CustomCalloutView.calloutClicked(_:)) ,for: UIControlEvents.touchUpInside)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func calloutClicked(_ sender: UIButton) {
        if (self.delegate != nil) {
            if (self.delegate!.responds(to: #selector(CustomCalloutViewDelegate.calloutViewClicked(_:)))) {
                self.delegate!.calloutViewClicked!(self)
            }
        }
    }
    
    func subtitleViewOrDefault() -> UIView {
        if (self.subtitleView != nil) {
            return self.subtitleView!
        } else {
            if (subtitleLabel != nil) {
                return subtitleLabel!
            } else {
                self.subtitleLabel = UILabel();
                self.subtitleLabel!.setFrameHeight(SUBTITLE_HEIGHT)
                self.subtitleLabel!.isOpaque = false
                self.subtitleLabel!.backgroundColor = UIColor.clear
                self.subtitleLabel!.font = UIFont.systemFont(ofSize: 12)
                self.subtitleLabel!.textColor = UIColor.black
                
                return subtitleLabel!
            }
        }
    }
    
    func titleViewOrDefault() -> UIView {
        if (self.titleView != nil) {
            return self.titleView!
        } else {
            if (titleLabel != nil) {
                return titleLabel!
            } else {
                self.titleLabel = UILabel();
                self.titleLabel!.setFrameHeight(TITLE_HEIGHT)
                self.titleLabel!.isOpaque = false
                self.titleLabel!.backgroundColor = UIColor.clear
                self.titleLabel!.font = UIFont.systemFont(ofSize: 17)
                self.titleLabel!.textColor = UIColor.black
                
                return titleLabel!
            }
        }
    }
    
    func getbackgroundView() -> CalloutBackgroundView {
        if (self.backgroundView != nil) {
            return self.backgroundView!
        } else {
            self.backgroundView = self.defaultBackgroundView()
            return self.backgroundView!
        }
    }
    
    func defaultBackgroundView() -> CalloutBackgroundView {
        return CalloutBackgroundView()
    }
    
    func rebuildSubviews () {
        // remove and re-add our appropriate subviews in the appropriate order
        for sub in self.subviews {
            sub.removeFromSuperview()
        }
        for sub in containerView.subviews {
            sub.removeFromSuperview()
        }
        self.setNeedsDisplay()
        layoutSubviews()

        self.addSubview(self.getbackgroundView())
        self.addSubview(self.containerView)
        
        if (self.contentView != nil) {
            self.containerView.addSubview(self.contentView!)
        }
        self.containerView.addSubview(self.titleViewOrDefault())
        self.containerView.addSubview(self.subtitleViewOrDefault())

    }
    
    var innerContentMarginLeft : CGFloat {
        return self.contentViewInset.left
    }
    
    var innerContentMarginRight : CGFloat {
        return self.contentViewInset.right
    }
    
    var calloutHeight : CGFloat {
        return self.calloutContainerHeight + self.getbackgroundView().anchorHeight
    }
    
    var calloutContainerHeight : CGFloat {
        var height : CGFloat = 0.0
        if (self.contentView != nil) {
            height += self.contentView!.frameHeight + self.contentViewInset.bottom + self.contentViewInset.top;
        }
        if (self.subtitleView != nil || (self.subtitle != nil && self.subtitle!.length > 0) ) {
            height +=  SUBTITLE_HEIGHT
        }
        if (self.titleView != nil || (self.subtitle != nil && self.subtitle!.length > 0) ) {
            height += TITLE_HEIGHT
        }
        return height
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        // calculate how much non-negotiable space we need to reserve for margin and accessories
        let margin : CGFloat = self.innerContentMarginLeft + self.innerContentMarginRight;
        
        // how much room is left for text?
        var availableWidthForText = size.width - margin - 1;
        
        // no room for text? then we'll have to squeeze into the given size somehow.
        if (availableWidthForText < 0) {
            availableWidthForText = 0;
        }
        
        let preferredTitleSize : CGSize = self.titleViewOrDefault().sizeThatFits(CGSize(width: availableWidthForText, height: TITLE_HEIGHT))
        let preferredSubtitleSize : CGSize = self.subtitleViewOrDefault().sizeThatFits(CGSize(width: availableWidthForText, height: SUBTITLE_HEIGHT))
        
        // total width we'd like
        var preferredWidth : CGFloat
        var contentWidth : CGFloat
        var textWidth : CGFloat
        
        if (self.contentView != nil) {
            // if we have a content view, then take our preferred size directly from that
            contentWidth = self.contentView!.frameWidth + margin;
        } else {
            contentWidth = 0
        }
        if (preferredTitleSize.width >= 0.000001 || preferredSubtitleSize.width >= 0.000001) {
            // if we have a title or subtitle, then our assumed margins are valid, and we can apply them
            textWidth = max(preferredTitleSize.width, preferredSubtitleSize.width) + margin;
        } else {
            textWidth = 0
        }
        
        if (textWidth == 0 && contentWidth == 0) {
            // ok we have no title, subtitle, or content to speak of. In this case, the system callout would actually not display
            // at all! But we can handle it.
            preferredWidth = BETWEEN_ACCESSORIES_MARGIN;
        } else {
            preferredWidth = max(contentWidth, textWidth)
        }
        
        // ensure we're big enough to fit our graphics!
        preferredWidth = max(preferredWidth, CALLOUT_MIN_WIDTH);
        
        // ask to be smaller if we have space, otherwise we'll fit into what we have by truncating the title/subtitle.
        return CGSize(width: min(preferredWidth, size.width), height: self.calloutHeight);

    }
    
    func offsetToContainRect(_ innerRect: CGRect, inRect outerRect: CGRect) -> CGSize {
        let nudgeRight = max(0, outerRect.minX - innerRect.minX);
        let nudgeLeft = min(0, outerRect.maxX - innerRect.maxX);
        let nudgeTop = max(0, outerRect.minY - innerRect.minY);
        let nudgeBottom = min(0, outerRect.maxY - innerRect.maxY);
        
        var returnX : CGFloat
        if (nudgeLeft > 0) {
            returnX = nudgeLeft
        } else {
            returnX = nudgeRight
        }
        var returnY : CGFloat
        if nudgeTop > 0 {
            returnY = nudgeTop
        } else {
            returnY = nudgeBottom
        }
        return CGSize(width: returnX, height: returnY)
    }
    
    // Presents a callout view by adding it to "inView" and pointing at the given rect of inView's bounds.
    // Constrains the callout to the bounds of the given view. Optionally scrolls the given rect into view (plus margins)
    // if -delegate is set and responds to -delayForRepositionWithSize.
    func presentCalloutFromRect(_ rect: CGRect, inView view: UIView, constrainedToView constrainedView: UIView, animated: Bool) {
        self.presentCalloutFromRect(rect, inLayer: view.layer, ofView: view, constrainedToLayer: constrainedView.layer, animated: animated)
    }
    
    fileprivate func presentCalloutFromRect(_ rect: CGRect, inLayer layer: CALayer, ofView view: UIView, constrainedToLayer constrainedLayer: CALayer, animated: Bool) {
        
        // Sanity check: dismiss this callout immediately if it's displayed somewhere
        if (self.layer.superlayer != nil) {
            //TODO: implement following
            //self.dismissCalloutAnimated(false)
        }
        
        // cancel any presenting animation that may be in progress
        self.layer.removeAnimation(forKey: "present")
        
        // figure out the constrained view's rect in our popup view's coordinate system
        var constrainedRect : CGRect = constrainedLayer.convert(constrainedLayer.bounds, to:layer)
        
        // apply our edge constraints
        if (self.constrainedInsets != nil) {
            constrainedRect = UIEdgeInsetsInsetRect(constrainedRect, self.constrainedInsets!)
        }
        
        constrainedRect = constrainedRect.insetBy(dx: COMFORTABLE_MARGIN, dy: COMFORTABLE_MARGIN);
        
        // form our subviews based on our content set so far
        self.rebuildSubviews()
        
        // apply title/subtitle (if present
        if (self.titleLabel != nil && self.title != nil) {
            self.titleLabel!.text = self.title! as String;
        }
        if (self.subtitleLabel != nil && self.subtitle != nil) {
            self.subtitleLabel!.text = self.subtitle! as String
        }
        
        // size the callout to fit the width constraint as best as possible
        self.setFrameSize(self.sizeThatFits(CGSize(width: constrainedRect.size.width, height: self.calloutHeight)))
        
        // how much room do we have in the constraint box, both above and below our target rect?
        let topSpace = rect.minY - constrainedRect.minY;
        let bottomSpace = constrainedRect.maxY - rect.maxY;
        
        // we prefer to point our arrow down.
        var bestDirection = CalloutArrowDirection.down;
        
        // we'll point it up though if that's the only option you gave us.
        if (self.permittedArrowDirection == CalloutArrowDirection.up) {
            bestDirection = CalloutArrowDirection.up;
        }
        
        // or, if we don't have enough space on the top and have more space on the bottom, and you
        // gave us a choice, then pointing up is the better option.
        if (self.permittedArrowDirection == CalloutArrowDirection.any && topSpace < self.calloutHeight && bottomSpace > topSpace) {
            bestDirection = CalloutArrowDirection.up;
        }
        
        self.currentArrowDirection = bestDirection;
        
        // we want to point directly at the horizontal center of the given rect. calculate our "anchor point" in terms of our
        // target view's coordinate system. make sure to offset the anchor point as requested if necessary.
        let anchorX = self.calloutOffset.x + rect.midX;
        let anchorY : CGFloat
        if (bestDirection == CalloutArrowDirection.down) {
            anchorY = self.calloutOffset.y + rect.minY
        } else {
            anchorY = self.calloutOffset.y + rect.maxY
        }
        
        // we prefer to sit centered directly above our anchor
        var calloutX = round(anchorX - self.frameWidth / 2);
        
        // but not if it's going to get too close to the edge of our constraints
        if (calloutX < constrainedRect.origin.x) {
            calloutX = constrainedRect.origin.x;
        }
        
        if (calloutX > constrainedRect.origin.x+constrainedRect.size.width-self.frameWidth) {
            calloutX = constrainedRect.origin.x+constrainedRect.size.width-self.frameWidth;
        }
        
        // what's the farthest to the left and right that we could point to, given our background image constraints?
        let minPointX = calloutX + self.backgroundView!.anchorMargin;
        let maxPointX = calloutX + self.frameWidth - self.backgroundView!.anchorMargin;
        
        // we may need to scoot over to the left or right to point at the correct spot
        var adjustX : CGFloat = 0;
        if (anchorX < minPointX)  {
            adjustX = anchorX - minPointX;
        }
        if (anchorX > maxPointX) {
            adjustX = anchorX - maxPointX;
        }
        
        // add the callout to the given view
        view.addSubview(self)
        
        var calloutOrigin = CGPoint()
        calloutOrigin.x = calloutX + adjustX
        if (bestDirection == CalloutArrowDirection.down) {
            calloutOrigin.y = anchorY - self.calloutHeight
        } else {
            calloutOrigin.y = anchorY
        }
        
        self.setFrameOrigin(calloutOrigin)
        
        // now set the *actual* anchor point for our layer so that our "popup" animation starts from this point.
        var anchorPoint = layer.convert(CGPoint(x: anchorX, y: anchorY), to:self.layer)
        
        // pass on the anchor point to our background view so it knows where to draw the arrow
        self.backgroundView!.arrowPoint = anchorPoint;
        
        // adjust it to unit coordinates for the actual layer.anchorPoint property
        anchorPoint.x /= self.frameWidth;
        anchorPoint.y /= self.frameHeight;
        self.layer.anchorPoint = anchorPoint;
        
        // setting the anchor point moves the view a bit, so we need to reset
        self.setFrameOrigin(calloutOrigin)
        
        // make sure our frame is not on half-pixels or else we may be blurry!
        let scale = UIScreen.main.scale;
        self.setFrameX(floor(self.frameX*scale)/scale)
        self.setFrameY(floor(self.frameY*scale)/scale)
        
        // layout now so we can immediately start animating to the final position if needed
        self.setNeedsLayout()
        self.layoutIfNeeded()
        
        // if we're outside the bounds of our constraint rect, we'll give our delegate an opportunity to shift us into position.
        // consider both our size and the size of our target rect (which we'll assume to be the size of the content you want to scroll into view.
        let contentRect = self.frame.union(rect);
        let offset = self.offsetToContainRect(contentRect, inRect:constrainedRect)
        
        var delay: TimeInterval = 0;
        self.popupCancelled = false // reset this before calling our delegate below
        
        if (self.delegate!.responds(to: #selector(CustomCalloutViewDelegate.calloutView(_:delayForRepositionWithSize:))) && !offset.equalTo(CGSize.zero)) {
            delay = self.delegate!.calloutView!(self, delayForRepositionWithSize:offset)
        }
        
        // there's a chance that user code in the delegate method may have called -dismissCalloutAnimated to cancel things; if that
        // happened then we need to bail!
        //TODO: get this to work no internet now :(
        //if (self.popupCancelled) return;
        
        // now we want to mask our contents to our background view (if requested) to match the iOS 7 style
        self.containerView.layer.mask = self.backgroundView!.contentMask;
        
        // if we need to delay, we don't want to be visible while we're delaying, so hide us in preparation for our popup
        self.isHidden = true;
        
        // create the appropriate animation, even if we're not animated
        let animation = self.animationWithType(self.presentAnimation, presenting:true)
        
        // nuke the duration if no animation requested - we'll still need to "run" the animation to get delays and callbacks
        if (!animated) {
            animation.duration = 0.0000001; // can't be zero or the animation won't "run"
        }
        
        animation.beginTime = CACurrentMediaTime() + delay;
        animation.delegate = self;
        
        self.layer.add(animation, forKey:"present")
    }
    
    
    func animationDidStart(_ anim : CAAnimation) {
        let presenting : Bool = (anim.value(forKey: "presenting")! as AnyObject).boolValue
    
        if (presenting) {
            if (self.delegate!.responds(to: #selector(CustomCalloutViewDelegate.calloutViewWillAppear(_:)))) {
                self.delegate!.calloutViewWillAppear!(self)
            }
    
            // ok, animation is on, let's make ourselves visible!
            self.isHidden = false;
        }
        else if (!presenting) {
            if (self.delegate!.responds(to: #selector(CustomCalloutViewDelegate.calloutViewWillDisappear(_:)))) {
                self.delegate!.calloutViewWillDisappear!(self)
            }
        }
    }
    
    func animationDidStop(_ anim : CAAnimation, finished: Bool) {
        let presenting : Bool = (anim.value(forKey: "presenting")! as AnyObject).boolValue
    
        if (presenting && finished) {
            if (self.delegate!.responds(to: #selector(CustomCalloutViewDelegate.calloutViewDidAppear(_:)))) {
                self.delegate!.calloutViewDidAppear!(self)
            }
        } else if (!presenting && finished) {
            self.removeFromParent()
            self.layer.removeAnimation(forKey: "dismiss")
    
            if (self.delegate!.responds(to: #selector(CustomCalloutViewDelegate.calloutViewDidDisappear(_:)))) {
                self.delegate!.calloutViewDidDisappear!(self)
            }
        }
    }
    
    func dismissCalloutAnimated(_ animated: Bool) {
    
        // cancel all animations that may be in progress
        self.layer.removeAnimation(forKey: "present")
        self.layer.removeAnimation(forKey: "dismiss")
    
        self.popupCancelled = true;
    
        if (animated) {
            let animation = self.animationWithType(self.dismissAnimation, presenting: false)
            animation.delegate = self;
            self.layer.add(animation, forKey: "dismiss")
        }
        else {
            self.removeFromParent()
        }
    }

    
    func removeFromParent() {
        if (self.superview != nil) {
            self.removeFromSuperview()
        } else {
            // removing a layer from a superlayer causes an implicit fade-out animation that we wish to disable.
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            self.layer.removeFromSuperlayer()
            CATransaction.commit()
        }
    }
    
    func animationWithType(_ type : CalloutAnimation, presenting:Bool) -> CAAnimation {
        var animation : CAAnimation
    
        if (type == CalloutAnimation.bounce) {
    
            let fade = CABasicAnimation(keyPath: "opacity")
            fade.duration = 0.23;
            if (presenting) {
                fade.fromValue = 0
                fade.toValue = 1
            } else {
                fade.fromValue = 1
                fade.toValue = 0
            }
            fade.timingFunction = CAMediaTimingFunction(name:kCAMediaTimingFunctionEaseInEaseOut)
    
            let bounce = CABasicAnimation(keyPath: "transform.scale")
            bounce.duration = 0.23;
            if (presenting) {
                bounce.fromValue = 0.7
                bounce.toValue = 1.0
            } else {
                bounce.fromValue = 1.0
                bounce.toValue = 0.7
            }
            bounce.timingFunction = CAMediaTimingFunction(controlPoints: 0.59367, 0.12066, 0.18878, 1.5814)
    
            let group = CAAnimationGroup()
            group.animations = [fade, bounce];
            group.duration = 0.23;
    
            animation = group;
        }
        else  { //if (type == CalloutAnimation.Fade)
            let fade = CABasicAnimation(keyPath: "opacity")
            fade.duration = 1.0/3.0;
            if (presenting) {
                fade.fromValue = 0
                fade.toValue = 1
            } else {
                fade.fromValue = 1
                fade.toValue = 0
            }
            animation = fade
        }
    
        // CAAnimation is KVC compliant, so we can store whether we're presenting for lookup in our delegate methods
        animation.setValue(presenting, forKey: "presenting")
    
        animation.fillMode = kCAFillModeForwards;
        animation.isRemovedOnCompletion = false;
        return animation;
    }
    
    override func layoutSubviews() {
    
        self.containerView.frame = self.bounds;
        self.getbackgroundView().frame = self.bounds;
    
        // if we're pointing up, we'll need to push almost everything down a bit
        let dy : CGFloat
        if (self.currentArrowDirection == CalloutArrowDirection.up) {
            dy = TOP_ANCHOR_MARGIN
        } else {
            dy = 0
        }
    
        self.titleViewOrDefault().setFrameX(self.innerContentMarginLeft)
        
        if (self.subtitleView != nil || self.subtitle?.length != nil) {
            self.titleViewOrDefault().setFrameY(TITLE_SUB_TOP + dy)
        } else {
            self.titleViewOrDefault().setFrameY(TITLE_TOP + dy)
        }
        
        self.titleViewOrDefault().setFrameWidth(self.frameWidth - self.innerContentMarginLeft - self.innerContentMarginRight)
    
        self.subtitleViewOrDefault().setFrameX(self.titleViewOrDefault().frameX)
        self.subtitleViewOrDefault().setFrameY(SUBTITLE_TOP + dy)
        self.subtitleViewOrDefault().setFrameWidth(self.titleViewOrDefault().frameWidth)
    
        if (self.contentView != nil) {
            self.contentView!.setFrameX(self.innerContentMarginLeft)
            self.contentView!.setFrameY(self.contentViewInset.top + dy + self.titleViewOrDefault().frameHeight + self.subtitleViewOrDefault().frameHeight)

        }
    }
    
    //Mark : - Accessibility
    /**
    override func accessibilityElementCount() -> NSInteger{
        return (!!self.titleViewOrDefault() + !!self.subtitleViewOrDefault())
    }
    
    - (id)accessibilityElementAtIndex:(NSInteger)index {
    if (index == 0) {
    return self.leftAccessoryView ? self.leftAccessoryView : self.titleViewOrDefault;
    }
    if (index == 1) {
    return self.leftAccessoryView ? self.titleViewOrDefault : self.subtitleViewOrDefault;
    }
    if (index == 2) {
    return self.leftAccessoryView ? self.subtitleViewOrDefault : self.rightAccessoryView;
    }
    if (index == 3) {
    return self.leftAccessoryView ? self.rightAccessoryView : nil;
    }
    return nil;
    }
    
    - (NSInteger)indexOfAccessibilityElement:(id)element {
    if (element == nil) return NSNotFound;
    if (element == self.leftAccessoryView) return 0;
    if (element == self.titleViewOrDefault) {
    return self.leftAccessoryView ? 1 : 0;
    }
    if (element == self.subtitleViewOrDefault) {
    return self.leftAccessoryView ? 2 : 1;
    }
    if (element == self.rightAccessoryView) {
    return self.leftAccessoryView ? 3 : 2;
    }
    return NSNotFound;
    }

**/


}

class CalloutBackgroundView: UIView {
    var arrowPoint: CGPoint?
    var anchorHeight : CGFloat
    var anchorMargin : CGFloat
    
    fileprivate var containerView, containerBorderView, arrowView : UIView
    fileprivate var arrowImageView, arrowBorderView : UIImageView
    fileprivate var blackArrowImage : UIImage? = nil
    fileprivate var whiteArrowImage : UIImage? = nil
    
    override init(frame: CGRect) {
        
        self.containerView = UIView()
        self.containerView.backgroundColor = UIColor.white;
        self.containerView.alpha = 0.96;
        self.containerView.layer.cornerRadius = 8;
        self.containerView.layer.shadowRadius = 30;
        self.containerView.layer.shadowOpacity = 0.1;
        
        self.containerBorderView = UIView()
        self.containerBorderView.layer.borderColor = UIColor(white: 0, alpha: 0.1).cgColor
        self.containerBorderView.layer.borderWidth = 0.5;
        self.containerBorderView.layer.cornerRadius = 8.5;

        if (blackArrowImage == nil) {
            blackArrowImage = UIImage(named: "blackArrow.png")
            whiteArrowImage = UIImage(named: "whiteArrow.png")
        }
        
        self.arrowView = UIView(frame: CGRect(x: 0, y: 0, width: blackArrowImage!.size.width, height: blackArrowImage!.size.height))
        self.arrowView.alpha = 0.96
        self.arrowImageView = UIImageView(image: whiteArrowImage!)
        self.arrowBorderView = UIImageView(image: blackArrowImage!)
        self.arrowBorderView.alpha = 0.1
        self.arrowBorderView.setFrameY(0.5)
        
        self.anchorMargin = 27
        self.anchorHeight = arrowImageView.frameHeight
        
        super.init(frame: frame)
        
        self.addSubview(self.containerView);
        self.containerView.addSubview(self.containerBorderView)
        self.addSubview(self.arrowView)
        self.arrowView.addSubview(self.arrowBorderView)
        self.arrowView.addSubview(self.arrowImageView)
        
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setArrowPoint(_ arrowPoint : CGPoint) {
        self.arrowPoint = arrowPoint
    }
    
    override func layoutSubviews() {
        let pointingUp : Bool = self.arrowPoint!.y < self.frameHeight/2
        let dy : CGFloat?
        if pointingUp {
            dy = CGFloat(TOP_ANCHOR_MARGIN)
        } else {
            dy = 0.0
        }
        
        self.containerView.frame = CGRect(x: 0, y: dy!, width: self.frameWidth, height: self.frameHeight - self.arrowView.frameHeight + 0.5);
        self.containerBorderView.frame = self.containerView.bounds.insetBy(dx: -0.5, dy: -0.5)
        
        self.arrowView.setFrameX(round(self.arrowPoint!.x - self.arrowView.frameWidth / 2))
        
        if (pointingUp) {
            self.arrowView.setFrameY(1)
            self.arrowView.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi));
        }
        else {
            self.arrowView.setFrameY(self.containerView.frameHeight - 0.5)
            self.arrowView.transform = CGAffineTransform.identity;
        }
    }
    
    var contentMask : CALayer {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, 0);
        
        self.layer.render(in: UIGraphicsGetCurrentContext()!);
        
        let maskImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        let layer = CALayer()
        layer.frame = self.bounds;
        layer.contents = maskImage?.cgImage;
        return layer;
    }
}

extension UIView {
    
    var frameOrigin : CGPoint { return self.frame.origin }
    func setFrameOrigin(_ origin : CGPoint) { self.frame = CGRect(origin: origin, size: self.frame.size) }
    
    var frameX : CGFloat { return self.frame.origin.x }
    func setFrameX (_ x : CGFloat) { self.frame = CGRect(x: x, y: self.frame.origin.y, width: self.frame.size.width, height: self.frame.size.height) }
    
    var frameY : CGFloat { return self.frame.origin.y }
    func setFrameY (_ y : CGFloat) { self.frame = CGRect(x: self.frame.origin.x, y: y, width: self.frame.size.width, height: self.frame.size.height) }
    
    var frameSize : CGSize { return self.frame.size }
    func setFrameSize (_ size : CGSize) { self.frame = CGRect(origin: self.frame.origin, size: size) }
    
    var frameWidth : CGFloat { return self.frame.width }
    func setFrameWidth (_ width : CGFloat) { self.frame = CGRect(x: self.frame.origin.x, y: self.frame.origin.y, width: width, height: self.frame.size.height) }
    
    var frameHeight : CGFloat { return self.frame.height }
    func setFrameHeight (_ height : CGFloat) { self.frame = CGRect(x: self.frame.origin.x, y: self.frame.origin.y, width: self.frame.size.width, height: height) }
    
    var frameLeft : CGFloat { return self.frame.origin.x }
    func setFrameLeft (_ left : CGFloat) { self.frame = CGRect(x: left, y: self.frame.origin.y, width: max(self.frame.origin.x+self.frame.size.width-left, 0), height: self.frame.size.height) }
    
    var frameTop : CGFloat { return self.frame.origin.y }
    func setFrameTop (_ top : CGFloat) { self.frame = CGRect(x: self.frame.origin.x, y: top, width: self.frame.size.width, height: max(self.frame.origin.y+self.frame.size.height - top, 0)) }
    
    var frameRight : CGFloat { return self.frame.origin.x + self.frame.size.height }
    func setFrameRight (_ right : CGFloat) { self.frame = CGRect(x: self.frame.origin.x, y: self.frame.origin.y, width: max(right - self.frame.origin.x, 0), height: self.frame.size.height) }
    
    var frameBottom : CGFloat { return self.frame.origin.y + self.frame.size.height }
    func setFrameBottom (_ bottom : CGFloat) { self.frame = CGRect(x: self.frame.origin.x, y: self.frame.origin.y, width: self.frame.size.width, height: max(bottom - self.frame.origin.y,0)) }

}
