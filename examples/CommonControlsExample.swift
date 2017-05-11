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

import UIKit
import MaterialMotion
import MaterialMotionComponents

@discardableResult
func theme(_ button: UIButton, color: UIColor) -> UIButton {
  button.backgroundColor = color
  button.contentEdgeInsets = .init(top: 8, left: 8, bottom: 8, right: 8)
  button.layer.cornerRadius = 2
  return button
}

class CommonControlsExampleViewController: ExampleViewController {

  var runtime: MotionRuntime!

  var cfg: ConfigurationController!
  var targets: [ReactiveButtonTarget] = []

  override func viewDidLoad() {
    super.viewDidLoad()

    runtime = MotionRuntime(containerView: view)
    cfg = ConfigurationController(runtime: runtime)

    view.backgroundColor = .white

    let jumpCutButton = UIButton(type: .custom)
    jumpCutButton.setTitle("Button", for: .normal)
    view.addSubview(jumpCutButton)

    theme(jumpCutButton, color: .black)

    jumpCutButton.sizeToFit()
    jumpCutButton.layer.position = .init(x: view.bounds.midX, y: view.bounds.midY)

    let target = ReactiveButtonTarget(jumpCutButton)
    let animationDuration = createProperty(withInitialValue: CGFloat(0.25))

    let highlightScale = createProperty(withInitialValue: 1)
    target.didHighlight.dedupe().subscribeToValue { highlighted in
      UIView.animate(withDuration: Double(animationDuration.value), delay: 0, options: UIViewAnimationOptions.beginFromCurrentState, animations: {
        jumpCutButton.backgroundColor = highlighted ? .lightGray : .black

        jumpCutButton.transform = highlighted ? CGAffineTransform(scaleX: highlightScale.value, y: highlightScale.value) : CGAffineTransform.identity
      })
    }
    targets.append(target)

    cfg.makeConfigurable(runtime.get(jumpCutButton.layer).cornerRadius,
                         min: 0, max: 10,
                         label: "Button corner radius")
    cfg.makeConfigurable(animationDuration,
                         min: 0.1, max: 0.5,
                         label: "Button highlight duration")
    cfg.makeConfigurable(highlightScale,
                         min: 0.5, max: 2,
                         label: "Button highlight scale")

    let configView = cfg.generateUI()
    configView.frame = .init(x: view.bounds.maxX - 300, y: 0, width: 300, height: view.bounds.height)
    view.addSubview(configView)
  }

  override func exampleInformation() -> ExampleInfo {
    return .init(title: type(of: self).catalogBreadcrumbs().last!,
                 instructions: "Common controls.")
  }
}

class ConfigurationController {

  private struct Configurator {
    let property: ReactiveProperty<CGFloat>
    let min: CGFloat
    let max: CGFloat
    let label: String
  }
  private var configurators: [Configurator] = []

  private let runtime: MotionRuntime
  init(runtime: MotionRuntime) {
    self.runtime = runtime
  }

  func makeConfigurable(_ property: ReactiveProperty<CGFloat>,
                        min: CGFloat,
                        max: CGFloat,
                        label: String) {
    configurators.append(.init(property: property, min: min, max: max, label: label))
  }

  func generateUI() -> UIView {
    let scrollView = UIScrollView(frame: .init(x: 0, y: 0, width: 300, height: 0))

    var topEdge: CGFloat = 0

    for configurator in configurators {
      let label = UILabel()
      let valueLabel = UILabel()
      let slider = UISlider()

      label.text = configurator.label
      label.numberOfLines = 0
      label.lineBreakMode = .byWordWrapping
      slider.minimumValue = Float(configurator.min)
      slider.maximumValue = Float(configurator.max)
      slider.value = Float(configurator.property.value)
      valueLabel.text = String(format: "%.2f", configurator.property.value)

      let labelSize = label.sizeThatFits(.init(width: 100, height: .max))
      let sliderSize = slider.sizeThatFits(.init(width: 200, height: .max))
      let valueSize = valueLabel.sizeThatFits(.init(width: 200, height: .max))
      label.frame = .init(x: 0, y: topEdge, width: labelSize.width, height: labelSize.height)
      slider.frame = .init(x: 100, y: topEdge, width: sliderSize.width, height: sliderSize.height)
      valueLabel.frame = .init(x: 100, y: slider.frame.maxY, width: 200, height: valueSize.height)

      topEdge += max(labelSize.height, sliderSize.height + valueSize.height)

      scrollView.addSubview(label)
      scrollView.addSubview(slider)
      scrollView.addSubview(valueLabel)

      runtime.connect(runtime.get(slider), to: configurator.property)
      runtime.connect(configurator.property.toString(format: "%.2f"), to: Reactive(valueLabel).text)
    }

    scrollView.contentInset = .init(top: 64, left: 0, bottom: 0, right: 0)
    scrollView.contentSize = .init(width: scrollView.bounds.width, height: topEdge)
    
    return scrollView
  }
}
