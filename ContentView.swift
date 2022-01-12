import PlaygroundSupport
import SwiftUI
import RealityKit
import ARKit

enum Shape: String, CaseIterable {
    case cube, sphere
}

//creating coordinator for ARView
class ARViewCoordinator: NSObject, ARSessionDelegate
{
    var arViewWrapper: ARViewWrapper
    @Binding var selectedShapeIndex: Int
    
    init(arViewWrapper: ARViewWrapper, selectedShapeIndex: Binding<Int>)
    {
        self.arViewWrapper = arViewWrapper        //this var to communicate with arViewWrapper
        self._selectedShapeIndex = selectedShapeIndex //initializing binding variable to prepending with _
    }
}

//ARViewWrapper is UIView representable
struct ARViewWrapper: UIViewRepresentable
{
    @Binding var selectedShapeIndex: Int    //constructor already auto created for this binding var
    
    typealias UIViewType = ARView
    
    //implementing makeCoordinator
    func makeCoordinator() -> (ARViewCoordinator) {
        return ARViewCoordinator(arViewWrapper: self, selectedShapeIndex: $selectedShapeIndex)
    }
    
    func makeUIView(context: UIViewRepresentableContext<ARViewWrapper>) -> ARView {
        let arView = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: true)
        
        //making AR Cube by creating model entity
        //model entity is ar object (needs mesh and material)
        //creating mesh & material:
        //let mesh = MeshResource.generateBox(size: 0.2)
        //let material = SimpleMaterial(color: .blue, roughness: 0.5, isMetallic: true)
        //let modelEntity = ModelEntity(mesh: mesh, materials: [material])
        //any ar object needs an anchor. Creating it:
        //let anchorEntity = AnchorEntity(plane: .horizontal)    //creating anchor on horz. plane
        //anchorEntity.addChild(modelEntity)
        
        //arView.scene.addAnchor(anchorEntity)
        
        arView.enablePlacement()
        arView.session.delegate = context.coordinator
        
        return arView 
    }
    
    func updateUIView(_ uiView: ARView, context: UIViewRepresentableContext<ARViewWrapper>) {
        
    }
}

//creating extension so you can choose where to place obj
extension ARView {
    func enablePlacement()
    {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(recognizer:)))
        
        //adding tap gesture recognizer
        self.addGestureRecognizer(tapGestureRecognizer)
    }
    
    //function to take in shape param and return a modelEntity
    func createModel(shape: Shape) -> ModelEntity
    {
        /* IF CASES FOR MORE THAN 2 SHAPES:
         if(mesh == shape == .cube)
         {
         MeshResource.generateBox(0.2)
         }
         
         if(mesh == shape == .sphere)
         {
         MeshResource.generateSphere(radius: 0.1)
         }*/
        
        let mesh = shape == .cube ? MeshResource.generateBox(size: 0.2) : MeshResource.generateSphere(radius: 0.1)
        let material = SimpleMaterial(color: .blue, roughness: 0.5, isMetallic: true)
        return ModelEntity(mesh: mesh, materials: [material])
    }
    
    @objc func handleTap(recognizer: UITapGestureRecognizer)
    {
        //get coordinator from delegate
        guard let coordinator = self.session.delegate as? ARViewCoordinator else {
            print("Error obtaining coordinator")
            return
        }
        
        let location = recognizer.location(in: self)
        
        //using ray cast, essentially pointing laser to point user taps
        let results = self.raycast(from: location, allowing: .estimatedPlane, alignment: .horizontal)
        
        //check if first result of raycast is horz surface
        if let firstResult = results.first {
            let selectedShape = Shape.allCases[coordinator.selectedShapeIndex]
            let modelEntity = createModel(shape: selectedShape)//ModelEntity(mesh: mesh, materials: [material])
            let anchorEntity = AnchorEntity(world: firstResult.worldTransform)
            anchorEntity.addChild(modelEntity)
            
            self.scene.addAnchor(anchorEntity)
        }
        else {
            //if no surface detected (possibly no lidar sensor)
            print("No surface detected - move device to new location")
        }
    }
}

struct ContentView: View {
    let objectShapes = Shape.allCases
    
    //creating state var for shapeIndex to cycle through shapes
    @State private var selectedShapeIndex = 0
    
    var body: some View
    {
        ZStack(alignment: .bottomTrailing) {
            ARViewWrapper(selectedShapeIndex: $selectedShapeIndex)
            
            //creating segmented picker
            Picker("Shapes", selection: $selectedShapeIndex) {
                //iterating through each shape to populate the picker
                //loop up to but not including objectShapes.count
                ForEach(0..<objectShapes.count) { index in
                    Text(self.objectShapes[index].rawValue).tag(index)
                }
            } .pickerStyle(SegmentedPickerStyle())
                .padding(10)
                .background(Color.black.opacity(0.5))    //50% opaque
        }
    }
}
