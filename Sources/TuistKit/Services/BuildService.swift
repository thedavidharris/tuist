import Foundation
import RxBlocking
import TSCBasic
import TuistAutomation
import TuistCore
import TuistSupport

enum BuildServiceError: FatalError {
    case schemeNotFound(scheme: String, existing: [String])

    // Error description
    var description: String {
        switch self {
        case let .schemeNotFound(scheme, existing):
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

    /// Build graph inspector.
    let buildGraphInspector: BuildGraphInspecting

    init(projectGenerator: ProjectGenerating = ProjectGenerator(),
         xcodebuildController: XcodeBuildControlling = XcodeBuildController(),
         buildGraphInspector: BuildGraphInspecting = BuildGraphInspector()) {
        self.projectGenerator = projectGenerator
        self.xcodebuildController = xcodebuildController
        self.buildGraphInspector = buildGraphInspector
    }

    func run(schemeName: String?, generate: Bool) throws {
        let graph: Graph
        if generate || buildGraphInspector.workspacePath(directory: FileHandler.shared.currentPath) == nil {
            graph = try projectGenerator.generateWithGraph(path: FileHandler.shared.currentPath, projectOnly: false).1
        } else {
            graph = try projectGenerator.load(path: FileHandler.shared.currentPath)
        }

        let buildableSchemes = buildGraphInspector.buildableSchemes(graph: graph)
        logger.log(level: .notice, "Found the following buildable schemes: \(buildableSchemes.map(\.name).joined(separator: ", "))")
        var cleaned: Bool = false

        func buildScheme(scheme: Scheme) throws {
            logger.log(level: .notice, "Building scheme \(scheme.name)", metadata: .section)
            let buildableTarget = buildGraphInspector.buildableTarget(scheme: scheme, graph: graph)
            let workspacePath = buildGraphInspector.workspacePath(directory: FileHandler.shared.currentPath)!
            _ = try xcodebuildController.build(.workspace(workspacePath),
                                               scheme: scheme.name,
                                               clean: cleaned == false,
                                               arguments: buildGraphInspector.buildArguments(target: buildableTarget))
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
}
