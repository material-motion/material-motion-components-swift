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
 A modal transition moves the forward view controller from the bottom of the container to the center
 of the container.

 ## Customizing dismissal with gestures

 This transition will be interactive if a pan gesture recognizer is available.
 */
public final class ModalTransition: Transition {

  public required init() {}

  public func willBeginTransition(withContext ctx: TransitionContext, runtime: MotionRuntime) -> [Stateful] {
    let bounds = ctx.containerView().bounds
    let frame = ctx.fore.view.frame
    let forePosition = ctx.fore.view.layer.position
    let backPosition = CGPoint(x: forePosition.x, y: bounds.maxY + frame.height / 2)

    let activePans = ctx.gestureRecognizers.filter { $0 is UIPanGestureRecognizer && ($0.state == .began || $0.state == .changed) }
    let draggable = Draggable(withFirstGestureIn: activePans)

    let position = runtime.get(ctx.fore.view.layer).position

    let changeDirection = ChangeDirection(withVelocityOf: draggable.nextGestureRecognizer,
                                          whenNegative: .forward,
                                          whenPositive: .backward)
    runtime.add(changeDirection, to: ctx.direction)

    if let gesture = draggable.nextGestureRecognizer {
      // When let go without enough velocity, we set direction based only on position.

      let positionalDirection: MotionObservable<TransitionDirection> = position.y()
        .threshold(bounds.maxY)
        .rewrite([.below: .forward, .above: .backward])

      runtime.connect(runtime.get(gesture).velocityOnReleaseStream().y()
        .thresholdRange(min: -changeDirection.minimumVelocity, max: changeDirection.minimumVelocity)
        .rewrite([ .within: positionalDirection ]),
                      to: ctx.direction)
    }

    let spring = TransitionSpring(back: backPosition, fore: forePosition, direction: ctx.direction)
    let tossable = Tossable(spring: spring, draggable: draggable)

    draggable.resistance.perimeter.value = CGRect(x: forePosition.x,
                                                  y: forePosition.y,
                                                  width: 0,
                                                  height: backPosition.y - forePosition.y)

    runtime.add(tossable, to: ctx.fore.view) { $0.xLocked(to: forePosition.x) }

    return [tossable]
  }
}
