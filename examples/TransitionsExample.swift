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

let transitions: [Transition.Type] = [ModalTransition.self]

class TransitionsExampleViewController: ExampleViewController {

  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

    navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.play, target: self, action: #selector(didTap))
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  var picker: UIPickerView!
  var sizeSwitch: UISwitch!
  override func viewDidLoad() {
    super.viewDidLoad()

    picker = UIPickerView()
    let size = picker.sizeThatFits(view.bounds.size)
    picker.bounds = .init(origin: .zero, size: size)
    picker.layer.position = .init(x: view.bounds.midX, y: view.bounds.midY)
    picker.dataSource = self
    picker.delegate = self
    view.addSubview(picker)

    sizeSwitch = UISwitch()
    let sizeSize = sizeSwitch.sizeThatFits(view.bounds.size)
    sizeSwitch.frame = .init(origin: .init(x: view.bounds.midX - sizeSize.width / 2, y: picker.frame.maxY), size: size)
    view.addSubview(sizeSwitch)
  }

  func didTap() {
    let vc = ModalViewController()
    vc.transitionController.transitionType = transitions[picker.selectedRow(inComponent: 0)]
    if sizeSwitch.isOn {
      vc.preferredContentSize = .init(width: 100, height: 100)
      vc.modalPresentationStyle = .overCurrentContext
    }
    present(vc, animated: true)
  }

  override func exampleInformation() -> ExampleInfo {
    return .init(title: type(of: self).catalogBreadcrumbs().last!,
                 instructions: "Tap to present a modal transition.")
  }
}

extension TransitionsExampleViewController: UIPickerViewDataSource {
  func numberOfComponents(in pickerView: UIPickerView) -> Int {
    return 1
  }

  func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    return transitions.count
  }
}

extension TransitionsExampleViewController: UIPickerViewDelegate {
  func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
    let string = String(describing: transitions[row])
    return NSAttributedString(string: string, attributes: [NSForegroundColorAttributeName: UIColor.white])
  }
}

private class ModalViewController: UIViewController {

  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .primaryColor

    view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTap)))

    let pan = UIPanGestureRecognizer()
    view.addGestureRecognizer(pan)
    transitionController.dismissWhenGestureRecognizerBegins(pan)
  }

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }

  func didTap() {
    dismiss(animated: true)
  }
}
