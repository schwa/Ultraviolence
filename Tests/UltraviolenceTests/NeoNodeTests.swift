import Foundation
@testable import Ultraviolence
import Testing

@MainActor
struct NeoNodeTests {
    
    @Test
    func testParentIdentifierIsSet() async throws {
        struct Parent: Element {
            var body: some Element {
                Child()
            }
        }
        
        struct Child: Element {
            var body: some Element {
                GrandChild()
            }
        }
        
        struct GrandChild: Element {
            var body: some Element {
                EmptyElement()
            }
        }
        
        let system = System()
        let root = Parent()
        
        try system.update(root: root)
        
        // Root should have no parent
        let rootNode = system.nodes[system.orderedIdentifiers[0]]
        #expect(rootNode?.parentIdentifier == nil)
        
        // Child should have root as parent
        let childNode = system.nodes[system.orderedIdentifiers[1]]
        #expect(childNode?.parentIdentifier == system.orderedIdentifiers[0])
        
        // GrandChild should have child as parent
        let grandChildNode = system.nodes[system.orderedIdentifiers[2]]
        #expect(grandChildNode?.parentIdentifier == system.orderedIdentifiers[1])
        
        // EmptyElement should have grandchild as parent
        let emptyNode = system.nodes[system.orderedIdentifiers[3]]
        #expect(emptyNode?.parentIdentifier == system.orderedIdentifiers[2])
    }
}