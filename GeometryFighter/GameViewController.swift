//
//  GameViewController.swift
//  GeometryFighter
//
//  Created by Benjamin Pust on 10/28/16.
//  Copyright © 2016 Ben Pust. All rights reserved.
//

import UIKit
import SceneKit

class GameViewController: UIViewController {
    
    var scnView: SCNView!
    var scnScene: SCNScene!
    var cameraNode: SCNNode!
    var spawnTime: TimeInterval = 0
    var game = GameHelper.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupScene()
        setupCamera()
        spawnShape()
        setupHUD()
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    func setupView() {
        scnView = self.view as! SCNView
        
        scnView.showsStatistics = true
        scnView.allowsCameraControl = false          // lets you control the active camera through simple gestures
        scnView.autoenablesDefaultLighting = true   // add generic omnidirectional light
        
        scnView.delegate = self
        scnView.isPlaying = true
    }
    
    func setupScene() {
        scnScene = SCNScene()
        scnView.scene = scnScene
        
        scnScene.background.contents = "GeometryFighter.scnassets/Textures/Background_Diffuse.png"
    }
    
    
    func setupCamera() {
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3Make(0, 5, 10)
        scnScene.rootNode.addChildNode(cameraNode)
    }
    
    func spawnShape() {
        var geometry: SCNGeometry
        
        let size: CGFloat = 0.6
        
        switch ShapeType.random() {
        case .box:
            geometry = SCNBox(width: size+1, height: size, length: size, chamferRadius: 0.1)
        case .sphere:
            geometry = SCNSphere(radius: size)
        case .pyramid:
            geometry = SCNPyramid(width: size, height: size, length: size)
        case .torus:
            geometry = SCNTorus(ringRadius: size+0.5, pipeRadius: size/2)
        case .capsule:
            geometry = SCNCapsule(capRadius: size/2, height: size+1)
        case .cylinder:
            geometry = SCNCylinder(radius: size, height: size)
        case .cone:
            geometry = SCNCone(topRadius: 0.3, bottomRadius: size, height: size)
        case .tube:
            geometry = SCNTube(innerRadius: 0.3, outerRadius: size+0.3, height: size+1)
        default:
            geometry = SCNBox(width: 1.0, height: 1.0, length: 1.0, chamferRadius: 0.0)
        }
        
        let color = UIColor.random()
        geometry.materials.first?.diffuse.contents = color
        
        let geometryNode = SCNNode(geometry: geometry)
        
        geometryNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        let randomX = Float.random(min: -2, max: 2)
        let randomY = Float.random(min: 10, max: 18)
        let force = SCNVector3Make(randomX, randomY, 0)
        let position = SCNVector3Make(0.05, 0.05, 0.05)
        geometryNode.physicsBody?.applyForce(force, at: position, asImpulse: true)
        
        let trailEmitter = createTrail(color: color, geometry: geometry)
        geometryNode.addParticleSystem(trailEmitter)
        
        if color == UIColor.red {
            geometryNode.name = "BAD"
        } else {
            geometryNode.name = "GOOD"
        }
        
        scnScene.rootNode.addChildNode(geometryNode)
    }
    
    func cleanScene() {
        for node in scnScene.rootNode.childNodes {
            if node.presentation.position.y < -2 {
                node.removeFromParentNode()
            }
        }
    }
    
    func createTrail(color: UIColor, geometry: SCNGeometry) -> SCNParticleSystem {
        let trail = SCNParticleSystem(named: "Trail.scnp", inDirectory: nil)!
        trail.particleColor = color
        trail.emitterShape = geometry
        return trail
    }
    
    func setupHUD(){
        game.hudNode.position = SCNVector3Make(0.0, 10.0, 0.0)
        scnScene.rootNode.addChildNode(game.hudNode)
    }
    
    func handleForTouch(node: SCNNode) {
        if node.name == "GOOD" {
            game.score += 1
            createExplosion(geometry: node.geometry!, position: node.presentation.position, rotation: node.presentation.rotation)
            node.removeFromParentNode()
        } else if node.name == "BAD" {
            game.lives -= 1
            createExplosion(geometry: node.geometry!, position: node.presentation.position, rotation: node.presentation.rotation)
            node.removeFromParentNode()
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first!
        let location = touch.location(in: scnView)
        let hitResults = scnView.hitTest(location, options: nil)
        if let result = hitResults.first {
            handleForTouch(node: result.node)
        }
    }
    
    func createExplosion(geometry: SCNGeometry, position: SCNVector3, rotation: SCNVector4) {
        let explosion = SCNParticleSystem(named: "Explode.scnp", inDirectory: nil)!
        explosion.emitterShape = geometry
        explosion.birthLocation = .surface
        let rotationMatrix = SCNMatrix4MakeRotation(rotation.w, rotation.x, rotation.y, rotation.z)
        let translationMatrix = SCNMatrix4MakeTranslation(position.x, position.y, position.z)
        let transformMatrix = SCNMatrix4Mult(rotationMatrix, translationMatrix)
        scnScene.addParticleSystem(explosion, transform: transformMatrix)
    }
}

extension GameViewController: SCNSceneRendererDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
        if time > spawnTime {
            spawnShape()
            
            spawnTime = time + TimeInterval(Float.random(min: 0.2, max: 1.5))
        }
        
        cleanScene()
        game.updateHUD()
    }
    
}
