import Foundation
import TSCBasic
import TuistSupport
import TuistCore
import TuistAutomation
import RxBlocking

enum TestServiceError: FatalError {
    
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

final class TestService {
    
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
        
        let testableSchemes = self.testableSchemes(graph: graph)
        logger.log(level: .notice, "Found the following testable schemes: \(testableSchemes.map(\.name).joined(separator: ", "))")
        var cleaned: Bool = false
        
        func testScheme(scheme: Scheme) throws {
            logger.log(level: .notice, "Testing scheme \(scheme.name)", metadata: .section)
            let tesatbleTarget = self.testableTarget(scheme: scheme, graph: graph)
            _ = try xcodebuildController.test(.workspace(workspacePath()!),
                                               scheme: scheme.name,
                                               clean: cleaned == false,
                                               arguments: [
                                                .sdk(tesatbleTarget.platform.xcodeSimulatorSDK!)
            ])
                .printFormattedOutput()
                .toBlocking()
                .last()
            cleaned = true
        }
        
        if let schemeName = schemeName {
            guard let scheme = testableSchemes.first(where: { $0.name == schemeName }) else {
                throw TestServiceError.schemeNotFound(scheme: schemeName, existing: testableSchemes.map(\.name))
            }
            try testScheme(scheme: scheme)
        } else {
            try testableSchemes.forEach(testScheme)
        }
        
        
        logger.log(level: .notice, "The project tests ran successfully", metadata: .success)
    }
    
    // MARK: - Fileprivate
    
    fileprivate func testableTarget(scheme: Scheme, graph: Graph) -> Target {
        let target = scheme.testAction!.targets.first!.target
        return graph.target(path: target.projectPath, name: target.name)!.target
    }
    
    fileprivate func testableSchemes(graph: Graph) -> [Scheme] {
        let projects = Set(graph.entryNodes.compactMap({ ($0 as? TargetNode)?.project }))
        return projects
            .flatMap({ $0.schemes })
            .filter({ $0.testAction?.targets.count != 0 })
            .sorted(by: { $0.name < $1.name })
    }
    
    fileprivate func shouldGenerateProject() -> Bool {
        workspacePath() == nil
    }
    
    fileprivate func workspacePath() -> AbsolutePath? {
        FileHandler.shared.glob(FileHandler.shared.currentPath, glob: "*.xcworkspace").first
    }
    
}
