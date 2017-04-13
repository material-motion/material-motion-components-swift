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
 A slide transition moves the forward view controller in from the bottom of the container to the
 center of the container.

 This transition will be interactive if provided with a pan gesture recognizer.
 */
public class SlideTransition: Transition {

  public required init() {}

  public func willBeginTransition(withContext ctx: TransitionContext, runtime: MotionRuntime) -> [Stateful] {
    let bounds = ctx.containerView().bounds
    let backPosition = CGPoint(x: bounds.midX, y: bounds.maxY + ctx.fore.view.bounds.height / 2)
    let forePosition = CGPoint(x: bounds.midX, y: bounds.midY)

    let draggable = Draggable(withFirstGestureIn: ctx.gestureRecognizers)

    runtime.add(ChangeDirection(withVelocityOf: draggable.nextGestureRecognizer, whenNegative: .forward),
                to: ctx.direction)

    let movement = TransitionSpring(back: backPosition, fore: forePosition, direction: ctx.direction)
    let tossable = Tossable(spring: movement, draggable: draggable)
    runtime.add(tossable, to: ctx.fore.view) { $0.xLocked(to: bounds.midX) }

    return [tossable]
  }
}
