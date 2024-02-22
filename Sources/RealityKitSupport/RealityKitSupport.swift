import RealityKit
import SwiftUI

#if os(visionOS)
public extension RealityViewContent {
    func firstEntity(where test: (Entity) throws -> Bool) rethrows -> Entity? {
        for child in entities {
            if try test(child) {
                return child
            }
            if let result = try child.first(where: test) {
                return result
            }
        }
        return nil
    }
    
    func firstEntity(named name: String) -> Entity? {
        return firstEntity(where: { $0.name == name })
    }
}
#endif

#if !os(visionOS)
public extension RealityKit.Scene {
    func findEntity(id: Entity.ID) -> Entity? {
        for anchor in anchors {
            if let result = anchor.findEntity(id: id) {
                return result
            }
        }
        return nil
    }
}
#endif

public extension Entity {
    convenience init(name: String? = nil, children: [Entity]) {
        self.init()
        if let name {
            self.name = name
        }
        for child in children {
            self.addChild(child)
        }
    }

    convenience init(name: String? = nil, children: [Entity] = [], components: [any Component]) {
        self.init()
        if let name {
            self.name = name
        }
        for child in children {
            self.addChild(child)
        }
        for component in components {
            self.components[type(of: component)] = component
        }
    }
}

public extension ModelEntity {
    convenience init(name: String, mesh: MeshResource, materials: [any RealityKit.Material]) {
        self.init(mesh: mesh, materials: materials)
        self.name = name
    }
    
    convenience init(name: String? = nil, children: [Entity] = [], components: [any Component], mesh: MeshResource, materials: [any RealityKit.Material]) {
        self.init(mesh: mesh, materials: materials)
        if let name {
            self.name = name
        }
        for child in children {
            self.addChild(child)
        }
        for component in components {
            self.components[type(of: component)] = component
        }
    }

}

public extension Entity {
    func findEntity(id: Entity.ID) -> Entity? {
        if self.id == id {
            return self
        }
        for child in children {
            if let result = child.findEntity(id: id) {
                return result
            }
        }
        return nil
    }

    func first(where test: (Entity) throws -> Bool) rethrows -> Entity? {
        if try test(self) {
            return self
        }
        for child in children {
            if try test(child) {
                return child
            }
            if let result = try child.first(where: test) {
                return result
            }
        }
        return nil
    }
    
    func first(named name: String) -> Entity? {
        first(where: { $0.name == name })
    }

    func child(named name: String) -> Entity? {
        children.first(where: { $0.name == name })
    }
}

public extension Entity {
    var ancestors: [Entity] {
        guard let parent else {
            return []
        }
        return parent.ancestors + [parent]
    }
}

public extension Entity {
    var path: [String] {
        ancestors.map { $0.name }
    }

    func descendent <C>(at path: C) -> Entity? where C: Collection, C.Element == String {
        if let firstName = path.first, let descendent = child(named: firstName) {
            let remaining = path.dropFirst()
            if remaining.isEmpty {
                return descendent
            }
            else {
                return descendent.descendent(at: remaining)
            }
        }
        return nil
    }

    func scaleToFit(_ box: BoundingBox) {
        let currentBox = visualBounds(relativeTo: nil)
        let scaleVector = box.extents / currentBox.extents
        let fittedScale = min(scaleVector.x, min(scaleVector.y, scaleVector.z))
        scale = [fittedScale, fittedScale, fittedScale]
    }
    
    var areAllEntitiesNamed: Bool {
        first(where: { $0.name == "" }) == nil
    }
}

public extension Entity {
    var onlyChild: Entity? {
        get {
            guard children.count == 1 else {
                return nil
            }
            return children.first
        }
    }

    @discardableResult
    func replaceOnlyChild(with newOnlyChild: Entity) -> Bool {
        let result = removeOnlyChild()
        addChild(newOnlyChild)
        return result
    }

    @discardableResult
    func removeOnlyChild() -> Bool {
        if let onlyChild {
            removeChild(onlyChild)
            return true
        }
        else {
            return false
        }
    }
}

public extension Entity {
    func addChildAtop(_ child: Entity) {
        let visualBounds = visualBounds(recursive: true, relativeTo: nil, excludeInactive: false)
        let maxY = visualBounds.isFinite ? visualBounds.max.y : 0
        let childVisualBounds = child.visualBounds(recursive: true, relativeTo: nil, excludeInactive: false)
        let childHeight = childVisualBounds.isFinite ? childVisualBounds.extents.y : 0
        let y = maxY + childHeight / 2
        child.position.y = y
        addChild(child)
    }
}


//extension Entity {
//    func dumpVerticalModels() {
////        var modelEntities: [Entity] = []
//        walk { entity, depth in
//            let bounds = entity.visualBounds(relativeTo: nil)
//            let padding = repeatElement("  ", count: depth).joined()
//            print("\(padding)\(type(of: entity)): \(entity.name) - MINY: \(bounds.min.y.formatted()) HEIGHT: \(bounds.extents.y.formatted())")
//        }
//        
////        modelEntities = modelEntities.sorted { lhs, rhs in
////            let lhs = lhs.visualBounds(relativeTo: nil)
////            let rhs = rhs.visualBounds(relativeTo: nil)
////            return lhs.min.y < rhs.min.y
////        }
////
////        modelEntities.forEach {
////            let bounds = $0.visualBounds(relativeTo: nil)
////            print("\(type(of: $0)): \($0.name) - Y: \(bounds.min.y.formatted()) HEIGHT: \(bounds.extents.y.formatted())")
////        
////        }
//    }
//
//    func walk(depth: Int = 0, visitor: (Entity, Int) -> Void) {
//        visitor(self, depth)
//        let depth = depth + 1
//        for child in children {
//            child.walk(depth: depth, visitor: visitor)
//        }
//    }
//}

public extension BoundingBox {
    var isFinite: Bool {
        return min.x.isFinite && min.y.isFinite && min.z.isFinite && max.x.isFinite && max.y.isFinite && max.z.isFinite
    }
}
