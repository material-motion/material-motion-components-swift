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

public typealias CalculateFrame = (UIView, UIViewController, UIViewController) -> CGRect

/**
 A vertical sheet transition moves the forward view controller from the bottom of the container to
 the center of the container.
 */
public final class VerticalSheetTransition: TransitionWithPresentation {

  public init() {}

  /**
   This optional block can be used to customize the frame of the presented view controller.

   If no block is provided, then the presented view controller will consume the entire container
   view's bounds.

   The first argument is the **presenting** view controller. The second argument is the
   **presented** view controller.
   */
  public var calculateFrameOfPresentedViewInContainerView: CalculateFrame?

  public func defaultModalPresentationStyle() -> UIModalPresentationStyle? {
    if calculateFrameOfPresentedViewInContainerView != nil {
      return .custom
    }
    return nil
  }

  public func presentationController(forPresented presented: UIViewController,
                                     presenting: UIViewController?,
                                     source: UIViewController) -> UIPresentationController? {
    if let calculateFrameOfPresentedViewInContainerView = calculateFrameOfPresentedViewInContainerView {
      return DimmingPresentationController(presentedViewController: presented,
                                           presenting: presenting,
                                           calculateFrameOfPresentedViewInContainerView: calculateFrameOfPresentedViewInContainerView)
    }
    return nil
  }

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

final class DimmingPresentationController: UIPresentationController, Transition {
  public init(presentedViewController: UIViewController,
              presenting presentingViewController: UIViewController?,
              calculateFrameOfPresentedViewInContainerView: @escaping CalculateFrame) {
    let dimmingView = UIView()
    dimmingView.backgroundColor = UIColor(white: 0, alpha: 0.3)
    dimmingView.alpha = 0
    self.dimmingView = dimmingView

    self.calculateFrameOfPresentedViewInContainerView = calculateFrameOfPresentedViewInContainerView

    super.init(presentedViewController: presentedViewController, presenting: presentingViewController)

    let tap = UITapGestureRecognizer(target: self, action: #selector(didTap))
    dimmingView.addGestureRecognizer(tap)
  }

  func didTap() {
    presentingViewController.dismiss(animated: true)
  }

  let calculateFrameOfPresentedViewInContainerView: CalculateFrame

  override var frameOfPresentedViewInContainerView: CGRect {
    guard let containerView = containerView else {
      assertionFailure("Missing container view during frame query.")
      return .zero()
    }
    return calculateFrameOfPresentedViewInContainerView(containerView, presentingViewController, presentedViewController)
  }

  public override func presentationTransitionWillBegin() {
    guard let containerView = containerView else { return }

    dimmingView.frame = containerView.bounds
    dimmingView.alpha = 0

    containerView.insertSubview(dimmingView, at: 0)

    presentedViewController.view.autoresizingMask = [.flexibleLeftMargin,
                                                     .flexibleTopMargin,
                                                     .flexibleRightMargin,
                                                     .flexibleBottomMargin]
  }

  public override func presentationTransitionDidEnd(_ completed: Bool) {
    if !completed {
      dimmingView.removeFromSuperview()
    }
  }

  public override func dismissalTransitionDidEnd(_ completed: Bool) {
    if completed {
      dimmingView.removeFromSuperview()
    }
  }

  public func willBeginTransition(withContext ctx: TransitionContext, runtime: MotionRuntime) -> [Stateful] {
    let fade = TransitionTween<CGFloat>(duration: 0.375, forwardValues: [0, 1], direction: ctx.direction)
    runtime.add(fade, to: runtime.get(dimmingView.layer).opacity)
    return [fade]
  }

  private let dimmingView: UIView
}
