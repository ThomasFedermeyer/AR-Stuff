//
//  ViewController.swift
//  AR surface Tarcking
//
//  Created by Thomas Federmeyer on 9/21/20.
//

import UIKit
import SceneKit
import ARKit
import RealityKit


enum bodytype:Int {
    case box = 1
    case plane = 2
    case ball = 3
    
    
}

/*
 useful pages:
 handeling update data-
 https://firebase.google.com/docs/firestore/query-data/listen#swift_1
 
 coca pods install errors-
 https://stackoverflow.com/questions/53135863/macos-mojave-ruby-config-h-file-not-found
 
 
 
 
 */
class ViewController: UIViewController, ARSCNViewDelegate, SCNPhysicsContactDelegate {

    
    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        sceneView.delegate = self
        sceneView.autoenablesDefaultLighting = true
        //sceneView.showsStatistics = true
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handle_tap))
        sceneView.addGestureRecognizer(tapGestureRecognizer)
        //sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]

        sceneView.scene.physicsWorld.contactDelegate = self
        
        
    }
    
    
    // detecks differnet kinds of colliosns
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        //print("Collison" )
        
        //print(contact.nodeA)
        //print(contact.nodeB)
        
        // adds gravity to the cube that a ball hits
        if(contact.nodeA.physicsBody?.categoryBitMask == bodytype.ball.rawValue &&
            contact.nodeB.physicsBody?.categoryBitMask == bodytype.box.rawValue){
            contact.nodeB.physicsBody?.isAffectedByGravity = true
        }
        
        // adds gravity to the cube that a ball hits
        else if(contact.nodeB.physicsBody?.categoryBitMask == bodytype.ball.rawValue &&
            contact.nodeA.physicsBody?.categoryBitMask == bodytype.box.rawValue){
            contact.nodeA.physicsBody?.isAffectedByGravity = true
        }
        // removes the ball that comes in contact with a plane
        else if(contact.nodeA.physicsBody?.categoryBitMask == bodytype.ball.rawValue &&
            contact.nodeB.physicsBody?.categoryBitMask == bodytype.plane.rawValue){
            contact.nodeA.removeFromParentNode()
        }
        // removes the ball that comes in contact wtih a plane
        else if(contact.nodeB.physicsBody?.categoryBitMask == bodytype.ball.rawValue &&
            contact.nodeA.physicsBody?.categoryBitMask == bodytype.plane.rawValue){
            contact.nodeB.removeFromParentNode()
        }
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
       
        configuration.planeDetection = [.horizontal, .vertical]
        
        sceneView.session.run(configuration)
        
    }
    
    var startouch: CGPoint?
    var endtouch: CGPoint?
    var starttime: TimeInterval?
    var endtime: TimeInterval?
    var change_arena = true

    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        let touch = touches.first
        startouch = touch?.location(in: view)
        starttime = Date().timeIntervalSince1970

        
        //print(startouch)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super .touchesEnded(touches, with: event)
        let touch = touches.first
        endtouch = touch?.location(in: view)
        endtime = Date().timeIntervalSince1970
        
        
        FlingBall()
        
    }
    
    @objc func handle_tap(sender: UITapGestureRecognizer){
        let tapped_view = sender.view as! SCNView
        let location_touched = sender.location(in: tapped_view)
        let hit_test = tapped_view.hitTest(location_touched, options: nil)
        if !hit_test.isEmpty{
            //print("hello again")
            let result = hit_test.first!
            // if its a cube applys a force in a radomdirection
            if (result.node.name == "cube pog"){
                result.node.physicsBody?.applyForce(SCNVector3(Float.random(in: 0...2),Float.random(in: 0...2),Float.random(in: 0...2)), at: SCNVector3(0, 0, 0), asImpulse: true)
                result.node.physicsBody?.isAffectedByGravity = true
            }
            // if its not a cube, then create a cube a random distance above the point
            else{
                var location = result.worldCoordinates
                var location_center = result.node.worldPosition
                var node_clicked = result.node
                //print(result.node.rotation)
                location.y = (location.y + Float.random(in: 0...1.5))

                //print(location)
                
                
                let cube = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0.0)
                cube.materials.first?.diffuse.contents = UIColor.red
                //let cube_node_1 = SCNNode(geometry: cube)
                
                
                // create the physcis body \\
//                cube_node_1.name = "cube pog"
//                cube_node_1.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
//                cube_node_1.physicsBody?.isAffectedByGravity     = false
//                cube_node_1.position                             = location
//                cube_node_1.physicsBody?.mass                    = 1
//                cube_node_1.physicsBody?.categoryBitMask         = bodytype.box.rawValue
//                cube_node_1.physicsBody?.collisionBitMask        = bodytype.plane.rawValue | bodytype.ball.rawValue
//                cube_node_1.physicsBody?.contactTestBitMask      = bodytype.plane.rawValue | bodytype.ball.rawValue

                //sceneView.scene.rootNode.addChildNode(cube_node_1)
                
                
                
                game_arena_create(coordinates: location_center, node_passed: node_clicked)
            }
            
            
        }
        
    }
    
    func game_arena_create(coordinates: SCNVector3, node_passed: SCNNode)  {
        
        change_arena = false
        
        //print(node_passed.name)
        
        let node_name = (node_passed.name ?? "NA") as String

        print(node_name)
        
        let node_geo_vales = node_name.split(separator: ",", maxSplits: 2, omittingEmptySubsequences: true)
        var node_geo_x = Double(node_geo_vales[0])!
        var node_geo_y = Double(node_geo_vales[1])!
        
        

        let cube = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0.0)
        cube.materials.first?.diffuse.contents = UIColor.red
        let cube_node_1 = SCNNode(geometry: cube)
        
        
        // create the physcis body \\
        cube_node_1.name = "cube pog"
        cube_node_1.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        cube_node_1.physicsBody?.isAffectedByGravity     = false
        cube_node_1.position                             = coordinates
        cube_node_1.physicsBody?.mass                    = 1
        
        
        var CGX = CGFloat(node_geo_x)
        var CGY = CGFloat(node_geo_y)
        let wall_plane_1 = SCNPlane(width: CGX, height: 1)
        let wall_plane_2 = SCNPlane(width: CGY, height: 1)
        wall_plane_1.materials.first?.diffuse.contents = UIColor.black.withAlphaComponent(1)
        wall_plane_2.materials.first?.diffuse.contents = UIColor.yellow.withAlphaComponent(1)
        let wall_plane_node1 = SCNNode(geometry: wall_plane_1)
        let wall_plane_node2 = SCNNode(geometry: wall_plane_2)
        let wall_plane_node3 = SCNNode(geometry: wall_plane_1)
        let wall_plane_node4 = SCNNode(geometry: wall_plane_2)
        wall_plane_node1.position = SCNVector3(coordinates.x, coordinates.y, coordinates.z + Float(node_geo_y/2))
        wall_plane_node2.position = SCNVector3(coordinates.x + Float(node_geo_x/2), coordinates.y, coordinates.z)
        wall_plane_node3.position = SCNVector3(coordinates.x, coordinates.y, coordinates.z - Float(node_geo_y/2))
        wall_plane_node4.position = SCNVector3(coordinates.x - Float(node_geo_x/2), coordinates.y, coordinates.z)
        wall_plane_node1.eulerAngles.y = .pi
        wall_plane_node2.eulerAngles.y = .pi/2*3
        wall_plane_node3.eulerAngles.y = 0
        wall_plane_node4.eulerAngles.y = .pi/2
        
        
        
        
        sceneView.scene.rootNode.addChildNode(cube_node_1)
        sceneView.scene.rootNode.addChildNode(wall_plane_node1)
        sceneView.scene.rootNode.addChildNode(wall_plane_node2)
        sceneView.scene.rootNode.addChildNode(wall_plane_node3)
        sceneView.scene.rootNode.addChildNode(wall_plane_node4)
    }
    
    
    // creates the first instacne of a plane
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(0.1)
        let plane = SCNPlane(width: width, height: height)
        plane.materials.first?.diffuse.contents = UIColor.purple.withAlphaComponent(0.8)
        let planeNode = SCNNode(geometry: plane)
        
        // corrdiantes
        let x_val = CGFloat(planeAnchor.center.x)
        let y_val = CGFloat(planeAnchor.center.y)
        let z_val = CGFloat(planeAnchor.center.z)
        
        //creates postion and physicsbody of the plane
        planeNode.position                           = SCNVector3(x_val,y_val,z_val)
        planeNode.eulerAngles.x                      = -.pi / 2
        planeNode.physicsBody                        = SCNPhysicsBody(type: .static, shape: nil)
        planeNode.physicsBody?.categoryBitMask       = bodytype.plane.rawValue
        planeNode.physicsBody?.collisionBitMask      = bodytype.box.rawValue | bodytype.ball.rawValue
        planeNode.physicsBody?.contactTestBitMask    = bodytype.box.rawValue | bodytype.ball.rawValue
        
        
        let cube = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0.0)
        cube.materials.first?.diffuse.contents = UIColor.red
        let cube_test = SCNNode(geometry: cube)
        
        
        // create the physcis body \\
        


        
        cube_test.name = ""
        cube_test.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        cube_test.physicsBody?.isAffectedByGravity     = false
        cube_test.physicsBody?.mass                    = 1
        cube_test.position = SCNVector3(0, 0, 0)

        
        //print(planeNode.position)
        //sceneView.scene.rootNode.addChildNode(cube_test)
        
        
        

        
        // 6
        //node.addChildNode(cube_test)
        //planeNode.addChildNode(cube_test)
        node.addChildNode(planeNode)
        
        
    }

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
     guard let planeAnchor = anchor as? ARPlaneAnchor,
     var planeNode = node.childNodes.first,
     let planeGeometry = planeNode.geometry as? SCNPlane
     else { return }

        if(change_arena){
            // updates the postion and dimentions of the plane
             planeGeometry.width                = CGFloat(planeAnchor.extent.x)
             planeGeometry.height               = CGFloat(planeAnchor.extent.z)
             planeNode.position                 = SCNVector3(planeAnchor.center.x, planeAnchor.center.y, planeAnchor.center.z)
                planeNode.name = "\(planeGeometry.height),\(planeGeometry.width)"
                //print(planeNode.position)
             update(&planeNode, withGeometry: planeGeometry, type: .static)
        }
        
    
    }
    
    func update(_ node: inout SCNNode, withGeometry geometry: SCNGeometry, type: SCNPhysicsBodyType) {
        let shape = SCNPhysicsShape(geometry: geometry, options: nil)
        let physicsBody = SCNPhysicsBody(type: type, shape: shape)
        node.physicsBody = physicsBody
    }
    
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        
    }
    
    
    
    // creates a ball from the camera postion and oriatnation with a velocity based on a swipe speed
    func FlingBall() {
        // total time of wipe
        let TimeBegin = Double(starttime ?? 0)
        let TimeEnd = Double(endtime ?? 0)
        let Time = TimeEnd - TimeBegin
        //print(Time)
        
        // change in vertial disntace for the swipe
        let Y_startpoint = Int(startouch?.y ?? 0)
        let Y_endPoint = Int(endtouch?.y ?? 0)
        let Y_distance = Y_startpoint - Y_endPoint
        let double_y_distance = Double(Y_distance)
        //print(Y_distance)
        
        let velocity = double_y_distance/Time / 1000
        //print(velocity)
        
        
        // the cammerea postion
        let POV = sceneView.pointOfView
        let transform = POV?.transform
        //let camerapos = SCNVector3(transform!.m41, transform!.m42, transform!.m43)
        
        
        // creating the sphere node
        let sphere = SCNSphere(radius: 0.05)
        sphere.materials.first?.diffuse.contents = UIColor.blue
        let Sphere_Node = SCNNode(geometry: sphere)
        Sphere_Node.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        Sphere_Node.position = SCNVector3Make(transform!.m41, transform!.m42, transform!.m43)
        Sphere_Node.physicsBody?.applyForce(SCNVector3(-2*transform!.m31 * Float(velocity), 0 * transform!.m42 * Float(velocity) , -2*transform!.m33 * Float(velocity)), at: SCNVector3(0, 0, 0), asImpulse: true)
        
        
        // physics body of the ball
        Sphere_Node.physicsBody?.categoryBitMask    = bodytype.ball.rawValue
        Sphere_Node.physicsBody?.collisionBitMask   = bodytype.box.rawValue | bodytype.plane.rawValue
        Sphere_Node.physicsBody?.contactTestBitMask = bodytype.box.rawValue | bodytype.plane.rawValue
        
        sceneView.scene.rootNode.addChildNode(Sphere_Node)
    }
    
    
    
    
    
    
}
