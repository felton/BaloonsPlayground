//: Playground - noun: a place where people can play

import SpriteKit
import XCPlayground

let sceneView = SKView(frame: CGRect(x: 0, y: 0, width: 850, height: 638))
let scene = SKScene(fileNamed: "GameScene")!
scene.scaleMode = .AspectFill
sceneView.presentScene(scene)

XCPlaygroundPage.currentPage.liveView = sceneView

/*:
 * experiment:
  Because gravity is defined by the scene’s physics world (its `physicsWorld` property), in the the world of SpriteKit laws of physics can be altered!
  \
Turn the gravity upside down by changing the `scene.physicsWorld.gravity` vector. Hint: Invert the sign of the vector's `dy` component.
 
 To actually see the content of a scene in a playground, we assign `sceneView` to the `liveView` of the currentPage of the playground. This renders the view live in the timeline editor so that the game is visible. From this point on, every change you make will be rendered live and be visible in the timeline editor.

### Firing the Cannons
 
 When the cannons fire, let’s add a balloon and move it across the scene. The balloons are sprite nodes, and we'll give each balloon a texture with a random element from our collection of balloon images.
 Here, we use the map function of Swift arrays to create an array of `SKTexture` objects from an array of image names. With our array of textures, we can simply generate a random index within its range and then create a sprite node with the texture at that index.
 */

let images = [
    "blue", "heart-blue", "star-blue",
    "green", "star-green", "heart-pink",
    "heart-red", "orange", "red",
    "star-gold", "star-pink", "star-red",
    "yellow"
]
let textures: [SKTexture] = images.map { SKTexture(imageNamed: "balloon-\($0)") }

var configureBalloonPhysics: ((balloon: SKSpriteNode) -> Void)?
func createRandomBalloon() -> SKSpriteNode {
    let choice = Int(arc4random_uniform(UInt32(textures.count)))
    let balloon = SKSpriteNode(texture: textures[choice])
    configureBalloonPhysics?(balloon: balloon)
    
    return balloon
}
/*:
 * experiment:
 You can add elements to the timeline by clicking the circle to the right of a line of code. This allows you to inspect the elements further.
 \
Add the array of textures to the timeline. You may need to scroll down in the timeline to see it.

 Now that we’ve created the balloon, let’s make sure it can be moved across the screen. We do this by giving it a physics body. When simulating physics, nodes without physics bodies are not considered.
 In SpriteKit, a physics body can be assigned up to 32 different categories. You use categories to separate nodes from each other. Note that we assign the balloon category to the contact test bit mask. This causes collisions between two nodes to trigger a notification.
 */

let BalloonCategory: UInt32 = 1 << 1
configureBalloonPhysics = { balloon in
    balloon.physicsBody = SKPhysicsBody(texture: balloon.texture!, size: balloon.size)
    balloon.physicsBody!.linearDamping = 0.5
    balloon.physicsBody!.mass = 0.1
    balloon.physicsBody!.categoryBitMask = BalloonCategory
    balloon.physicsBody!.contactTestBitMask = BalloonCategory
}
/*:
 * experiment:
 Remove the line that assigns the `BalloonCategory` to the `contactTestBitMask`. What happens?
 
 Modifying physics body properties is a great way to experiment, because of the immediate visual feedback that live rendering in playgrounds provides. Plus, you can inspect and debug your scenes on the spot.
 
 * experiment:
 Try to significantly increase or decrease the `mass` and `linearDamping` properties of the physics body. How does that affect the balloons? Change other physics body properties, too.
 
 We still need to position the balloon and add it to the scene. We want balloons to be fired from the mouth of the cannons.
 */

let displayBalloon: (SKSpriteNode, SKNode) -> Void = { balloon, cannon in
    balloon.position = cannon.childNodeWithName("mouth")!.convertPoint(CGPointZero, toNode: scene)
    scene.addChild(balloon)
}
/*:
 Notice that we determined the position of the balloon by asking for at child node named mouth. That’s possible because we explicitly added a node named mouth as a child of each cannon to define where the balloon should appear. This approach freed us from having to calculate the position, and if we wanted to reposition where the balloons first appear, we could do that directly in Xcode, without changing the code.
 To actually fire the balloon, we apply an impulse to its physics body to move it across the scene. An impulse is an instantaneous change to the body’s velocity. By applying an impulse to a body, SpriteKit pushes it in the direction specified (by an impulse vector). We’ve based the direction on the rotation of the firing cannon.
 Finally, we wrap creation, displaying, and firing of a balloon in a single function that we can call later.
 */
let fireBalloon: (SKSpriteNode, SKNode) -> Void = { balloon, cannon in
    let impulseMagnitude: CGFloat = 70.0
    
    let xComponent = cos(cannon.zRotation) * impulseMagnitude
    let yComponent = sin(cannon.zRotation) * impulseMagnitude
    let impulseVector = CGVector(dx: xComponent, dy: yComponent)
    
    balloon.physicsBody!.applyImpulse(impulseVector)
}

func fireCannon(cannon: SKNode) {
    let balloon = createRandomBalloon()
    
    displayBalloon(balloon, cannon)
    fireBalloon(balloon, cannon)
}
/*:
 To offer easy access to the cannon nodes, we named these nodes explicitly in Xcode’s Level Designer. As a result, we don’t need special knowledge of the tree’s organization or of the cannon nodes’ location. The cannons could even be repositioned without requiring any code changes.
 */
let leftBalloonCannon = scene.childNodeWithName("//left_cannon")!
let rightBalloonCannon = scene.childNodeWithName("//right_cannon")!
/*:
 SpriteKit executes SKAction objects on nodes to change their position, rotation, scale—or in our case to wait (that is, do nothing for a specified amount of time). You can execute an action standalone, in a sequence, or in a group, and you can automatically repeat it an arbitrary number of times (or forever). But actions do not necessarily change a node’s properties—an action can simply be a block of code to be executed.
 */
let wait = SKAction.waitForDuration(1.0, withRange: 0.05)
let pause = SKAction.waitForDuration(0.55, withRange: 0.05)

let left = SKAction.runBlock { fireCannon(leftBalloonCannon) }
let right = SKAction.runBlock { fireCannon(rightBalloonCannon) }

let leftFire = SKAction.sequence([wait, left, pause, left, pause, left, wait])
let rightFire = SKAction.sequence([pause, right, pause, right, pause, right, wait])
/*:
 To fire the cannons, we’ve created a sequence of actions that alternates between waiting and firing. We embed the fire/wait sequence in another action, one that is repeated forever.
 
 * experiment:
 Increase the cannons’ fire interval, change the power with which the cannons fire, and then make the cannons fire without pauses
 
 To execute an action on a node, we simply call its `runAction` function and pass it the action of interest. Multiple actions can be executed simultaneously by a node, making it easy to implement complex, custom behavior in SpriteKit.
 */
leftBalloonCannon.runAction(SKAction.repeatActionForever(leftFire))
rightBalloonCannon.runAction(SKAction.repeatActionForever(rightFire))
/*:
 * experiment:
 The `rotateByAngle` class function of `SKAction` gives you an action that rotates the executing node by a number of degrees (in radians).
 \
Create and run actions that make the cannons rotate while they are shooting.
 ### Popping Balloons
 
 When two balloons collide, we want to make one of them explode. The explosion effect can be created with actions, so this time we’ve used actions to create an animation from textures and to remove the executing node from the scene. These two actions are combined into one sequence action that runs the two actions one after the other.
 */
let balloonPop = (1...4).map {
    SKTexture(imageNamed: "explode_0\($0)")
}

let removeBalloonAction: SKAction = SKAction.sequence([
    SKAction.animateWithTextures(balloonPop, timePerFrame: 1 / 30.0),
    SKAction.removeFromParent()
    ])
/*:
 Even though collisions between physics bodies in a scene are automatically handled by SpriteKit, we must provide any logic that’s specific to our game. This includes defining which collisions should trigger contact notifications (contact testing). Earlier we ensured that all balloons are of the balloon category, but the ground is also a node and the category of a node defaults to all categories (`0xFFFFFFFF`).
 */
let GroundCategory: UInt32 = 1 << 2
let ground = scene.childNodeWithName("//ground")!
ground.physicsBody!.categoryBitMask = GroundCategory
/*:
 * experiment:
 Don’t assign the ground node a category (do this by commenting out the above three lines of code). What happens when balloons hit the ground now?
 
 Contact notifications are handled by the physics world’s contact delegate. This is a class that conforms to the `SKPhysicsContactDelegate` protocol. Whenever collisions occur, the physics world notifies its contact delegate (an instance of a class conforming to the `SKPhysicsContactDelegate` protocol), so that we can react appropriately to the collision.
 */
class PhysicsContactDelegate: NSObject, SKPhysicsContactDelegate {
    func didBeginContact(contact: SKPhysicsContact) {
        let categoryA = contact.bodyA.categoryBitMask
        let categoryB = contact.bodyB.categoryBitMask
        
        if (categoryA & BalloonCategory != 0) && (categoryB & BalloonCategory != 0) {
            contact.bodyA.node!.runAction(removeBalloonAction)
        }
    }
}

let contactDelegate = PhysicsContactDelegate()
scene.physicsWorld.contactDelegate = contactDelegate
/*:
 In the contact delegate’s `didBeginContact` function, we make use of the physics bodies’ category bit masks to ensure that only collisions between balloon nodes trigger explosions (that is, nodes of the `BalloonCategory`.). We use the bitwise AND operator to determine whether both bodies are of `BalloonCategory`, and run the action only if they are.
 
 * experiment:
 Enable collisions between cannons and balloons.
 \
Hint: The cannon nodes don’t have a physics body.
 
 ### And finally...
 
 Playgrounds provide you with a way to experiment with your code that is interactive and fun. Playgrounds are also rewarding, because you learn by doing and by making mistakes in a controlled environment. More important, they challenge your curiosity and encourage you to play with and test your code while writing it.
 Have fun! Change the code, experiment, and don’t be afraid to start over.
 */
