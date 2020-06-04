import Foundation
import TSCBasic
import TuistSupport
import TuistCore
import TuistAutomation
import RxBlocking

enum BuildServiceError: FatalError {
    
    case schemeNotFound(scheme: String, existing: [String])
    
    // Error description
    var description: String {
        switch self {
        case .schemeNotFound(let scheme, let existing):
            return "Couldn't find scheme \(scheme). The available schemes are: \(existing.joined(separator: ", "))"
        }
    }

    // Error type
    var type: ErrorType {
        switch self {
        case .schemeNotFound:
            return .abort
        }
    }
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
    
    func run(schemeName: String?) throws {
        let graph: Graph
        if shouldGenerateProject() {
            graph = try self.projectGenerator.generateWithGraph(path: FileHandler.shared.currentPath, projectOnly: false).1
        } else {
            graph = try self.projectGenerator.load(path: FileHandler.shared.currentPath)
        }
        
        let buildableSchemes = self.buildableSchemes(graph: graph)
        logger.log(level: .notice, "Found the following buildable schemes: \(buildableSchemes.map(\.name).joined(separator: ", "))")
        var cleaned: Bool = false
        
        func buildScheme(scheme: Scheme) throws {
            logger.log(level: .notice, "Building scheme \(scheme.name)", metadata: .section)
            let buildableTarget = self.buildableTarget(scheme: scheme, graph: graph)
            _ = try xcodebuildController.build(.workspace(workspacePath()!),
                                               scheme: scheme.name,
                                               clean: cleaned == false,
                                               arguments: [
                                                .sdk(buildableTarget.platform.xcodeSimulatorSDK!)
            ])
                .printFormattedOutput()
                .toBlocking()
                .last()
            cleaned = true
        }
        
        if let schemeName = schemeName {
            guard let scheme = buildableSchemes.first(where: { $0.name == schemeName }) else {
                throw BuildServiceError.schemeNotFound(scheme: schemeName, existing: buildableSchemes.map(\.name))
            }
            try buildScheme(scheme: scheme)
        } else {
            try buildableSchemes.forEach(buildScheme)
        }
        
        
        logger.log(level: .notice, "The project built successfully", metadata: .success)
    }
    
    // MARK: - Fileprivate
    
    fileprivate func buildableTarget(scheme: Scheme, graph: Graph) -> Target {
        let buildTarget = scheme.buildAction!.targets.first!
        return graph.target(path: buildTarget.projectPath, name: buildTarget.name)!.target
    }
    
    fileprivate func buildableSchemes(graph: Graph) -> [Scheme] {
        let projects = Set(graph.entryNodes.compactMap({ ($0 as? TargetNode)?.project }))
        return projects
            .flatMap({ $0.schemes })
            .filter({ $0.buildAction?.targets.count != 0 })
            .sorted(by: { $0.name < $1.name })
    }
    
    fileprivate func shouldGenerateProject() -> Bool {
        workspacePath() == nil
    }
    
    fileprivate func workspacePath() -> AbsolutePath? {
        FileHandler.shared.glob(FileHandler.shared.currentPath, glob: "*.xcworkspace").first
    }
    
}
