import Testing
@testable import Ultraviolence

struct StructuralIdentifierTests {
    struct TestElement1: Element {
        var body: some Element { EmptyElement() }
    }
    
    struct TestElement2: Element {
        var body: some Element { EmptyElement() }
    }
    
    @Test
    func testElementTypeIdentifier() {
        let id1 = ElementTypeIdentifier(TestElement1.self)
        let id2 = ElementTypeIdentifier(TestElement1.self)
        let id3 = ElementTypeIdentifier(TestElement2.self)
        
        #expect(id1 == id2)
        #expect(id1 != id3)
        #expect(id1.hashValue == id2.hashValue)
        #expect(id1.hashValue != id3.hashValue)
    }
    
    @Test
    func testAtomCreation() {
        let typeId = ElementTypeIdentifier(TestElement1.self)
        let atom1 = StructuralIdentifier.Atom(typeIdentifier: typeId, index: 0)
        let atom2 = StructuralIdentifier.Atom(typeIdentifier: typeId, explicit: "custom")
        
        #expect(atom1.typeIdentifier == typeId)
        #expect(atom1.index == 0)
        #expect(atom1.explicit == nil)
        
        #expect(atom2.typeIdentifier == typeId)
        #expect(atom2.index == nil)
        #expect(atom2.explicit as? String == "custom")
    }
    
    @Test
    func testAtomEquality() {
        let typeId1 = ElementTypeIdentifier(TestElement1.self)
        let typeId2 = ElementTypeIdentifier(TestElement2.self)
        
        let atom1 = StructuralIdentifier.Atom(typeIdentifier: typeId1, index: 0)
        let atom2 = StructuralIdentifier.Atom(typeIdentifier: typeId1, index: 0)
        let atom3 = StructuralIdentifier.Atom(typeIdentifier: typeId1, index: 1)
        let atom4 = StructuralIdentifier.Atom(typeIdentifier: typeId2, index: 0)
        let atom5 = StructuralIdentifier.Atom(typeIdentifier: typeId1, explicit: "a")
        let atom6 = StructuralIdentifier.Atom(typeIdentifier: typeId1, explicit: "b")
        
        #expect(atom1 == atom2)
        #expect(atom1 != atom3)
        #expect(atom1 != atom4)
        #expect(atom1 != atom5)
        #expect(atom5 != atom6)
    }
    
    @Test
    func testStructuralIdentifierCreation() {
        let typeId = ElementTypeIdentifier(TestElement1.self)
        let atom1 = StructuralIdentifier.Atom(typeIdentifier: typeId, index: 0)
        let atom2 = StructuralIdentifier.Atom(typeIdentifier: typeId, index: 1)
        
        let identity = StructuralIdentifier(atoms: [atom1, atom2])
        
        #expect(identity.atoms.count == 2)
        #expect(identity.atoms[0] == atom1)
        #expect(identity.atoms[1] == atom2)
    }
    
    @Test
    func testStructuralIdentifierAppending() {
        let typeId1 = ElementTypeIdentifier(TestElement1.self)
        let typeId2 = ElementTypeIdentifier(TestElement2.self)
        
        let atom1 = StructuralIdentifier.Atom(typeIdentifier: typeId1, index: 0)
        let atom2 = StructuralIdentifier.Atom(typeIdentifier: typeId2, index: 0)
        
        let identity1 = StructuralIdentifier(atoms: [atom1])
        let identity2 = identity1.appending(atom2)
        
        #expect(identity1.atoms.count == 1)
        #expect(identity2.atoms.count == 2)
        #expect(identity2.atoms[0] == atom1)
        #expect(identity2.atoms[1] == atom2)
        
        // Verify original identity is unchanged
        #expect(identity1.atoms.count == 1)
    }
    
    @Test
    func testStructuralIdentifierEquality() {
        let typeId = ElementTypeIdentifier(TestElement1.self)
        let atom1 = StructuralIdentifier.Atom(typeIdentifier: typeId, index: 0)
        let atom2 = StructuralIdentifier.Atom(typeIdentifier: typeId, index: 1)
        
        let identity1 = StructuralIdentifier(atoms: [atom1, atom2])
        let identity2 = StructuralIdentifier(atoms: [atom1, atom2])
        let identity3 = StructuralIdentifier(atoms: [atom2, atom1]) // Different order
        let identity4 = StructuralIdentifier(atoms: [atom1])
        
        #expect(identity1 == identity2)
        #expect(identity1 != identity3)
        #expect(identity1 != identity4)
        #expect(identity1.hashValue == identity2.hashValue)
    }
    
    @Test
    func testEmptyStructuralIdentifier() {
        let identity = StructuralIdentifier(atoms: [])
        #expect(identity.atoms.isEmpty)
        
        let typeId = ElementTypeIdentifier(TestElement1.self)
        let atom = StructuralIdentifier.Atom(typeIdentifier: typeId, index: 0)
        let newIdentity = identity.appending(atom)
        
        #expect(newIdentity.atoms.count == 1)
        #expect(newIdentity.atoms[0] == atom)
    }
    
    @Test
    func testExplicitIdentifierInAtom() {
        let typeId = ElementTypeIdentifier(TestElement1.self)
        
        let atom1 = StructuralIdentifier.Atom(typeIdentifier: typeId, explicit: 42)
        let atom2 = StructuralIdentifier.Atom(typeIdentifier: typeId, explicit: 42)
        let atom3 = StructuralIdentifier.Atom(typeIdentifier: typeId, explicit: 43)
        
        #expect(atom1 == atom2)
        #expect(atom1 != atom3)
        #expect(atom1.explicit as? Int == 42)
    }
    
    @Test
    func testComplexHierarchy() {
        let rootType = ElementTypeIdentifier(TestElement1.self)
        let childType = ElementTypeIdentifier(TestElement2.self)
        
        let rootAtom = StructuralIdentifier.Atom(typeIdentifier: rootType, index: 0)
        let child1Atom = StructuralIdentifier.Atom(typeIdentifier: childType, index: 0)
        let child2Atom = StructuralIdentifier.Atom(typeIdentifier: childType, index: 1)
        
        let rootIdentity = StructuralIdentifier(atoms: [rootAtom])
        let child1Identity = rootIdentity.appending(child1Atom)
        let child2Identity = rootIdentity.appending(child2Atom)
        
        #expect(child1Identity != child2Identity)
        #expect(child1Identity.atoms.count == 2)
        #expect(child2Identity.atoms.count == 2)
        #expect(child1Identity.atoms[0] == rootAtom)
        #expect(child2Identity.atoms[0] == rootAtom)
        #expect(child1Identity.atoms[1].index == 0)
        #expect(child2Identity.atoms[1].index == 1)
    }
}
