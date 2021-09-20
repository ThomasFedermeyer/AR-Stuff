//
//  ViewController.swift
//  Billiards
//
//  Created by Ed Federmeyer on 4/11/21.
//

import UIKit
import SceneKit
import ARKit
import RealityKit
import MultipeerConnectivity



enum bodytype:Int {
    case plane = 1
    case ball = 2
    case ball_player1 = 3
    case ball_player2 = 4
    case ball_final = 5
    case goal = 6
    
}

/*
 useful pages:
 handeling update data-
 https://firebase.google.com/docs/firestore/query-data/listen#swift_1
 
 coca pods install errors-
 https://stackoverflow.com/questions/53135863/macos-mojave-ruby-config-h-file-not-found
 
 // might need to change the lanes to walls woth width so stuff doesnt fall out
 
 
 
 */
class ViewController: UIViewController, ARSCNViewDelegate, SCNPhysicsContactDelegate, MCSessionDelegate, MCBrowserViewControllerDelegate {
   

    
    @IBOutlet var sceneView: ARSCNView!
    
    var all_nodes = [SCNNode]()
    var ball_nodes = [SCNNode]()
    var scanned_surfaces = [SCNNode]()
    var center_pos:SCNVector3!
    var P1_score = 0
    var P2_score = 0
    var check_first_collide = false
    var is_turn:Bool!
    var other_arenaX:Double!
    var other_arenaY:Double!
    
    // goal vars bc im lazy and this is an easy easy fix, to pass the vars one at a time
    var goal_x1:Double!
    var goal_y1:Double!
    var goal_x2:Double!
    var goal_y2:Double!
    var goal_x3:Double!
    var goal_y3:Double!
    var goal_x4:Double!
    var goal_y4:Double!
    var goal_height1:Double!
    var goal_height2:Double!
    var goal_height3:Double!
    var goal_height4:Double!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        sceneView.delegate = self
        sceneView.autoenablesDefaultLighting = true
        //sceneView.showsStatistics = true
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handle_tap))
        sceneView.addGestureRecognizer(tapGestureRecognizer)
        //sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]

        sceneView.scene.physicsWorld.contactDelegate = self
        
        
        peerID = MCPeerID(displayName: UIDevice.current.name)
        session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        host = false
        
    }
    
    
    // detecks differnet kinds of colliosns
    
    //MARK: ##THE PHYSICS STUFF ##
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        //print("Collison" )
        
        //print(contact.nodeA.name)
        //print(contact.nodeB.name)
        if(!check_first_collide && (contact.nodeA.name == "flung_ball" || contact.nodeB.name == "flung_ball") ){
            check_first_collide = true
            //print(check_first_collide)
            //print("POGGGG")
        }
        if(check_first_collide && contact.nodeA.name == "flung_ball" ){
            contact.nodeA.physicsBody?.collisionBitMask = 1|3|4|5
        }
        else if(check_first_collide && contact.nodeB.name == "flung_ball" ){
            contact.nodeB.physicsBody?.collisionBitMask = 1|3|4|5
        }
        if (contact.nodeA.name == "flung_ball" && contact.nodeB.name == "ground_node"){
            contact.nodeA.removeFromParentNode()
            
        }
        else if (contact.nodeB.name == "flung_ball" && contact.nodeA.name == "ground_node"){
            contact.nodeB.removeFromParentNode()
        }
        else if (contact.nodeA.name == "ground_node" && (contact.nodeB.physicsBody?.collisionBitMask == 3) || contact.nodeB.physicsBody?.collisionBitMask == 4 || contact.nodeB.physicsBody?.collisionBitMask == 5){
            contact.nodeB.physicsBody?.velocityFactor.y = 2
        }
        else if (contact.nodeB.name == "ground_node" && (contact.nodeA.physicsBody?.collisionBitMask == 3) || contact.nodeA.physicsBody?.collisionBitMask == 4 || contact.nodeA.physicsBody?.collisionBitMask == 5){
            contact.nodeA.physicsBody?.velocityFactor.y = 2
        }
        else if (contact.nodeA.name == "top_node" && (contact.nodeB.physicsBody?.collisionBitMask == 3) || contact.nodeB.physicsBody?.collisionBitMask == 4 || contact.nodeB.physicsBody?.collisionBitMask == 5){
            contact.nodeB.physicsBody?.velocityFactor.y = -2
        }
        else if (contact.nodeB.name == "top_node" && (contact.nodeA.physicsBody?.collisionBitMask == 3) || contact.nodeA.physicsBody?.collisionBitMask == 4 || contact.nodeA.physicsBody?.collisionBitMask == 5){
            contact.nodeA.physicsBody?.velocityFactor.y = -2
        }
        else if (contact.nodeA.name == "flung_ball" && (contact.nodeB.name == "P1_ball" || contact.nodeB.name == "P2_ball")){
            contact.nodeB.physicsBody?.velocityFactor.x = 0.9
            contact.nodeB.physicsBody?.velocityFactor.y = 0.9
            contact.nodeB.physicsBody?.velocityFactor.z = 0.9
        }
        else if (contact.nodeB.name == "flung_ball" && (contact.nodeA.name == "P1_ball" || contact.nodeA.name == "P2_ball")){
            contact.nodeA.physicsBody?.velocityFactor.x = 0.9
            contact.nodeA.physicsBody?.velocityFactor.y = 0.9
            contact.nodeA.physicsBody?.velocityFactor.z = 0.9
        }
        
        
        
        if(contact.nodeA.name == "goal" && contact.nodeB.name == "P1_ball"){
            P1_score = P1_score + 1
            contact.nodeB.removeFromParentNode()
            P1_score = P1_score + 1
            msg_send = "points:P1"
            var message = msg_send.data(using: String.Encoding.utf8, allowLossyConversion: false)

            do {
                try self.session.send(message!, toPeers: self.session.connectedPeers, with: .reliable)
            }
            catch{
                print("well that didnt work")
            }
        }
        else if(contact.nodeB.name == "goal" && contact.nodeA.name == "P1_ball"){
            P1_score = P1_score + 1
            contact.nodeA.removeFromParentNode()
            P1_score = P1_score + 1
            msg_send = "points:P1"
            var message = msg_send.data(using: String.Encoding.utf8, allowLossyConversion: false)

            do {
                try self.session.send(message!, toPeers: self.session.connectedPeers, with: .reliable)
            }
            catch{
                print("well that didnt work")
            }
        }
        else if(contact.nodeA.name == "goal" && contact.nodeB.name == "P2_ball"){
            P2_score = P2_score + 1
            contact.nodeB.removeFromParentNode()
            P1_score = P1_score + 1
            msg_send = "points:P2"
            var message = msg_send.data(using: String.Encoding.utf8, allowLossyConversion: false)

            do {
                try self.session.send(message!, toPeers: self.session.connectedPeers, with: .reliable)
            }
            catch{
                print("well that didnt work")
            }
        }
        else if(contact.nodeB.name == "goal" && contact.nodeA.name == "P2_ball"){
            P2_score = P2_score + 1
            contact.nodeA.removeFromParentNode()
            P1_score = P1_score + 1
            msg_send = "points:P2"
            var message = msg_send.data(using: String.Encoding.utf8, allowLossyConversion: false)

            do {
                try self.session.send(message!, toPeers: self.session.connectedPeers, with: .reliable)
            }
            catch{
                print("well that didnt work")
            }
        }
        
        else if(contact.nodeA.name == "goal" && contact.nodeB.name == "final_ball"){
            
            if (host && P1_score == 4){
                msg_send = "winner_host?:true"
            }
            if (!host && P2_score == 4){
                msg_send = "winner_host:false"
            }
            else{
                msg_send = "winner_host:false"
            }
            var message = msg_send.data(using: String.Encoding.utf8, allowLossyConversion: false)

            do {
                try self.session.send(message!, toPeers: self.session.connectedPeers, with: .reliable)
            }
            catch{
                print("well that didnt work")
            }
            end_game()
        }
        else if(contact.nodeB.name == "goal" && contact.nodeA.name == "final_ball"){
            
            if (host && P1_score == 4){
                msg_send = "winner_host?:true"
            }
            if (!host && P2_score == 4){
                msg_send = "winner_host:false"
            }
            else{
                msg_send = "winner_host:false"
            }
            var message = msg_send.data(using: String.Encoding.utf8, allowLossyConversion: false)

            do {
                try self.session.send(message!, toPeers: self.session.connectedPeers, with: .reliable)
            }
            catch{
                print("well that didnt work")
            }
            end_game()
        }
        
        
        
        
        // adds gravity to the cube that a ball hits
//        if(contact.nodeA.physicsBody?.categoryBitMask == bodytype.ball.rawValue &&
//            contact.nodeB.physicsBody?.categoryBitMask == bodytype.box.rawValue){
//            contact.nodeB.physicsBody?.isAffectedByGravity = true
//        }
//
//        // adds gravity to the cube that a ball hits
//        else if(contact.nodeB.physicsBody?.categoryBitMask == bodytype.ball.rawValue &&
//            contact.nodeA.physicsBody?.categoryBitMask == bodytype.box.rawValue){
//            contact.nodeA.physicsBody?.isAffectedByGravity = true
//        }
//        // removes the ball that comes in contact with a plane
//        else if(contact.nodeA.physicsBody?.categoryBitMask == bodytype.ball.rawValue &&
//            contact.nodeB.physicsBody?.categoryBitMask == bodytype.plane.rawValue){
//            contact.nodeA.removeFromParentNode()
//        }
//        // removes the ball that comes in contact wtih a plane
//        else if(contact.nodeB.physicsBody?.categoryBitMask == bodytype.ball.rawValue &&
//            contact.nodeA.physicsBody?.categoryBitMask == bodytype.plane.rawValue){
//            contact.nodeB.removeFromParentNode()
//        }
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
    var area_sizeX:Double!
    var arra_sizeY:Double!
    var selected_node:SCNNode!
    

    

    
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
    
    //MARK: handles Tapping on a plane to start the game
    @objc func handle_tap(sender: UITapGestureRecognizer){
        if (change_arena == true){
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
                    
                    // sending messages
                    selected_node = node_clicked
                    let node_name = (node_clicked.name ?? "NA") as String
                    let node_geo_vales = node_name.split(separator: ",", maxSplits: 2, omittingEmptySubsequences: true)
                    let node_geo_x = Double(node_geo_vales[0])!
                    let node_geo_y = Double(node_geo_vales[1])!
                    
                    if(host){
                        goal_x1 = Double.random(in: 0.2 ..< (node_geo_x - 0.2))/2
                        goal_y1 = Double.random(in: 0.2 ..< (node_geo_y - 0.2))/2
                        goal_height1 = Double.random(in: 0.1 ..< 0.9)
                        goal_x2 = Double.random(in: 0.2 ..< (node_geo_x - 0.2))/2
                        goal_y2 = Double.random(in: 0.2 ..< (node_geo_y - 0.2))/2
                        goal_height2 = Double.random(in: 0.1 ..< 0.9)
                        msg_send = "Goal:" + String(format: "%f", (goal_x1)) + ":" + String(format: "%f", (goal_y1)) + ":" + String(format: "%f", (goal_height1)) + ":" + String(format: "%f", (goal_x2)) + ":" + String(format: "%f", (goal_y2)) + ":" + String(format: "%f", (goal_height2))
                        print(msg_send)
                        let message = msg_send.data(using: String.Encoding.utf8, allowLossyConversion: false)
                        
                        do {
                            try self.session.send(message!, toPeers: self.session.connectedPeers, with: .reliable)
                        }
                        catch{
                            print("well that didnt work")
                        }
                        
                    }
                    else{
                        goal_x3 = Double.random(in: 0.1 ..< (node_geo_x - 0.1))/2
                        goal_y3 = Double.random(in: 0.1 ..< (node_geo_y - 0.1))/2
                        goal_height3 = Double.random(in: 0.1 ..< 0.9)
                        goal_x4 = Double.random(in: 0.1 ..< (node_geo_x - 0.1))/2
                        goal_y4 = Double.random(in: 0.1 ..< (node_geo_y - 0.1))/2
                        goal_height4 = Double.random(in: 0.1 ..< 0.9)
                        msg_send = "Goal:" + String(format: "%f", (goal_x3)) + ":" + String(format: "%f", (goal_y3)) + ":" + String(format: "%f", (goal_height3)) + ":" + String(format: "%f", (goal_x4)) + ":" + String(format: "%f", (goal_y4)) + ":" + String(format: "%f", (goal_height4))
                        print(msg_send)
                        let message = msg_send.data(using: String.Encoding.utf8, allowLossyConversion: false)
                        
                        do {
                            try self.session.send(message!, toPeers: self.session.connectedPeers, with: .reliable)
                        }
                        catch{
                            print("well that didnt work")
                        }
                    }
                    
                    
                    msg_send = "plane_info:" + String(format: "%f", (node_geo_x)) + ":" + String(format: "%f", (node_geo_y))
                    print(msg_send)
                    let message = msg_send.data(using: String.Encoding.utf8, allowLossyConversion: false)
                    
                    do {
                        try self.session.send(message!, toPeers: self.session.connectedPeers, with: .reliable)
                    }
                    catch{
                        print("well that didnt work")
                    }
                    
                    if(other_arenaY != nil){
                        game_arena_create(coordinates_to_lazy_to_remove: location_center, node_passed: node_clicked)
                        
                    }
                
                    
                    //node_clicked.removeFromParentNode()
                }
                
                
            }
        }
        
    }
    
    
    
    //MARK: ## MAKING THE ARENA ##
    func game_arena_create(coordinates_to_lazy_to_remove: SCNVector3, node_passed: SCNNode)  {
        
        // create a temp bottom with and top untill i get the orrentation working
        if (change_arena == true){
            change_arena = false
            for node in scanned_surfaces {
                node.isHidden = true
            }
            
            //print(node_passed.name)
            
            let node_name = (node_passed.name ?? "NA") as String

            
            let coordinates = node_passed.worldPosition
            center_pos = coordinates
            let node_geo_vales = node_name.split(separator: ",", maxSplits: 2, omittingEmptySubsequences: true)
            var node_geo_x = Double(node_geo_vales[0])!
            var node_geo_y = Double(node_geo_vales[1])!
            
            if (other_arenaX < node_geo_x){
                node_geo_x = other_arenaX
            }
            if (other_arenaY < node_geo_y){
                node_geo_y = other_arenaY
            }
            
            
            
            
            // MARK: Wall shit
            
            var CGX = CGFloat(node_geo_x)
            var CGY = CGFloat(node_geo_y)
            
            var big_side: CGFloat
            if (CGY > CGX){
                big_side = CGY
            }
            else{
                big_side = CGX
            }
            
            let plane_ground = SCNPlane(width: CGX, height: CGY)
            plane_ground.materials.first?.diffuse.contents = UIColor.blue.withAlphaComponent(0.8)
            let plane_ground_node = SCNNode(geometry: plane_ground)
            plane_ground_node.position = coordinates
            plane_ground_node.eulerAngles.x  = -.pi / 2
            plane_ground_node.name = "ground_node"
            
            
            
            
            var plane_top_node = plane_ground_node.clone()
            plane_top_node.position = SCNVector3Make(coordinates.x, coordinates.y + Float(big_side), coordinates.z)
            plane_top_node.eulerAngles.x  = -.pi*3 / 2
            plane_top_node.name = "top_node"
            
            
            let wall_plane_1 = SCNPlane(width: CGX, height: big_side)
            let wall_plane_2 = SCNPlane(width: CGY, height: big_side)
            wall_plane_1.materials.first?.diffuse.contents = UIColor.blue.withAlphaComponent(0.8)
            wall_plane_2.materials.first?.diffuse.contents = UIColor.blue.withAlphaComponent(0.8)
            let wall_plane_node1 = SCNNode(geometry: wall_plane_1)
            let wall_plane_node2 = SCNNode(geometry: wall_plane_2)
            let wall_plane_node3 = SCNNode(geometry: wall_plane_1)
            let wall_plane_node4 = SCNNode(geometry: wall_plane_2)
            wall_plane_node1.name = "Wall 1"
            wall_plane_node2.name = "Wall 2"
            wall_plane_node3.name = "Wall 3"
            wall_plane_node4.name = "Wall 4"
            wall_plane_node1.position = SCNVector3(coordinates.x, coordinates.y + (Float(big_side)/2), coordinates.z + Float(node_geo_y/2))
            wall_plane_node2.position = SCNVector3(coordinates.x + Float(node_geo_x/2), coordinates.y + (Float(big_side)/2) , coordinates.z)
            wall_plane_node3.position = SCNVector3(coordinates.x, coordinates.y + (Float(big_side)/2), coordinates.z - Float(node_geo_y/2))
            wall_plane_node4.position = SCNVector3(coordinates.x - Float(node_geo_x/2), coordinates.y + (Float(big_side)/2), coordinates.z)
            wall_plane_node1.eulerAngles.y = .pi
            wall_plane_node2.eulerAngles.y = .pi/2*3
            wall_plane_node3.eulerAngles.y = 0
            wall_plane_node4.eulerAngles.y = .pi/2
            
            
            
            // this adds a goal
            // use math.random from 0,coordiates x, y and or z to get a random postion
            // then just use that insed for hte postion vector
            // do this 4 - 6 times and rotate them accordingly to put one goal on every wall
            
            
            // the random spawning is still a little bit janky/ off by a little
            
            
            
            //MARK: Goal Shit
            let cylender = SCNCylinder(radius: 0.2, height: 0.02)
            cylender.materials.first?.diffuse.contents = UIColor.orange.withAlphaComponent(0.8)
            
            
            
            
            
            var goal_x = Double.random(in: 0.1 ..< (node_geo_x - 0.1))/2
            var goal_y = Double.random(in: 0.1 ..< (node_geo_y - 0.1))/2
            var goal_height = Double.random(in: 0.1 ..< (Double(big_side) - 0.1))
            var test = Bool.random()
            if(test) {
                goal_x = goal_x * -1
            }
            var test2 = Bool.random()
            if(test2) {
                goal_y = goal_y * -1
            }
            let goal_node_1 = SCNNode(geometry: cylender)
            goal_node_1.name = "goal"
            //old
            //goal_node_1.position = SCNVector3(coordinates.x + Float(goal_x), coordinates.y + Float(goal_height), coordinates.z + Float(node_geo_y/2))
            goal_node_1.position = SCNVector3(coordinates.x + Float(goal_x1), coordinates.y + Float(goal_height1*Double(big_side)/2), coordinates.z + Float(node_geo_y/2))
            goal_node_1.eulerAngles.x = .pi/2
            
            
            goal_node_1.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
            goal_node_1.physicsBody?.categoryBitMask = 6
            goal_node_1.physicsBody?.categoryBitMask = bodytype.ball_player1.rawValue
            
            
            goal_x = Double.random(in: 0.1 ..< (node_geo_x - 0.1))/2
            goal_y = Double.random(in: 0.1 ..< (node_geo_y - 0.1))/2
            
            goal_height = Double.random(in: 0.2 ..< (Double(big_side) - 0.2))
            test = Bool.random()
            if(test) {
                goal_x = goal_x * -1
            }
            test2 = Bool.random()
            if(test2) {
                goal_y = goal_y * -1
            }
            let goal_node_2 = SCNNode(geometry: cylender)
            goal_node_2.name = "goal"
            //goal_node_2.position = SCNVector3(coordinates.x + Float(node_geo_x/2), coordinates.y + Float(goal_height), coordinates.z - Float(goal_y))
            goal_node_2.position = SCNVector3(coordinates.x + Float(node_geo_x/2), coordinates.y + Float(goal_height2*Double(big_side)/2), coordinates.z - Float(goal_y2))
            goal_node_2.eulerAngles.x = .pi/2
            goal_node_2.eulerAngles.y = .pi/2
            
            
            goal_node_2.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
            goal_node_2.physicsBody?.categoryBitMask = 6
            goal_node_2.physicsBody?.categoryBitMask = bodytype.ball_player1.rawValue
            
            
            goal_x = Double.random(in: 0.1 ..< (node_geo_x - 0.1))/2
            goal_y = Double.random(in: 0.1 ..< (node_geo_y - 0.1))/2
            goal_height = Double.random(in: 0.1 ..< (Double(big_side) - 0.1))
            test = Bool.random()
            if(test) {
                goal_x = goal_x * -1
            }
            test2 = Bool.random()
            if(test2) {
                goal_y = goal_y * -1
            }
            let goal_node_3 = SCNNode(geometry: cylender)
            goal_node_3.name = "goal"
            //goal_node_3.position = SCNVector3(coordinates.x + Float(goal_x), coordinates.y + Float(goal_height), coordinates.z - Float(node_geo_y/2))
            goal_node_3.position = SCNVector3(coordinates.x + Float(goal_x3), coordinates.y + Float(goal_height3*Double(big_side)/2), coordinates.z - Float(node_geo_y/2))
            goal_node_3.eulerAngles.x = .pi/2
            
            goal_node_3.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
            goal_node_3.physicsBody?.categoryBitMask = 6
            goal_node_3.physicsBody?.categoryBitMask = bodytype.ball_player1.rawValue
            //good
            
            
            goal_x = Double.random(in: 0.1 ..< (node_geo_x - 0.1))/2
            goal_y = Double.random(in: 0.1 ..< (node_geo_y - 0.1))/2
            goal_height = Double.random(in: 0.1 ..< (Double(big_side) - 0.1))
            test = Bool.random()
            if(test) {
                goal_x = goal_x * -1
            }
            test2 = Bool.random()
            if(test2) {
                goal_y = goal_y * -1
            }
            let goal_node_4 = SCNNode(geometry: cylender)
            goal_node_4.name = "goal"
            //goal_node_4.position = SCNVector3(coordinates.x - Float(node_geo_x/2), coordinates.y + Float(goal_height), coordinates.z + Float(goal_y))
            goal_node_4.position = SCNVector3(coordinates.x - Float(node_geo_x/2), coordinates.y + Float(goal_height4*Double(big_side)/2), coordinates.z + Float(goal_y4))
            goal_node_4.eulerAngles.x = .pi/2
            goal_node_4.eulerAngles.y = .pi/2
            
            goal_node_4.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
            goal_node_4.physicsBody?.categoryBitMask = 6
            goal_node_4.physicsBody?.categoryBitMask = bodytype.ball_player1.rawValue
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            

            
            //MARK: Arena wall phyics
            // adding the physics bitmasks
            plane_ground_node.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
            plane_ground_node.physicsBody?.categoryBitMask    = bodytype.plane.rawValue
            plane_ground_node.physicsBody?.collisionBitMask   = bodytype.ball_player1.rawValue | bodytype.ball_player2.rawValue | bodytype.ball.rawValue | bodytype.ball_final.rawValue
            //plane_ground_node.physicsBody?.contactTestBitMask = bodytype.ball_player1.rawValue | bodytype.ball_player2.rawValue | bodytype.ball.rawValue | bodytype.ball_final.rawValue
            
            plane_top_node.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
            plane_top_node.physicsBody?.categoryBitMask       = bodytype.plane.rawValue
            plane_ground_node.physicsBody?.collisionBitMask   = bodytype.ball_player1.rawValue | bodytype.ball_player2.rawValue | bodytype.ball.rawValue | bodytype.ball_final.rawValue
            plane_ground_node.physicsBody?.contactTestBitMask = bodytype.ball_player1.rawValue | bodytype.ball_player2.rawValue | bodytype.ball.rawValue | bodytype.ball_final.rawValue
            
            wall_plane_node1.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
            wall_plane_node1.physicsBody?.categoryBitMask    = bodytype.plane.rawValue
            wall_plane_node1.physicsBody?.collisionBitMask   = bodytype.ball_player1.rawValue | bodytype.ball_player2.rawValue | bodytype.ball.rawValue | bodytype.ball_final.rawValue
            wall_plane_node1.physicsBody?.contactTestBitMask = bodytype.ball_player1.rawValue | bodytype.ball_player2.rawValue | bodytype.ball.rawValue | bodytype.ball_final.rawValue
            
            wall_plane_node2.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
            wall_plane_node2.physicsBody?.categoryBitMask    = bodytype.plane.rawValue
            wall_plane_node2.physicsBody?.collisionBitMask   = bodytype.ball_player1.rawValue | bodytype.ball_player2.rawValue | bodytype.ball.rawValue | bodytype.ball_final.rawValue
            wall_plane_node2.physicsBody?.contactTestBitMask = bodytype.ball_player1.rawValue | bodytype.ball_player2.rawValue | bodytype.ball.rawValue | bodytype.ball_final.rawValue
            
            wall_plane_node3.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
            wall_plane_node3.physicsBody?.categoryBitMask    = bodytype.plane.rawValue
            wall_plane_node3.physicsBody?.collisionBitMask   = bodytype.ball_player1.rawValue | bodytype.ball_player2.rawValue | bodytype.ball.rawValue | bodytype.ball_final.rawValue
            wall_plane_node3.physicsBody?.contactTestBitMask = bodytype.ball_player1.rawValue | bodytype.ball_player2.rawValue | bodytype.ball.rawValue | bodytype.ball_final.rawValue
            
            wall_plane_node4.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
            wall_plane_node4.physicsBody?.categoryBitMask    = bodytype.plane.rawValue
            wall_plane_node4.physicsBody?.collisionBitMask   = bodytype.ball_player1.rawValue | bodytype.ball_player2.rawValue | bodytype.ball.rawValue | bodytype.ball_final.rawValue
            wall_plane_node4.physicsBody?.contactTestBitMask = bodytype.ball_player1.rawValue | bodytype.ball_player2.rawValue | bodytype.ball.rawValue | bodytype.ball_final.rawValue
            
            
            
            
            
            
            
            //sceneView.scene.rootNode.addChildNode(cube_node_1)
            sceneView.scene.rootNode.addChildNode(wall_plane_node1)
            sceneView.scene.rootNode.addChildNode(wall_plane_node2)
            sceneView.scene.rootNode.addChildNode(wall_plane_node3)
            sceneView.scene.rootNode.addChildNode(wall_plane_node4)
            sceneView.scene.rootNode.addChildNode(plane_top_node)
            sceneView.scene.rootNode.addChildNode(plane_ground_node)
            sceneView.scene.rootNode.addChildNode(goal_node_1)
            sceneView.scene.rootNode.addChildNode(goal_node_2)
            sceneView.scene.rootNode.addChildNode(goal_node_3)
            sceneView.scene.rootNode.addChildNode(goal_node_4)
            all_nodes.append(wall_plane_node1)
            all_nodes.append(wall_plane_node2)
            all_nodes.append(wall_plane_node3)
            all_nodes.append(wall_plane_node4)
            all_nodes.append(plane_top_node)
            all_nodes.append(plane_ground_node)
            all_nodes.append(goal_node_1)
            all_nodes.append(goal_node_2)
            all_nodes.append(goal_node_3)
            all_nodes.append(goal_node_4)
            
            if (host){
                is_turn = true
                create_ball_start(coordinates: coordinates, big_side: CGFloat(big_side))
            }
            else{
                is_turn = false
            }
            
        }
        
    }
    
    // MARK: Creates the balls at the start of the game
    func create_ball_start(coordinates: SCNVector3, big_side: CGFloat) {
        
        
        var postion_balls_1 = SCNVector3Make(coordinates.x + 0.04, coordinates.y + Float(big_side/2) , coordinates.z )
        var postion_balls_2 = SCNVector3Make(coordinates.x - 0.04, coordinates.y + Float(big_side/2) , coordinates.z )
        
        // red ball for player 1
        let sphere_p1 = SCNSphere(radius: 0.025)
        sphere_p1.materials.first?.diffuse.contents = UIColor.red
        let Sphere_Node_p1 = SCNNode(geometry: sphere_p1)
        
        Sphere_Node_p1.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        Sphere_Node_p1.physicsBody?.damping = 0.5
        Sphere_Node_p1.physicsBody?.isAffectedByGravity = false
        Sphere_Node_p1.position = postion_balls_1
        Sphere_Node_p1.name = "P1_ball"
        
        // physics body of the ball
        Sphere_Node_p1.physicsBody?.categoryBitMask    = bodytype.ball_player1.rawValue
        Sphere_Node_p1.physicsBody?.collisionBitMask   =
            bodytype.plane.rawValue | bodytype.ball.rawValue | bodytype.ball_player2.rawValue | bodytype.ball_final.rawValue
        Sphere_Node_p1.physicsBody?.contactTestBitMask =
            bodytype.plane.rawValue | bodytype.ball.rawValue | bodytype.ball_player2.rawValue | bodytype.ball_final.rawValue
        
        
        // purple ball for player 2
        let sphere_p2 = SCNSphere(radius: 0.025)
        sphere_p2.materials.first?.diffuse.contents = UIColor.purple
        let Sphere_Node_p2 = SCNNode(geometry: sphere_p2)
        
        Sphere_Node_p2.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        Sphere_Node_p1.physicsBody?.damping = 0.5
        Sphere_Node_p2.physicsBody?.isAffectedByGravity = false
        Sphere_Node_p2.position = postion_balls_2
        Sphere_Node_p2.name = "P2_ball"
        
        
        // physics body of the ball
        Sphere_Node_p2.physicsBody?.categoryBitMask    = bodytype.ball_player2.rawValue
        Sphere_Node_p2.physicsBody?.collisionBitMask   =
            bodytype.plane.rawValue | bodytype.ball.rawValue | bodytype.ball_player1.rawValue | bodytype.ball_final.rawValue

        Sphere_Node_p2.physicsBody?.contactTestBitMask =
            bodytype.plane.rawValue | bodytype.ball.rawValue | bodytype.ball_player1.rawValue | bodytype.ball_final.rawValue
        
        let sphere_final = SCNSphere(radius: 0.025)
        sphere_final.materials.first?.diffuse.contents = UIColor.white
        let Sphere_Node_final = SCNNode(geometry: sphere_final)
        Sphere_Node_final.name = "final_ball"
        
        Sphere_Node_final.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        Sphere_Node_final.physicsBody?.isAffectedByGravity = false
        Sphere_Node_final.position = SCNVector3Make(coordinates.x  , coordinates.y + Float(big_side/2), coordinates.z - 0.04)
        
        Sphere_Node_final.physicsBody?.categoryBitMask    = bodytype.ball_final.rawValue
        Sphere_Node_final.physicsBody?.collisionBitMask   =
            bodytype.plane.rawValue | bodytype.ball.rawValue | bodytype.ball_player1.rawValue | bodytype.ball_player2.rawValue
        Sphere_Node_final.physicsBody?.contactTestBitMask =
            bodytype.plane.rawValue | bodytype.ball.rawValue | bodytype.ball_player1.rawValue | bodytype.ball_player2.rawValue
        
        sceneView.scene.rootNode.addChildNode(Sphere_Node_p1)
        sceneView.scene.rootNode.addChildNode(Sphere_Node_p2)
        sceneView.scene.rootNode.addChildNode(Sphere_Node_final)
        all_nodes.append(Sphere_Node_p1)
        all_nodes.append(Sphere_Node_p2)
        all_nodes.append(Sphere_Node_final)
        ball_nodes.append(Sphere_Node_final)
        ball_nodes.append(Sphere_Node_p2)
        ball_nodes.append(Sphere_Node_p1)
        
        
        // can be probaby be done in a nested for loop but nah
        
        
        // copy the Sphere node var into a temp minipulate and then add to a list
        //player 1 balls
        var temp_pos_1 = postion_balls_1
        for times in 1...3 {
            var temp_sphere = Sphere_Node_p1.clone()
            temp_pos_1 = SCNVector3Make(temp_pos_1.x + 0.04, temp_pos_1.y , temp_pos_1.z + 0.04)
            temp_sphere.position = temp_pos_1
            sceneView.scene.rootNode.addChildNode(temp_sphere)
            all_nodes.append(temp_sphere)
            ball_nodes.append(temp_sphere)

        }
        
        
        // copy the Sphere node var into a temp minipulate and then add to a list
        // player 2 balls
        var temp_pos_2 = postion_balls_2
        for times in 1...3 {
            // copy the Sphere node var into a temp minipulate and then add to a list
            var temp_sphere = Sphere_Node_p2.clone()
            temp_pos_2 = SCNVector3Make(temp_pos_2.x - 0.04, temp_pos_2.y , temp_pos_2.z + 0.04)
            temp_sphere.position = temp_pos_2
            sceneView.scene.rootNode.addChildNode(temp_sphere)
            all_nodes.append(temp_sphere)
            ball_nodes.append(temp_sphere)
        }
        
      

        
    }
    
    // MARK: Rendering the planes using AR KIT
    // creates the first instacne of a plane
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        if(change_arena == true){
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
//            planeNode.physicsBody                        = SCNPhysicsBody(type: .static, shape: nil)
//            planeNode.physicsBody?.categoryBitMask       =  bodytype.plane.rawValue
//            planeNode.physicsBody?.collisionBitMask      =  bodytype.ball.rawValue
//            planeNode.physicsBody?.contactTestBitMask    =  bodytype.ball.rawValue
            
            
            node.addChildNode(planeNode)
            scanned_surfaces.append(node)
        }
        
        
    }

    
    
    
    
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        if(change_arena == true){
         guard let planeAnchor = anchor as? ARPlaneAnchor,
         var planeNode = node.childNodes.first,
         let planeGeometry = planeNode.geometry as? SCNPlane
         else { return }

        
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
        if (change_arena == true)
        {
            let shape = SCNPhysicsShape(geometry: geometry, options: nil)
            let physicsBody = SCNPhysicsBody(type: type, shape: shape)
            node.physicsBody = physicsBody
        }
    }
    
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        
    }
    
    
    
    // MARK: Ball Flinging
    
    // creates a ball from the camera postion and oriatnation with a velocity based on a swipe speed
    func FlingBall() {
        // total time of wipe
        if(is_turn){
            is_turn = false
            print("3")
            for  node in ball_nodes {
                print("Node vector from fling", SCNVector3Make(node.worldPosition.x - center_pos.x, node.worldPosition.y - center_pos.y, node.worldPosition.z - center_pos.z))
            }
            timer(6.0, completion: send_balls)
            check_first_collide = false
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
            Sphere_Node.name = "flung_ball"
            
            // physics body of the ball
            Sphere_Node.physicsBody?.categoryBitMask    = bodytype.ball.rawValue
            Sphere_Node.physicsBody?.collisionBitMask   = 0
            Sphere_Node.physicsBody?.contactTestBitMask = 1|3|4|5
            
            sceneView.scene.rootNode.addChildNode(Sphere_Node)
        }
        
        
    }
    
    // get rid of gravity make the height smaller try 1/4 imsted of 1/2
    
    func end_game()  {
        change_arena = true
        
        DispatchQueue.main.async {
            let  end_info = self.msg_recive.split(separator: ":", maxSplits: 8, omittingEmptySubsequences: true)
            let host_win = String(end_info[1])
            let display:String
            print(host_win)
            print(self.host)
            if(host_win == "true" && self.host){
                display = "YOU WIN!!!"
                i think one of the senerios ofr winning dosnt work so check it out 
            }
            else if(host_win == "false" && !self.host){
                display = "YOU WIN!!"
            }
            else{
                display = "YOU LOSE:("
            }
            let alert_thing = UIAlertController(title: display, message: "Game Over", preferredStyle: .alert)
            alert_thing.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { action in
            }))
            self.present(alert_thing, animated: true, completion: nil)
        }
        
        
        
        for node in all_nodes{
            node.removeFromParentNode()
        }
        for node in scanned_surfaces {
            node.isHidden = false
        }
//        for node in ball_nodes{
//            print(node.position)
//            print(node.name)
//        }
        var P1_score = 0
        var P2_score = 0
        all_nodes.removeAll()
        ball_nodes.removeAll()
        other_arenaX = nil
        other_arenaY = nil
        selected_node = nil
        
    }
    
    
    
    
    var host:Bool!
    var peerID  :MCPeerID!
    var session :MCSession!
    var advertiser_assistant  :MCAdvertiserAssistant!
    var msg_send:String!
    var msg_recive:String!
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        self.msg_recive = NSString(data: data as Data, encoding: String.Encoding.utf8.rawValue)! as String
        if(msg_recive.contains("plane_info")){
            let  other_arena_geo_vales = msg_recive.split(separator: ":", maxSplits: 8, omittingEmptySubsequences: true)
            other_arenaX = Double(other_arena_geo_vales[1])!
            other_arenaY = Double(other_arena_geo_vales[2])!
            if (selected_node != nil){
                game_arena_create(coordinates_to_lazy_to_remove: selected_node.worldPosition, node_passed: selected_node)
            }
        }
        else if(msg_recive.contains("Goal")){
         goal_set(MSG: msg_recive)
        }
        else if(msg_recive.contains("Balls")){
            rerender_balls(MSG: msg_recive)
        }
        else if(msg_recive.contains("remove_balls")){
            for node in ball_nodes {
                node.removeFromParentNode()
            }
        }
        else if(msg_recive.contains("turn_switch")){
            is_turn = true
        }
        else if(msg_recive.contains("winner_host")){
            end_game()
        }
        else if(msg_recive.contains("points")){
            points(point_info: msg_recive)
        }
        
    }
    
    func points(point_info: String) {
        let  point_stuff = msg_recive.split(separator: ":", maxSplits: 8, omittingEmptySubsequences: true)
        let add_poits = String(point_stuff[1])
        if (add_poits == "P1"){
            P1_score = P1_score + 1
        }
        else{
            P2_score = P2_score + 1
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        
    }
    
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true, completion: nil)
        
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func Host(_ sender: Any) {
        //print("host")
        host = true
        self.advertiser_assistant = MCAdvertiserAssistant(serviceType: "doesnt-matter", discoveryInfo: nil, session: self.session)
        self.advertiser_assistant.start()
    }
    
    @IBAction func Client(_ sender: Any) {
        //print("client")
        host = false
        let browser = MCBrowserViewController(serviceType: "doesnt-matter", session: self.session)
        browser.delegate = self
        self.present(browser, animated: true, completion: nil)
    }
    
    func goal_set(MSG: String) {
        let  Goal_info = msg_recive.split(separator: ":", maxSplits: 8, omittingEmptySubsequences: true)
        if (host){
            goal_x3 = Double(Goal_info[1])!
            goal_y3 = Double(Goal_info[2])!
            goal_height3 = Double(Goal_info[3])!
            goal_x4 = Double(Goal_info[4])!
            goal_y4 = Double(Goal_info[5])!
            goal_height4 = Double(Goal_info[6])!
        }
        else{
            goal_x1 = Double(Goal_info[1])!
            goal_y1 = Double(Goal_info[2])!
            goal_height1 = Double(Goal_info[3])!
            goal_x2 = Double(Goal_info[4])!
            goal_y2 = Double(Goal_info[5])!
            goal_height2 = Double(Goal_info[6])!
        }

    }
    
    func timer(_ seconds: Double, completion: @escaping () -> ()) {
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            completion()
        }

    }
    
    func send_balls()  {
        //print("HEllo im at the static ball thing ")
        msg_send = "remove_balls"
        var message = msg_send.data(using: String.Encoding.utf8, allowLossyConversion: false)

        do {
            try self.session.send(message!, toPeers: self.session.connectedPeers, with: .reliable)
        }
        catch{
            print("well that didnt work")
        }
        msg_send = "turn_switch"
        message = msg_send.data(using: String.Encoding.utf8, allowLossyConversion: false)

        do {
            try self.session.send(message!, toPeers: self.session.connectedPeers, with: .reliable)
        }
        catch{
            print("well that didnt work")
        }
        
        //print("DDFSFYDGUIHSDFGHIUGFHIUGFHIUUIHDFGIHUDFHIUUIHFDHFDHFDHU)DFHFDHOIFDHOIOIDFHIOFDHIOUFDIOHUIOFDHIOFDH")
        for  node in ball_nodes {
            //print( SCNVector3Make(node.worldPosition.x - center_pos.x, node.worldPosition.y - center_pos.y, node.worldPosition.z - center_pos.z))
        }
        for node in ball_nodes{
            var color:String!
            node.physicsBody?.type = .static
            if (node.name == "P1_ball") {
                color = "red"
            }
            else if(node.name == "P2_ball"){
                color = "purple"
            }
            else{
                color = "white"
            }
            
            
            
            //node.position = node.presentation.position
            msg_send = "Balls:" + String(format: "%f", (node.presentation.worldPosition.x - center_pos.x)) + ":" + String(format: "%f", (node.presentation.worldPosition.y - center_pos.y)) + ":" + String(format: "%f", (node.presentation.worldPosition.z - center_pos.z)) + ":" + color
            
            //print(node.presentation.worldPosition)
            //print(node.worldPosition.x - center_pos.x)
            print("message send" , msg_send)
            
            message = msg_send.data(using: String.Encoding.utf8, allowLossyConversion: false)

            do {
                try self.session.send(message!, toPeers: self.session.connectedPeers, with: .reliable)
                node.removeFromParentNode()
            }
            catch{
                print("well that didnt work")
            }
            
            
        }
        ball_nodes.removeAll()
//        msg_send = "remove_balls"
//        let message = msg_send.data(using: String.Encoding.utf8, allowLossyConversion: false)
//
//        do {
//            try self.session.send(message!, toPeers: self.session.connectedPeers, with: .reliable)
//        }
//        catch{
//            print("well that didnt work")
//        }
    }
    
    // i nened to find a way to erase the balls
    var have_got = false
    func rerender_balls(MSG: String) {
//        if (!have_got){
//            for node in ball_nodes{
//                node.removeFromParentNode()
//            }
//            ball_nodes.removeAll()
//        }
        
        let ball_info = MSG.split(separator: ":", maxSplits: 8, omittingEmptySubsequences: true)
        //print("test")
        print("1")
        print("message recived " ,MSG)
        var ball_x = Double(ball_info[1])!
        var ball_y = Double(ball_info[2])!
        var ball_z = Double(ball_info[3])!
        var colortmp = String(ball_info[4])
        var color:UIColor!
        if (colortmp == "purple"){
            color = UIColor.purple
        }
        else if (colortmp == "red"){
            color = UIColor.red
        }
        else{
            color = UIColor.white
        }
        balls(X: ball_x, Y: ball_y, Z: ball_z, Color: color)
        
    }
    
    func balls(X: Double, Y:Double, Z:Double, Color: UIColor){
        let sphere = SCNSphere(radius: 0.025)
        sphere.materials.first?.diffuse.contents = Color
        let temp_sphere = SCNNode(geometry: sphere)
        
        temp_sphere.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        temp_sphere.physicsBody?.damping = 0.5
        temp_sphere.physicsBody?.isAffectedByGravity = false
        print("2")
        print( "Values of ball created from math" , (center_pos.x + Float(X)), (center_pos.y + Float(Y)), (center_pos.z + Float(Z)))
        temp_sphere.position = SCNVector3Make(center_pos.x + Float(X), center_pos.y + Float(Y), center_pos.z + Float(Z))
        print("THE actual value fro, .worldpos", temp_sphere.worldPosition)
        
        
        
        // physics body of the ball
        if (Color == UIColor.red){
            temp_sphere.name = "P1_ball"
            temp_sphere.physicsBody?.categoryBitMask    = bodytype.ball_player1.rawValue
            temp_sphere.physicsBody?.collisionBitMask   =
                bodytype.plane.rawValue | bodytype.ball.rawValue | bodytype.ball_player2.rawValue | bodytype.ball_final.rawValue
            temp_sphere.physicsBody?.contactTestBitMask =
                bodytype.plane.rawValue | bodytype.ball.rawValue | bodytype.ball_player2.rawValue | bodytype.ball_final.rawValue
        }
        else if (Color == UIColor.purple){
            temp_sphere.name = "P2_ball"
            temp_sphere.physicsBody?.categoryBitMask    = bodytype.ball_player2.rawValue
            temp_sphere.physicsBody?.collisionBitMask   =
                bodytype.plane.rawValue | bodytype.ball.rawValue | bodytype.ball_player1.rawValue | bodytype.ball_final.rawValue

            temp_sphere.physicsBody?.contactTestBitMask =
                bodytype.plane.rawValue | bodytype.ball.rawValue | bodytype.ball_player1.rawValue | bodytype.ball_final.rawValue
        }
        
        else
        {
            temp_sphere.name = "final_ball"
            temp_sphere.physicsBody?.categoryBitMask    = bodytype.ball_final.rawValue
            temp_sphere.physicsBody?.collisionBitMask   =
                bodytype.plane.rawValue | bodytype.ball.rawValue | bodytype.ball_player1.rawValue | bodytype.ball_player2.rawValue
            temp_sphere.physicsBody?.contactTestBitMask =
                bodytype.plane.rawValue | bodytype.ball.rawValue | bodytype.ball_player1.rawValue | bodytype.ball_player2.rawValue
        }
        
        
        sceneView.scene.rootNode.addChildNode(temp_sphere)
        all_nodes.append(temp_sphere)
        ball_nodes.append(temp_sphere)
        print("HELLOOOOO?????")
        print("X", X ,"Y", Y, "Z", Z)
        print("Node vector from fling", SCNVector3Make(temp_sphere.worldPosition.x - center_pos.x, temp_sphere.worldPosition.y - center_pos.y, temp_sphere.worldPosition.z - center_pos.z))
    }
}


// send the coordiates for the goals with the plane
// this means 2 at a time for each player
