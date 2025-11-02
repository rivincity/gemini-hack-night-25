//
//  Globe3DView.swift
//  Roam
//
//  Created by Eswar Karavadi on 11/2/25.
//

import SwiftUI
import RealityKit
import SceneKit

struct Globe3DView: View {
    @State private var rotation: Double = 0
    
    var body: some View {
        SceneKitGlobeView(rotation: $rotation)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        rotation += value.translation.width / 100
                    }
            )
    }
}

// MARK: - SceneKit Globe View
struct SceneKitGlobeView: UIViewRepresentable {
    @Binding var rotation: Double
    
    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.backgroundColor = .clear
        scnView.allowsCameraControl = true
        scnView.autoenablesDefaultLighting = true
        scnView.antialiasingMode = .multisampling4X
        
        // Create scene
        let scene = SCNScene()
        scnView.scene = scene
        
        // Create Earth sphere
        let sphere = SCNSphere(radius: 1.0)
        let earthNode = SCNNode(geometry: sphere)
        
        // Add Earth texture
        let material = SCNMaterial()
        material.diffuse.contents = UIImage(named: "earth_texture") ?? UIColor.blue
        material.specular.contents = UIColor.white
        material.shininess = 0.1
        sphere.materials = [material]
        
        scene.rootNode.addChildNode(earthNode)
        
        // Add camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 3)
        scene.rootNode.addChildNode(cameraNode)
        
        // Add ambient light
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.color = UIColor(white: 0.6, alpha: 1.0)
        scene.rootNode.addChildNode(ambientLight)
        
        // Add directional light
        let directionalLight = SCNNode()
        directionalLight.light = SCNLight()
        directionalLight.light?.type = .directional
        directionalLight.light?.color = UIColor.white
        directionalLight.position = SCNVector3(x: 5, y: 5, z: 5)
        scene.rootNode.addChildNode(directionalLight)
        
        // Store earth node in context for rotation updates
        context.coordinator.earthNode = earthNode
        
        // Auto-rotate
        let rotateAction = SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 60)
        let repeatAction = SCNAction.repeatForever(rotateAction)
        earthNode.runAction(repeatAction)
        
        return scnView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        // Update rotation based on user interaction
        if let earthNode = context.coordinator.earthNode {
            earthNode.eulerAngles.y = Float(rotation)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var earthNode: SCNNode?
    }
}

// MARK: - Alternative: Simple Blue Sphere (Fallback)
struct SimpleGlobeView: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.blue.opacity(0.8),
                            Color.blue,
                            Color.blue.opacity(0.6)
                        ],
                        center: .center,
                        startRadius: 50,
                        endRadius: 200
                    )
                )
                .frame(width: 300, height: 300)
                .shadow(color: .black.opacity(0.3), radius: 20, x: 10, y: 10)
            
            // Continents overlay (simplified)
            Image(systemName: "globe.americas.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 280, height: 280)
                .foregroundColor(.green.opacity(0.3))
        }
    }
}

#Preview("3D Globe") {
    Globe3DView()
}

#Preview("Simple Globe") {
    SimpleGlobeView()
}

