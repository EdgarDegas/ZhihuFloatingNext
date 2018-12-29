//
//  ViewController.swift
//  ZhihuFloatingNext
//
//  Created by 孙一萌 on 2018/12/29.
//  Copyright © 2018 iMoe. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var floatingView: UIView!
    private var floatingViewOriginalOrigin: CGPoint!
    private var floatingViewDecelerationAnimator: UIViewPropertyAnimator?
    
    private enum Storyboard {
        static let horizontalPadding: CGFloat = 42
        static let verticalPadding  : CGFloat = 120
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addPanRecognizer(for: floatingView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        layout(floatingView: floatingView)
    }
    
    private func addPanRecognizer(for floatingView: UIView) {
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panRecognized(_:)))
        floatingView.addGestureRecognizer(panRecognizer)
    }
    
    @objc private func panRecognized(_ recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .began  : handlePanBegin  (recognizer)
        case .changed: handlePanChange (recognizer)
        case .ended  : handlePanEnd    (recognizer)
        default: return
        }
    }
    
    private func handlePanBegin(_ recognizer: UIPanGestureRecognizer) {
        floatingViewDecelerationAnimator?.stopAnimation(false)
        floatingViewOriginalOrigin = floatingView.frame.origin
    }
    
    private func handlePanChange(_ recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: view)
        self.floatingView.frame.origin.x = translation.x + self.floatingViewOriginalOrigin.x
        self.floatingView.frame.origin.y = translation.y + self.floatingViewOriginalOrigin.y
    }
    
    private func handlePanEnd(_ recognizer: UIPanGestureRecognizer) {
        let velocity = recognizer.velocity(in: view)
        
        let rangedVelocity = CGPoint(
            x: min (800.0, max (-800.0, velocity.x) ),
            y: min (800.0, max (-800.0, velocity.y) )
        )
        
        let floatingBounds = view.safeBounds.inset(by: UIEdgeInsets(
            top: Storyboard.verticalPadding,
            left: Storyboard.horizontalPadding,
            bottom: Storyboard.verticalPadding,
            right: Storyboard.horizontalPadding))
        floatingViewDecelerationAnimator = animateDecelerate(
            floatingView: floatingView,
            insideOf: floatingBounds,
            with: rangedVelocity)
        floatingViewDecelerationAnimator?.startAnimation()
    }
}


// MARK: - Pure functions

extension ViewController {
    /// Use animation to describes the deceleration process of the floating view.
    ///
    /// When dragging and moving a floating view, the user is actually applying a force to that view.
    /// The force brings acceleration, and the acceleration gives the view velocity. Exactly the same with the physical world.
    ///
    /// So according to physical laws, if the user then released his finger, the floating view should decelerate from its current velocity.
    /// This method creates an animator to describe the deceleration process using the same deceleration rate with UIScrollView.
    ///
    /// - Parameters:
    ///     - floatingView: the floating view to decelerate
    ///     - theView: the view that describe floatingView's boundary, maybe its superview
    ///     - velocity: velocity when user released his finger
    ///
    /// - Returns: A UIViewPropertyAnimator instance ready to start.
    private func animateDecelerate(floatingView: UIView, insideOf theBounds: CGRect, with velocity: CGPoint) -> UIViewPropertyAnimator {

        
        let decelerationRate = UIScrollView.DecelerationRate.normal.rawValue
        
        let x = floatingView.frame.origin.x; let y = floatingView.frame.origin.y
        
        let projection = (
            x: x + (velocity.x / 1000.0) * decelerationRate / (1.0 - decelerationRate),
            y: y + (velocity.y / 1000.0) * decelerationRate / (1.0 - decelerationRate)
        )
        
        var targetX = projection.x; var targetY = projection.y
        
        if projection.x <= theBounds.midX {
            targetX = theBounds.origin.x
        } else {
            targetX = theBounds.maxX - floatingView.frame.width
        }
        
        if projection.y < theBounds.origin.y {
            targetY = theBounds.origin.y
        }
        
        if projection.y > theBounds.maxY - floatingView.frame.height {
            targetY = theBounds.maxY - floatingView.frame.height
        }
        
        return animateDeceleration {
            floatingView.frame.origin.x = targetX
            floatingView.frame.origin.y = targetY
        }
    }
    
    private func animateDeceleration(with animation: @escaping () -> Void) -> UIViewPropertyAnimator {
        
        let parameters = UISpringTimingParameters(dampingRatio: 0.98)
        let animator = UIViewPropertyAnimator(duration: 1, timingParameters: parameters)
        animator.addAnimations(animation)
        return animator
        
    }
    
    private func layout(floatingView: UIView) {
        floatingView.layer.cornerRadius = floatingView.frame.height / 2
        floatingView.layer.shadowOpacity = 0.1
        floatingView.layer.shadowOffset = CGSize(width: 2, height: 2)
        floatingView.layer.shadowPath = UIBezierPath(ovalIn: floatingView.layer.bounds.insetBy(dx: 2, dy: 2)).cgPath
        floatingView.layer.shadowRadius = 6
    }
}

extension UIView {
    var safeBounds: CGRect {
        return bounds.inset(by: safeAreaInsets)
    }
}
