import Foundation
import TSCBasic

public protocol GraphTraversing {
    func staticDependencies(path: AbsolutePath, name: String) -> [GraphDependencyReference]
}
