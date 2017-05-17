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

let floodFillOvershootRatio: CGFloat = 1.2

/**
 A floating action button (FAB) masked reveal transition will use a mask effect to reveal the
 presented view controller as it slides into position.

 During dismissal, this transition falls back to a VerticalSheetTransition.
 */
public final class FABMaskedRevealTransition: TransitionWithPresentation, TransitionWithTermination, TransitionWithFallback {

  public init(fabView: UIView) {
    self.fabView = fabView
  }

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
      isUsingPresentationController = true
      return DimmingPresentationController(presentedViewController: presented,
                                           presenting: presenting,
                                           calculateFrameOfPresentedViewInContainerView: calculateFrameOfPresentedViewInContainerView)
    }
    isUsingPresentationController = false
    return nil
  }

  public func fallbackTansition(withContext ctx: TransitionContext) -> Transition {
    if ctx.direction.value == .backward {
      return VerticalSheetTransition()
    }
    return self
  }

  public func didEndTransition(withContext ctx: TransitionContext, runtime: MotionRuntime) {
    if !isUsingPresentationController {
      scrimView.removeFromSuperview()
      scrimView = nil
    }

    originalParentView.addSubview(ctx.fore.view)
    ctx.fore.view.frame.origin = originalOrigin
    maskedContainerView.removeFromSuperview()
    maskedContainerView = nil
    originalParentView = nil
    originalOrigin = nil
  }

  public func willBeginTransition(withContext ctx: TransitionContext, runtime: MotionRuntime) -> [Stateful] {
    guard ctx.direction.value == .forward else {
      assertionFailure("This transition does not support dismissal.")
      return []
    }

    var interactions: [Stateful] = []

    if !isUsingPresentationController {
      scrimView = UIView(frame: ctx.containerView().bounds)
      scrimView.backgroundColor = UIColor(white: 0, alpha: 0.3)
      ctx.containerView().addSubview(scrimView)
    }

    originalParentView = ctx.fore.view.superview
    originalOrigin = ctx.fore.view.frame.origin
    let originalFrame = ctx.fore.view.frame

    maskedContainerView = UIView(frame: ctx.fore.view.frame)
    maskedContainerView.clipsToBounds = true
    ctx.containerView().addSubview(maskedContainerView)

    let floodFillView = UIView()
    floodFillView.backgroundColor = fabView.backgroundColor
    floodFillView.frame = ctx.fore.view.bounds

    // TODO(featherless): Profile whether it's more performant to fade the flood fill out or to
    // fade the fore view in (what we're currently doing).
    maskedContainerView.addSubview(floodFillView)
    maskedContainerView.addSubview(ctx.fore.view)
    ctx.fore.view.frame.origin = .zero

    // Fade out the label, if any.
    if let button = fabView as? UIButton, let titleLabel = button.titleLabel, let text = titleLabel.text, !text.isEmpty {
      let label = ctx.replicator.replicate(view: titleLabel)

      let quickFadeOut = Tween<CGFloat>(duration: 0.075, values: [1, 0])
      runtime.add(quickFadeOut, to: runtime.get(label.layer).opacity)
      interactions.append(quickFadeOut)
    }

    let fabFrameInContainer = fabView.convert(fabView.bounds, to: ctx.containerView())
    let startingFrame = CGRect(x: ctx.fore.view.frame.minX,
                               y: fabFrameInContainer.minY - 20,
                               width: ctx.fore.view.bounds.width,
                               height: ctx.fore.view.bounds.height)
    let fabFrameInContent = fabFrameInContainer.offsetBy(dx: 0, dy: -fabFrameInContainer.minY + 20)
    let endingFrame = originalFrame

    let fabMaskLayer = CAShapeLayer()
    fabMaskLayer.path = UIBezierPath(rect: maskedContainerView.bounds).cgPath
    maskedContainerView.layer.mask = fabMaskLayer

    let fadeContentIn = Tween<CGFloat>(duration: 0.225, values: [0, 1])
    fadeContentIn.delay.value = 0.150
    fadeContentIn.timingFunctions.value = [.init(controlPoints: 0.4, 0.0, 0.2, 1.0)]
    runtime.add(fadeContentIn, to: runtime.get(ctx.fore.view).layer.opacity)
    interactions.append(fadeContentIn)

    let foreColor = ctx.fore.view.backgroundColor ?? .white

    let transitionFloodColor = Tween(duration: 0.075, values: [floodFillView.backgroundColor!.cgColor,
                                                               foreColor.cgColor])
    transitionFloodColor.timingFunctions.value = [.init(controlPoints: 0.4, 0.0, 0.2, 1.0)]
    runtime.add(transitionFloodColor, to: runtime.get(floodFillView).layer.backgroundColor)
    interactions.append(transitionFloodColor)

    // This is a guestimate answer to "when will the circle completely fill the visible content?"
    let fabCenterToFarthestVisiblePoint = CGVector(dx: fabFrameInContainer.midX - startingFrame.minX,
                                                   dy: fabFrameInContainer.midY - startingFrame.midY)
    let outerRadius = CGFloat(sqrt(fabCenterToFarthestVisiblePoint.dx * fabCenterToFarthestVisiblePoint.dx + fabCenterToFarthestVisiblePoint.dy * fabCenterToFarthestVisiblePoint.dy))
    let foreMaskBounds = CGRect(x: fabFrameInContent.midX - outerRadius,
                                y: fabFrameInContent.midY - outerRadius,
                                width: outerRadius * 2,
                                height: outerRadius * 2)
    let fabMaskReveal = Tween(duration: 0.105,
                              values: [UIBezierPath(ovalIn: fabFrameInContent).cgPath,
                                       UIBezierPath(ovalIn: foreMaskBounds).cgPath])
    fabMaskReveal.timingFunctions.value = [.init(controlPoints: 0.4, 0.0, 1.0, 1.0)]
    runtime.add(fabMaskReveal, to: runtime.get(fabMaskLayer).path)
    interactions.append(fabMaskReveal)
    fabMaskLayer.path = UIBezierPath(rect: maskedContainerView.bounds).cgPath

    let shiftContentUp = Tween(duration: 0.330, values: [startingFrame.midY, endingFrame.midY])
    shiftContentUp.delay.value = 0.045
    shiftContentUp.timingFunctions.value = [.init(controlPoints: 0.4, 0.0, 0.2, 1.0)]
    runtime.add(shiftContentUp, to: runtime.get(maskedContainerView.layer).positionY)
    interactions.append(shiftContentUp)

    if !isUsingPresentationController {
      let scrimFadeIn = Tween<CGFloat>(duration: 0.075, values: [0, 1])
      runtime.add(scrimFadeIn, to: runtime.get(scrimView).layer.opacity)
      scrimFadeIn.timingFunctions.value = [.init(controlPoints: 0.4, 0.0, 0.2, 1.0)]
      interactions.append(scrimFadeIn)
    }

    runtime.add(Hidden(), to: fabView)

    return interactions
  }

  private let fabView: UIView
  private var scrimView: UIView!
  private var maskedContainerView: UIView!
  private var originalParentView: UIView!
  private var originalOrigin: CGPoint!
  private var isUsingPresentationController = false
}

// TODO: The need here is we want to hide a given view will the transition is active. This
// implementation does not register a stream with the runtime.
private class Hidden: Interaction {
  deinit {
    for view in hiddenViews {
      view.isHidden = false
    }
  }
  func add(to view: UIView, withRuntime runtime: MotionRuntime, constraints: NoConstraints) {
    view.isHidden = true
    hiddenViews.insert(view)
  }
  var hiddenViews = Set<UIView>()
}
