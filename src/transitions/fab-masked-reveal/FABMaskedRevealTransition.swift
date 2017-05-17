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

  private var motion: Motion!
  public func fallbackTansition(withContext ctx: TransitionContext) -> Transition {
    self.motion = motion(withContext: ctx)

    if motion == nil {
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
      if let tween = motion.tween(for: motion.labelFade,
                                  values: [CGFloat(1), 0]) {
        let label = ctx.replicator.replicate(view: titleLabel)
        runtime.add(tween, to: runtime.get(label.layer).opacity)
        interactions.append(tween)
      }
    }

    let fabFrameInContainer = fabView.convert(fabView.bounds, to: ctx.containerView())
    let startingFrame: CGRect
    let vecToEdge: CGVector
    switch motion.contentPositioning {
    case .centered:
      startingFrame = CGRect(x: fabFrameInContainer.midX - ctx.fore.view.bounds.width / 2,
                             y: fabFrameInContainer.midY - ctx.fore.view.bounds.height / 2,
                             width: ctx.fore.view.bounds.width,
                             height: ctx.fore.view.bounds.height)
      vecToEdge = CGVector(dx: fabFrameInContainer.midX - startingFrame.maxX,
                           dy: fabFrameInContainer.midY - startingFrame.maxY)

    case .alignedNearTop:
      startingFrame = CGRect(x: ctx.fore.view.frame.minX,
                             y: fabFrameInContainer.minY - 20,
                             width: ctx.fore.view.bounds.width,
                             height: ctx.fore.view.bounds.height)
      if fabFrameInContainer.midX < startingFrame.midX {
        vecToEdge = CGVector(dx: fabFrameInContainer.midX - startingFrame.maxX,
                             dy: fabFrameInContainer.midY - startingFrame.midY)
      } else {
        vecToEdge = CGVector(dx: fabFrameInContainer.midX - startingFrame.minX,
                             dy: fabFrameInContainer.midY - startingFrame.midY)
      }
    }
    maskedContainerView.frame = startingFrame
    let fabFrameInContent = maskedContainerView.convert(fabFrameInContainer, from: ctx.containerView())
    let endingFrame = originalFrame

    let fabMaskLayer = CAShapeLayer()
    fabMaskLayer.path = UIBezierPath(rect: maskedContainerView.bounds).cgPath
    maskedContainerView.layer.mask = fabMaskLayer

    if let tween = motion.tween(for: motion.contentFade,
                                values: [CGFloat(0), 1]) {
      runtime.add(tween, to: runtime.get(ctx.fore.view).layer.opacity)
      interactions.append(tween)
    }

    let foreColor = ctx.fore.view.backgroundColor ?? .white

    if let tween = motion.tween(for: motion.fabBackgroundColor,
                                values: [floodFillView.backgroundColor!.cgColor, foreColor.cgColor]) {
      runtime.add(tween, to: runtime.get(floodFillView).layer.backgroundColor)
      interactions.append(tween)
    }

    // This is a guestimate answer to "when will the circle completely fill the visible content?"
    let targetRadius = CGFloat(sqrt(vecToEdge.dx * vecToEdge.dx + vecToEdge.dy * vecToEdge.dy))
    let foreMaskBounds = CGRect(x: fabFrameInContent.midX - targetRadius,
                                y: fabFrameInContent.midY - targetRadius,
                                width: targetRadius * 2,
                                height: targetRadius * 2)
    if let tween = motion.tween(for: motion.maskTransformation,
                                values: [UIBezierPath(ovalIn: fabFrameInContent).cgPath,
                                         UIBezierPath(ovalIn: foreMaskBounds).cgPath]) {
      runtime.add(tween, to: runtime.get(fabMaskLayer).path)
      interactions.append(tween)
      if motion.shouldReverseValues {
        fabMaskLayer.path = UIBezierPath(ovalIn: fabFrameInContent).cgPath
      } else {
        fabMaskLayer.path = UIBezierPath(rect: maskedContainerView.bounds).cgPath
      }
    }

    if let tween = motion.tween(for: motion.verticalMovement,
                                values: [startingFrame.midY, endingFrame.midY]) {
      runtime.add(tween, to: runtime.get(maskedContainerView.layer).positionY)
      interactions.append(tween)
    }

    if let tween = motion.tween(for: motion.horizontalMovement,
                                values: [startingFrame.midX, endingFrame.midX]) {
      runtime.add(tween, to: runtime.get(maskedContainerView.layer).positionX)
      interactions.append(tween)
    }

    if !isUsingPresentationController {
      if let tween = motion.tween(for: motion.scrimFade,
                                  values: [CGFloat(0), 1]) {
        runtime.add(tween, to: runtime.get(scrimView).layer.opacity)
        interactions.append(tween)
      }
    }

    runtime.add(Hidden(), to: fabView)

    return interactions
  }

  // Our motion router is based on context. We inspect the desired size of the content and adjust
  // the motion accordingly.
  private func motion(withContext ctx: TransitionContext) -> Motion? {
    let motion: Motion?
    if ctx.fore.view.frame == ctx.containerView().bounds {
      if ctx.direction.value == .forward {
        motion = fullscreenExpansion
      } else {
        motion = nil
      }

    } else if ctx.fore.view.frame.width == ctx.containerView().bounds.width && ctx.fore.view.frame.maxY == ctx.containerView().bounds.maxY {

      if ctx.fore.view.frame.height > 100 {
        if ctx.direction.value == .forward {
          motion = bottomSheetExpansion
        } else {
          motion = nil
        }

      } else {
        if ctx.direction.value == .forward {
          motion = toolbarExpansion
        } else {
          motion = toolbarCollapse
        }
      }

    } else if ctx.fore.view.frame.width < ctx.containerView().bounds.width && ctx.fore.view.frame.midY >= ctx.containerView().bounds.midY {
      if ctx.direction.value == .forward {
        motion = bottomCardExpansion
      } else {
        motion = bottomCardCollapse
      }

    } else {
      assertionFailure("Unhandled case.")
      motion = nil
    }

    return motion
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

private let eightyForty: [Float] = [0.4, 0.0, 0.2, 1.0]
private let fortyOut: [Float] = [0.4, 0.0, 1.0, 1.0]
private let eightyIn: [Float] = [0.0, 0.0, 0.2, 1.0]

private struct Motion {
  struct Timing {
    let delay: CGFloat
    let duration: CGFloat
    let controlPoints: [Float]
  }

  let labelFade: Timing
  let contentFade: Timing
  let fabBackgroundColor: Timing
  let maskTransformation: Timing
  let horizontalMovement: Timing?
  let verticalMovement: Timing
  let scrimFade: Timing

  enum ContentPositioning {
    case alignedNearTop
    case centered
  }
  let contentPositioning: ContentPositioning
  let shouldReverseValues: Bool

  func tween<T>(for timing: Motion.Timing?, values: [T]) -> Tween<T>? {
    guard let timing = timing else { return nil }

    let tween = Tween(duration: timing.duration, values: shouldReverseValues ? values.reversed() : values)
    tween.delay.value = timing.delay
    let timingFunction = CAMediaTimingFunction(controlPoints: timing.controlPoints[0],
                                               timing.controlPoints[1],
                                               timing.controlPoints[2],
                                               timing.controlPoints[3])
    tween.timingFunctions.value = [timingFunction]
    return tween
  }
}

private let fullscreenExpansion = Motion(
  labelFade: .init(delay: 0, duration: 0.075, controlPoints: eightyForty),
  contentFade: .init(delay: 0.150, duration: 0.225, controlPoints: eightyForty),
  fabBackgroundColor: .init(delay: 0, duration: 0.075, controlPoints: eightyForty),
  maskTransformation: .init(delay: 0, duration: 0.105, controlPoints: fortyOut),
  horizontalMovement: nil,
  verticalMovement: .init(delay: 0.045, duration: 0.330, controlPoints: eightyForty),
  scrimFade: .init(delay: 0, duration: 0.150, controlPoints: eightyForty),
  contentPositioning: .alignedNearTop,
  shouldReverseValues: false
)

private let bottomSheetExpansion = Motion(
  labelFade: .init(delay: 0, duration: 0.075, controlPoints: eightyForty),
  contentFade: .init(delay: 0.100, duration: 0.200, controlPoints: eightyForty), // No spec for this
  fabBackgroundColor: .init(delay: 0, duration: 0.075, controlPoints: eightyForty),
  maskTransformation: .init(delay: 0, duration: 0.105, controlPoints: fortyOut),
  horizontalMovement: nil,
  verticalMovement: .init(delay: 0.045, duration: 0.300, controlPoints: eightyForty),
  scrimFade: .init(delay: 0, duration: 0.150, controlPoints: eightyForty),
  contentPositioning: .alignedNearTop,
  shouldReverseValues: false
)

private let bottomCardExpansion = Motion(
  labelFade: .init(delay: 0, duration: 0.120, controlPoints: eightyForty),
  contentFade: .init(delay: 0.150, duration: 0.150, controlPoints: eightyForty),
  fabBackgroundColor: .init(delay: 0.075, duration: 0.075, controlPoints: eightyForty),
  maskTransformation: .init(delay: 0.045, duration: 0.225, controlPoints: fortyOut),
  horizontalMovement: .init(delay: 0, duration: 0.150, controlPoints: eightyForty),
  verticalMovement: .init(delay: 0, duration: 0.345, controlPoints: eightyForty),
  scrimFade: .init(delay: 0.075, duration: 0.150, controlPoints: eightyForty),
  contentPositioning: .centered,
  shouldReverseValues: false
)

private let bottomCardCollapse = Motion(
  labelFade: .init(delay: 0.150, duration: 0.150, controlPoints: eightyForty),
  contentFade: .init(delay: 0, duration: 0.075, controlPoints: fortyOut),
  fabBackgroundColor: .init(delay: 0.060, duration: 0.150, controlPoints: eightyForty),
  maskTransformation: .init(delay: 0, duration: 0.180, controlPoints: eightyIn),
  horizontalMovement: .init(delay: 0.045, duration: 0.255, controlPoints: eightyForty),
  verticalMovement: .init(delay: 0, duration: 0.255, controlPoints: eightyForty),
  scrimFade: .init(delay: 0, duration: 0.150, controlPoints: eightyForty),
  contentPositioning: .centered,
  shouldReverseValues: true
)

private let toolbarExpansion = Motion(
  labelFade: .init(delay: 0, duration: 0.120, controlPoints: eightyForty),
  contentFade: .init(delay: 0.150, duration: 0.150, controlPoints: eightyForty),
  fabBackgroundColor: .init(delay: 0.075, duration: 0.075, controlPoints: eightyForty),
  maskTransformation: .init(delay: 0.045, duration: 0.225, controlPoints: fortyOut),
  horizontalMovement: .init(delay: 0, duration: 0.300, controlPoints: eightyForty),
  verticalMovement: .init(delay: 0, duration: 0.120, controlPoints: eightyForty),
  scrimFade: .init(delay: 0.075, duration: 0.150, controlPoints: eightyForty),
  contentPositioning: .centered,
  shouldReverseValues: false
)

private let toolbarCollapse = Motion(
  labelFade: .init(delay: 0.150, duration: 0.150, controlPoints: eightyForty),
  contentFade: .init(delay: 0, duration: 0.075, controlPoints: fortyOut),
  fabBackgroundColor: .init(delay: 0.060, duration: 0.150, controlPoints: eightyForty),
  maskTransformation: .init(delay: 0, duration: 0.180, controlPoints: eightyIn),
  horizontalMovement: .init(delay: 0.105, duration: 0.195, controlPoints: eightyForty),
  verticalMovement: .init(delay: 0, duration: 0.255, controlPoints: eightyForty),
  scrimFade: .init(delay: 0, duration: 0.150, controlPoints: eightyForty),
  contentPositioning: .centered,
  shouldReverseValues: true
)
