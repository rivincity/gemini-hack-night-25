//
//  ViewController.swift
//  Roam
//
//  Created by Eswar Karavadi on 11/2/25.
//

import UIKit
import SwiftUI

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup the main globe view
        view.backgroundColor = .systemBackground
        
        // Create and add the globe view controller
        let globeVC = GlobeViewController()
        addChild(globeVC)
        view.addSubview(globeVC.view)
        globeVC.view.frame = view.bounds
        globeVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        globeVC.didMove(toParent: self)
    }
}

// MARK: - SwiftUI Preview
#Preview {
    ViewController()
}

