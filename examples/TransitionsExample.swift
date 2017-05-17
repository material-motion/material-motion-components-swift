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

class TransitionsExampleViewController: ExampleViewController {

  struct TransitionInfo {
    let name: String
    let transition: Transition
  }
  var transitions: [TransitionInfo] = []

  var tableView: UITableView!
  override func viewDidLoad() {
    super.viewDidLoad()

    transitions.append(.init(name: "Vertical sheet", transition: VerticalSheetTransition()))

    let modalDialog = VerticalSheetTransition()
    modalDialog.calculateFrameOfPresentedViewInContainerView = { containerView, _, _ in
      let size = CGSize(width: 200, height: 200)
      return CGRect(x: (containerView.bounds.width - size.width) / 2,
                    y: (containerView.bounds.height - size.height) / 2,
                    width: size.width,
                    height: size.height)
    }
    transitions.append(.init(name: "Modal dialog", transition: modalDialog))

    tableView = UITableView(frame: view.bounds, style: .plain)
    tableView.dataSource = self
    tableView.delegate = self
    tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    view.addSubview(tableView)

    let fab = UIButton(type: .custom)
    fab.frame = .init(x: view.bounds.maxX - 100, y: view.bounds.maxY - 100, width: 64, height: 64)
    fab.setTitle("+", for: .normal)
    fab.titleLabel?.font = UIFont.systemFont(ofSize: 28)
    fab.layer.cornerRadius = fab.bounds.width / 2
    fab.backgroundColor = .orange
    fab.addTarget(self, action: #selector(didTapFab), for: .touchUpInside)
    view.addSubview(fab)

    let fab2 = UIButton(type: .custom)
    fab2.frame = .init(x: fab.frame.minX, y: fab.frame.minY - 100, width: 64, height: 64)
    fab2.setTitle("+", for: .normal)
    fab2.titleLabel?.font = UIFont.systemFont(ofSize: 28)
    fab2.layer.cornerRadius = fab2.bounds.width / 2
    fab2.backgroundColor = .blue
    fab2.addTarget(self, action: #selector(didTapFab2), for: .touchUpInside)
    view.addSubview(fab2)
  }

  var cachedSelection: IndexPath?
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    cachedSelection = tableView.indexPathForSelectedRow
    if let selectedIndexPath = cachedSelection {
      tableView.deselectRow(at: selectedIndexPath, animated: animated)
    }
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)

    if let selectedIndexPath = cachedSelection {
      tableView.selectRow(at: selectedIndexPath, animated: false, scrollPosition: .none)
      cachedSelection = nil
    }
  }

  func didTapFab(fab: UIView) {
    let vc = ModalViewController()

    vc.transitionController.transition = FABMaskedRevealTransition(fabView: fab)

    showDetailViewController(vc, sender: self)
  }

  func didTapFab2(fab: UIView) {
    let vc = ModalViewController()

    let transition = FABMaskedRevealTransition(fabView: fab)
    transition.calculateFrameOfPresentedViewInContainerView = { containerView, _, _ in
      return containerView.bounds.divided(atDistance: 300, from: .maxYEdge).slice
    }
    vc.transitionController.transition = transition

    showDetailViewController(vc, sender: self)
  }

  override func exampleInformation() -> ExampleInfo {
    return .init(title: type(of: self).catalogBreadcrumbs().last!,
                 instructions: "Tap to present a modal transition.")
  }
}

extension TransitionsExampleViewController: UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return transitions.count
  }
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    cell.textLabel?.text = transitions[indexPath.row].name
    return cell
  }
}

extension TransitionsExampleViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let modal = ModalViewController()
    modal.transitionController.transition = transitions[indexPath.row].transition
    showDetailViewController(modal, sender: self)
  }
}

private class ModalViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .primaryColor

    view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTap)))

    let label = UILabel(frame: view.bounds)
    label.numberOfLines = 0
    label.lineBreakMode = .byWordWrapping
    label.text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. In aliquam dolor eget orci condimentum, eu blandit metus dictum. Suspendisse vitae metus pellentesque, sagittis massa vel, sodales velit. Aliquam placerat nibh et posuere interdum. Etiam fermentum purus vel turpis lobortis auctor. Curabitur auctor maximus purus, ac iaculis mi. In ac hendrerit sapien, eget porttitor risus. Integer placerat cursus viverra. Proin mollis nulla vitae nisi posuere, eu rutrum mauris condimentum. Nullam in faucibus nulla, non tincidunt lectus. Maecenas mollis massa purus, in viverra elit molestie eu. Nunc volutpat magna eget mi vestibulum pharetra. Suspendisse nulla ligula, laoreet non ante quis, vehicula facilisis libero. Morbi faucibus, sapien a convallis sodales, leo quam scelerisque leo, ut tincidunt diam velit laoreet nulla. Proin at quam vel nibh varius ultrices porta id diam. Pellentesque pretium consequat neque volutpat tristique. Sed placerat a purus ut molestie. Nullam laoreet venenatis urna non pulvinar. Proin a vestibulum nulla, eu placerat est. Morbi molestie aliquam justo, ut aliquet neque tristique consectetur. In hac habitasse platea dictumst. Fusce vehicula justo in euismod elementum. Ut vel malesuada est. Aliquam mattis, ex vel viverra eleifend, mauris nibh faucibus nibh, in fringilla sem purus vitae elit. Donec sed dapibus orci, ut vulputate sapien. Integer eu magna efficitur est pellentesque tempor. Sed ac imperdiet ex. Maecenas congue quis lacus vel dictum. Phasellus dictum mi at sollicitudin euismod. Mauris laoreet, eros vitae euismod commodo, libero ligula pretium massa, in scelerisque eros dui eu metus. Fusce elementum mauris velit, eu tempor nulla congue ut. In at tellus id quam feugiat semper eget ut felis. Nulla quis varius quam. Nullam tincidunt laoreet risus, ut aliquet nisl gravida id. Nulla iaculis mauris velit, vitae feugiat nunc scelerisque ac. Vivamus eget ligula porta, pulvinar ex vitae, sollicitudin erat. Maecenas semper ornare suscipit. Ut et neque condimentum lectus pulvinar maximus in sit amet odio. Aliquam congue purus erat, eu rutrum risus placerat a."
    label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    view.addSubview(label)

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
