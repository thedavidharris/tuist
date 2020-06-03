import Foundation
import TSCBasic
import TuistSupport
import TuistCore
import TuistAutomation
import RxBlocking

enum BuildServiceError: FatalError {
    // Error description
    var description: String {
        ""
    }

    // Error type
    var type: ErrorType { .abort }
}

final class BuildService {
    
    /// Project generator
    let projectGenerator: ProjectGenerating
    
    /// Xcode build controller.
    let xcodebuildController: XcodeBuildControlling
    
    init(projectGenerator: ProjectGenerating = ProjectGenerator(),
         xcodebuildController: XcodeBuildControlling = XcodeBuildController()) {
        self.projectGenerator = projectGenerator
        self.xcodebuildController = xcodebuildController
    }
    
    func run(scheme: String?) throws {
        let graph: Graph
        if shouldGenerateProject() {
            graph = try self.projectGenerator.generateWithGraph(path: FileHandler.shared.currentPath, projectOnly: false).1
        } else {
            graph = try self.projectGenerator.load(path: FileHandler.shared.currentPath)
        }
        
        let buildableSchemes = self.buildableSchemes(graph: graph)
        logger.log(level: .notice, "Found the following buildable schemes: \(buildableSchemes.map(\.name).joined(separator: ", "))")
        var cleaned: Bool = false
        
        try buildableSchemes.forEach { (scheme) in
            logger.log(level: .notice, "Building scheme \(scheme.name)", metadata: .section)
            _ = try xcodebuildController.build(.workspace(workspacePath()!),
                                           scheme: scheme.name,
                                           clean: cleaned == false,
                                           arguments: [])
                .printFormattedOutput()
                .toBlocking()
                .last()
            cleaned = true
            
        }
    }
    
    // MARK: - Fileprivate
    
    fileprivate func buildableSchemes(graph: Graph) -> [Scheme] {
        let projects = Set(graph.entryNodes.compactMap({ ($0 as? TargetNode)?.project }))
        return projects
            .flatMap({ $0.schemes })
            .filter({ $0.buildAction?.targets.count != 0 })
    }
    
    fileprivate func shouldGenerateProject() -> Bool {
        workspacePath() != nil
    }
    
    fileprivate func workspacePath() -> AbsolutePath? {
        FileHandler.shared.glob(FileHandler.shared.currentPath, glob: "*.xcworkspace").first
    }
    
}
