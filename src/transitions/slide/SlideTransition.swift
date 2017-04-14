/*
 Copyright 2017-present The Material Motion Authors. All Rights Reserved.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import Foundation
import MaterialMotion

/**
 A slide transition moves the forward view controller from the bottom of the container to the center
 of the container.

 ## Customizing dismissal with gestures

 This transition supports being dismissed with a pan gestural interaction. When
 gesturally-dismissed, the transition will lock the view controller's movement to the dominant axis
 of the gesture's velocity. If you do not want this behavior, you are encouraged to implementn your
 dismissal gesture's gestureRecognizerShouldBegin delegate method and use
 `SlideTransition.dismissDirection` to check whether the dismiss direction is one you wish to
 support.

     func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
       let dismissDirection = SlideTransition.dismissDirection(for: gesture, in: containerView)
       return dismissDirection == .bottom
     }

 This transition will be interactive if provided with a pan gesture recognizer.
 */
public final class SlideTransition: Transition {

  public required init() {}

  /**
   The axis-locked direction in which the fore view controller will be dismissed.
   */
  public enum DismissDirection {
    case left
    case top
    case right
    case bottom
  }

  /**
   Returns the axis-locked direction of dismissal for the given view controller.
   */
  public static func dismissDirection(for gestureRecognizer: UIPanGestureRecognizer, in view: UIView) -> DismissDirection {
    let initialVelocity = gestureRecognizer.velocity(in: view)
    if initialVelocity.x > 0 && abs(initialVelocity.x) > abs(initialVelocity.y) {
      return  .right

    } else if initialVelocity.x < 0 && abs(initialVelocity.x) > abs(initialVelocity.y) {
      return .left

    } else if initialVelocity.y < 0 && abs(initialVelocity.y) > abs(initialVelocity.x) {
      return .top

    } else {
      return .bottom
    }
  }

  public func willBeginTransition(withContext ctx: TransitionContext, runtime: MotionRuntime) -> [Stateful] {
    let bounds = ctx.containerView().bounds
    let forePosition = CGPoint(x: bounds.midX, y: bounds.midY)

    let offscreenLeft = CGPoint(x: bounds.minX - ctx.fore.view.bounds.width / 2, y: bounds.midY)
    let offscreenRight = CGPoint(x: bounds.maxX + ctx.fore.view.bounds.width / 2, y: bounds.midY)
    let offscreenTop = CGPoint(x: bounds.midX, y: bounds.minY - ctx.fore.view.bounds.height / 2)
    let offscreenBottom = CGPoint(x: bounds.midX, y: bounds.maxY + ctx.fore.view.bounds.height / 2)

    let draggable = Draggable(withFirstGestureIn: ctx.gestureRecognizers)
    let gesture = draggable.nextGestureRecognizer

    let dismissDirection = type(of: self).dismissDirection(for: gesture, in: ctx.containerView())

    let axis: ChangeDirection.Axis
    let backPosition: CGPoint
    switch dismissDirection {
    case .right:
      axis = .x
      backPosition = offscreenRight
    case .left:
      axis = .x
      backPosition = offscreenLeft
    case .top:
      axis = .y
      backPosition = offscreenTop
    case .bottom:
      axis = .y
      backPosition = offscreenBottom
    }

    let position = runtime.get(ctx.fore.view.layer).position

    // Change the direction based on velocity.

    let changeDirection: ChangeDirection
    switch dismissDirection {
    case .left: fallthrough
    case .top:
      changeDirection = ChangeDirection(withVelocityOf: gesture, whenNegative: .backward, whenPositive: .forward)

    case .right: fallthrough
    case .bottom:
      changeDirection = ChangeDirection(withVelocityOf: gesture, whenNegative: .forward, whenPositive: .backward)
    }

    let velocityOnRelease: MotionObservable<CGFloat>
    switch axis {
    case .x:
      velocityOnRelease = runtime.get(gesture).velocityOnReleaseStream().x()
    case .y:
      velocityOnRelease = runtime.get(gesture).velocityOnReleaseStream().y()
    }

    let positionalDirection: MotionObservable<TransitionDirection>
    switch dismissDirection {
    case .left:
        positionalDirection = position.x()
          .threshold(bounds.minX)
          .rewrite([.below: .backward, .above: .forward])

    case .right:
      positionalDirection = position.x()
        .threshold(bounds.maxX)
        .rewrite([.below: .forward, .above: .backward])

    case .top:
      positionalDirection = position.y()
        .threshold(bounds.minY)
        .rewrite([.below: .backward, .above: .forward])

    case .bottom:
      positionalDirection = position.y()
        .threshold(bounds.maxY)
        .rewrite([.below: .forward, .above: .backward])
    }

    runtime.add(changeDirection, to: ctx.direction, constraints: axis)

    // When let go without enough velocity, we set direction based only on position.

    runtime.connect(velocityOnRelease
      .thresholdRange(min: -changeDirection.minimumVelocity, max: changeDirection.minimumVelocity)
      .rewrite([ .within: positionalDirection ]),
                    to: ctx.direction)

    let spring = TransitionSpring(back: backPosition, fore: forePosition, direction: ctx.direction)
    let tossable = Tossable(spring: spring, draggable: draggable)

    switch axis {
    case .x:
      runtime.add(tossable, to: ctx.fore.view) { $0.yLocked(to: bounds.midY) }
    case .y:
      runtime.add(tossable, to: ctx.fore.view) { $0.xLocked(to: bounds.midX) }
    }

    return [tossable]
  }
}
