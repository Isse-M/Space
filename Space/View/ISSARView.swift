import SwiftUI
import ARKit
import SceneKit

struct ISSARView: UIViewControllerRepresentable {
    let position: (x: Float, y: Float, z: Float)
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> ARViewController {
        let controller = ARViewController()
        controller.onDismiss = { dismiss() }
        // Skicka in startpositionen direkt
        controller.targetPosition = SCNVector3(position.x, position.y, position.z)
        return controller
    }

    func updateUIViewController(_ uiViewController: ARViewController, context: Context) {
        uiViewController.updateNodePosition(x: position.x, y: position.y, z: position.z)
    }
}

class ARViewController: UIViewController {
    var sceneView = ARSCNView()
    var issNode: SCNNode?
    var onDismiss: (() -> Void)?
    var targetPosition: SCNVector3?

    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.frame = view.bounds
        view.addSubview(sceneView)
        
        sceneView.autoenablesDefaultLighting = true
        
        let config = ARWorldTrackingConfiguration()
        config.worldAlignment = .gravityAndHeading
        sceneView.session.run(config)
        
        if let scene = SCNScene(named: "ISS_stationary.usdz") {
            let containerNode = SCNNode()
                        
                        scene.rootNode.enumerateChildNodes { (child, _) in
                            child.geometry?.subdivisionLevel = 0
                            containerNode.addChildNode(child)
                        }
                        
                        issNode = containerNode
                    
                    
                    issNode?.scale = SCNVector3(0.1, 0.1, 0.1)
            
                    if let node = issNode {
                        sceneView.scene.rootNode.addChildNode(node)
                    }
                }
        
        
        
        addCloseButton()
    }

    func updateNodePosition(x: Float, y: Float, z: Float) {
        issNode?.position = SCNVector3(x, y, z)
    }
    
    private func addCloseButton() {
        let button = UIButton(type: .close)
        button.frame = CGRect(x: 20, y: 60, width: 40, height: 40)
        button.addTarget(self, action: #selector(close), for: .touchUpInside)
        view.addSubview(button)
    }

    @objc func close() {
        sceneView.session.pause()
        onDismiss?()
    }
}
