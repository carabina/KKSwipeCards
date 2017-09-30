//
//  KKSwipeCard.swift
//  KKSwipeCards
//
//  Created by Vinoth on 30/09/17.
//

import Foundation
import UIKit

protocol KKSwipeCardDelegate: class {
    func cardSwipedLeft(_ card: KKSwipeCard)
    func cardSwipedRight(_ card: KKSwipeCard)
    func cardSwipedTop(_ card: KKSwipeCard)
    func cardSwipedBottom(_ card: KKSwipeCard)
    func cardTapped(_ card: KKSwipeCard)
}

enum SwipeSide {
    case topBottom
    case leftRight
    case all
}

class KKSwipeCard: UIView {
    
    static let shared = KKSwipeCard()
    
    weak var delegate: KKSwipeCardDelegate?
    var obj: Any!
    var leftOverlay: UIView?
    var rightOverlay: UIView?
    var swipeSide = SwipeSide.topBottom
    
    private let actionMargin: CGFloat = 120.0
    private let rotationStrength: CGFloat = 320.0
    private let rotationAngle: CGFloat = CGFloat(Double.pi) / CGFloat(8.0)
    private let rotationMax: CGFloat = 1
    private let scaleStrength: CGFloat = -2
    private let scaleMax: CGFloat = 1.02
    
    private var xFromCenter: CGFloat = 0.0
    private var yFromCenter: CGFloat = 0.0
    private var originalPoint = CGPoint.zero
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(dragEvent(gesture:)))
        panGesture.delegate = self
        self.addGestureRecognizer(panGesture)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapEvent(gesture:)))
        tapGesture.delegate = self
        self.addGestureRecognizer(tapGesture)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configureOverlays() {
        self.configureOverlay(overlay: self.leftOverlay)
        self.configureOverlay(overlay: self.rightOverlay)
    }
    
    private func configureOverlay(overlay: UIView?) {
        if let o = overlay {
            self.addSubview(o)
            o.alpha = 0.0
        }
    }
    
    @objc func dragEvent(gesture: UIPanGestureRecognizer) {
        xFromCenter = gesture.translation(in: self).x
        yFromCenter = gesture.translation(in: self).y
        
        switch gesture.state {
        case .began:
            self.originalPoint = self.center
            break
        case .changed:
            let rStrength = min(xFromCenter / self.rotationStrength, rotationMax)
            let rAngle = self.rotationAngle * rStrength
            let scale = min(1 - fabs(rStrength) / self.scaleStrength, self.scaleMax)
            self.center = CGPoint(x: self.originalPoint.x + xFromCenter, y: self.originalPoint.y + yFromCenter)
            let transform = CGAffineTransform(rotationAngle: rAngle)
            let scaleTransform = transform.scaledBy(x: scale, y: scale)
            self.transform = scaleTransform
            self.updateOverlay(xFromCenter)
            break
        case .ended:
            self.afterSwipeAction()
            break
        default:
            break
        }
    }
    
    @objc func tapEvent(gesture: UITapGestureRecognizer) {
        self.delegate?.cardTapped(self)
    }
    
    private func afterSwipeAction() {
        let swipeSide = KKSwipeCard.shared.swipeSide
        
        if yFromCenter > actionMargin, swipeSide != .leftRight {
            self.bottomAction()
        } else if yFromCenter < -actionMargin, swipeSide != .leftRight {
            self.topAction()
        } else if xFromCenter > actionMargin, swipeSide != .topBottom {
            self.rightAction()
        } else if xFromCenter < -actionMargin, swipeSide != .topBottom {
            self.leftAction()
        } else {
            UIView.animate(withDuration: 0.3) {
                self.center = self.originalPoint
                self.transform = CGAffineTransform.identity
                self.leftOverlay?.alpha = 0.0
                self.rightOverlay?.alpha = 0.0
            }
        }
    }
    
    private func updateOverlay(_ distance: CGFloat) {
        var activeOverlay: UIView?
        if (distance > 0) {
            self.leftOverlay?.alpha = 0.0
            activeOverlay = self.rightOverlay
        } else {
            self.rightOverlay?.alpha = 0.0
            activeOverlay = self.leftOverlay
        }
        
        activeOverlay?.alpha = min(fabs(distance)/100, 1.0)
    }
    
    private func rightAction() {
        let finishPoint = CGPoint(x: 500, y: 2 * yFromCenter + self.originalPoint.y)
        UIView.animate(withDuration: 0.3, animations: {
            self.center = finishPoint
        }) { _ in
            self.removeFromSuperview()
        }
        self.delegate?.cardSwipedRight(self)
    }
    
    private func leftAction() {
        let finishPoint = CGPoint(x: -500, y: 2 * yFromCenter + self.originalPoint.y)
        UIView.animate(withDuration: 0.3, animations: {
            self.center = finishPoint
        }) { _ in
            self.removeFromSuperview()
        }
        self.delegate?.cardSwipedLeft(self)
    }
    
    func topAction() {
        let finishPoint = CGPoint(x: 2 * xFromCenter + self.originalPoint.x, y: -1000)
        UIView.animate(withDuration: 0.3, animations: {
            self.center = finishPoint
        }) { _ in
            self.removeFromSuperview()
        }
        self.delegate?.cardSwipedTop(self)
    }
    
    private func bottomAction() {
        let finishPoint = CGPoint(x: 2 * xFromCenter + self.originalPoint.x, y: 1000)
        UIView.animate(withDuration: 0.3, animations: {
            self.center = finishPoint
        }) { _ in
            self.removeFromSuperview()
        }
        self.delegate?.cardSwipedBottom(self)
    }
}

extension KKSwipeCard: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
}

