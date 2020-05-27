import Foundation
import TSCBasic

public final class GraphTraverser: GraphTraversing {
    
    private let graph: Graph
    
    public init(graph: Graph) {
        self.graph = graph
    }
    
    public func staticDependencies(path: AbsolutePath, name: String) -> [GraphDependencyReference] {
        return graph.staticDependencies(path: path, name: name)
    }
    
}
