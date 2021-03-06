//
//  ViewController.swift
//  BazaartProject
//
//  Created by Yedidya Reiss on 19/05/2021.
//

import UIKit

class ViewController: UIViewController {

    private var canvasView: CanvasView!
    
    //----Mobile Bar View------------------
    var mobileBarView: MobileBarView!
    var portsManager: PortsManager!
    //-------------------------------------

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let width = view.bounds.width - 40
        let height = width * 4 / 3
        let size = CGSize(width: width, height: height)
        let canvas = CanvasView(frame: CGRect(origin: .zero, size: size))
        canvas.center = view.center
        view.addSubview(canvas)
        
        self.canvasView = canvas
        
        let margin: CGFloat = 40
        let buttons = [addButton(),deleteButton(),saveButton()]
        _ = buttons.reduce(CGPoint(x: margin, y: view.frame.height - 80)) { prev, btn -> CGPoint in
            view.addSubview(btn)
            btn.center = CGPoint(x: prev.x + btn.bounds.width / 2, y: prev.y)
            return CGPoint(x: prev.x + btn.bounds.width + margin, y: prev.y)
        }
        
        setUpMobileBar()
    }
    
    private func addButton() -> UIButton {
        let btn = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        btn.addTarget(self, action: #selector(addDidPressed), for: .touchUpInside)
        btn.setImage(UIImage(systemName: "plus"), for: .normal)
        return btn
    }
    
    private func deleteButton() -> UIButton {
        let btn = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        btn.addTarget(self, action: #selector(deleteDidPressed), for: .touchUpInside)
        btn.setImage(UIImage(systemName: "trash"), for: .normal)
        return btn
    }
    
    private func saveButton() -> UIButton {
        let btn = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        btn.addTarget(self, action: #selector(saveDidPressed), for: .touchUpInside)
        btn.setImage(UIImage(systemName: "camera"), for: .normal)
        return btn
    }
    
    @objc func addDidPressed() {
        _ = canvasView.addLayer()
    }
    
    @objc func deleteDidPressed() {
        _ = canvasView.deleteLastLayer()
    }
    
    @objc func saveDidPressed() {
        _ = canvasView.renderCanvas()
    }
}

// MARK: - ViewController Extension - Setup Mobile BAr & Ports
extension ViewController {
    
    fileprivate func setUpMobileBar() {
        //
        // Create Ports
        //
        portsManager = PortsManager(canvasView: canvasView, size: canvasView.bounds.width / 5.0)
        portsManager.setPorts()

        //
        // Build the Mobile Bar
        //
        mobileBarView = MobileBarView(frame: CGRect(x: 0.0, y: 0.0, width: 35, height: 100))
        self.canvasView.addSubview(mobileBarView)
        mobileBarView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        mobileBarView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        addPanGesture(mobileBarView)
        
        //
        // Observe presses on MobileBar buttons
        //
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(addDidPressed),
                                               name: Notification.Name("UserRequestAddLayer"),
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(deleteDidPressed),
                                               name: Notification.Name("UserRequestDeleteLayer"),
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(saveDidPressed),
                                               name: Notification.Name("UserRequestSaveLayer"),
                                               object: nil)
    }
    
    fileprivate func addPanGesture(_ view: UIView) {
        let pan = UIPanGestureRecognizer(target: self,
                                         action: #selector(ViewController.handlePan(sender:)))
        view.addGestureRecognizer(pan)
        view.isUserInteractionEnabled = true
    }
    
    @objc func handlePan(sender: UIPanGestureRecognizer) {
        
        // this is the moving view
        guard let panView = sender.view, panView is MobileBarView else {
            fatalError("Pan view nil")
        }
        
        // If you want to adjust a view's location to keep it under the user's finger,
        // request the translation in that view's superview's coordinate system.
        let translation = sender.translation(in: self.canvasView)
        
        switch sender.state {
        case .began, .changed:
            // displace according to translation
            panView.center = CGPoint(x: panView.center.x + translation.x,
                                     y: panView.center.y + translation.y)
            
            #if DEBUG
            print("PanView.center = \(panView.center)")
            #endif
            
            // reset translation
            sender.setTranslation(CGPoint.zero, in: self.canvasView)
            
        case .ended:
            //
            // Ports Check
            //
            checkPortsIntersect(panView as! MobileBarView)
        default:
            break
        }
    }
    
    fileprivate func checkPortsIntersect(_ panView: MobileBarView) {

        guard let nearestPort = portsManager.scanPortsIntersections(for: panView) else {
            fatalError("No Nearest Port Found")
        }
            
        UIView.animateKeyframes(withDuration: 0.7,
                                delay: 0.0,
                                options: .allowUserInteraction,
                                animations: {
                                    panView.center = nearestPort.center
                                    if nearestPort.isHorizontal {
                                        panView.setOrientation(.horizontal)
                                    } else {
                                        panView.setOrientation(.vertical)
                                    }
                                },
                                completion: { _ in })
   }
}
