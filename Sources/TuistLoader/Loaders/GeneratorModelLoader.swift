import Foundation
import ProjectDescription
import TSCBasic
import TuistCore
import TuistSupport

public class GeneratorModelLoader {
    private let manifestLoader: ManifestLoading
    private let manifestLinter: ManifestLinting
    private let rootDirectoryLocator: RootDirectoryLocating

    public convenience init(manifestLoader: ManifestLoading,
                            manifestLinter: ManifestLinting) {
        self.init(manifestLoader: manifestLoader,
                  manifestLinter: manifestLinter,
                  rootDirectoryLocator: RootDirectoryLocator())
    }

    init(manifestLoader: ManifestLoading,
         manifestLinter: ManifestLinting,
         rootDirectoryLocator: RootDirectoryLocating) {
        self.manifestLoader = manifestLoader
        self.manifestLinter = manifestLinter
        self.rootDirectoryLocator = rootDirectoryLocator
    }
}

extension GeneratorModelLoader: GeneratorModelLoading {
    /// Load a Project model at the specified path
    ///
    /// - Parameters:
    ///   - path: The absolute path for the project model to load.
    /// - Returns: The Project loaded from the specified path
    /// - Throws: Error encountered during the loading process (e.g. Missing project)
    public func loadProject(at path: AbsolutePath) throws -> TuistCore.Project {
        let manifest = try manifestLoader.loadProject(at: path)
        try manifestLinter.lint(project: manifest).printAndThrowIfNeeded()
        return try convert(manifest: manifest, path: path)
    }

    public func loadWorkspace(at path: AbsolutePath) throws -> TuistCore.Workspace {
        let manifest = try manifestLoader.loadWorkspace(at: path)
        return try convert(manifest: manifest, path: path)
    }

    public func loadConfig(at path: AbsolutePath) throws -> TuistCore.Config {
        // If the Config.swift file exists in the root Tuist/ directory, we load it from there
        if let rootDirectoryPath = rootDirectoryLocator.locate(from: path) {
            let configPath = rootDirectoryPath.appending(RelativePath("\(Constants.tuistDirectoryName)/\(Manifest.config.fileName)"))

            if FileHandler.shared.exists(configPath) {
                let manifest = try manifestLoader.loadConfig(at: configPath.parentDirectory)
                return try TuistCore.Config.from(manifest: manifest)
            }
        }

        // We first try to load the deprecated file. If it doesn't exist, we load the new file name.
        let fileNames = [Manifest.config]
            .flatMap { [$0.deprecatedFileName, $0.fileName] }
            .compactMap { $0 }

        for fileName in fileNames {
            guard let configPath = FileHandler.shared.locateDirectoryTraversingParents(from: path, path: fileName) else {
                continue
            }
            let manifest = try manifestLoader.loadConfig(at: configPath.parentDirectory)
            return try TuistCore.Config.from(manifest: manifest)
        }

        return TuistCore.Config.default
    }
}

extension GeneratorModelLoader: ManifestModelConverting {
    public func convert(manifest: ProjectDescription.Project, path: AbsolutePath) throws -> TuistCore.Project {
        let config = try loadConfig(at: path)
        let generatorPaths = GeneratorPaths(manifestDirectory: path)
        let project = try TuistCore.Project.from(manifest: manifest, generatorPaths: generatorPaths)
        return try enriched(model: project, with: config)
    }

    public func convert(manifest: ProjectDescription.Workspace, path: AbsolutePath) throws -> TuistCore.Workspace {
        let generatorPaths = GeneratorPaths(manifestDirectory: path)
        let workspace = try TuistCore.Workspace.from(manifest: manifest,
                                                     path: path,
                                                     generatorPaths: generatorPaths,
                                                     manifestLoader: manifestLoader)
        return workspace
    }
}

extension GeneratorModelLoader {
    private func enriched(model: TuistCore.Project, with config: TuistCore.Config) throws -> TuistCore.Project {
        var enrichedModel = model

        // Xcode project file name
        var xcodeProjPath: AbsolutePath = enrichedModel.xcodeProjPath
        if let xcodeFileName = xcodeFileNameOverride(from: config, for: model) {
            xcodeProjPath = enrichedModel.xcodeProjPath.parentDirectory.appending(component: "\(xcodeFileName).xcodeproj")
        }
        enrichedModel = enrichedModel.replacing(xcodeProjPath: xcodeProjPath)

        // Xcode project organization name
        if let organizationName = organizationNameOverride(from: config) {
            enrichedModel = enrichedModel.replacing(organizationName: organizationName)
        }

        return enrichedModel
    }

    private func xcodeFileNameOverride(from config: TuistCore.Config, for model: TuistCore.Project) -> String? {
        var xcodeFileName = config.generationOptions.compactMap { item -> String? in
            switch item {
            case let .xcodeProjectName(projectName):
                return projectName.description
            default:
                return nil
            }
        }.first

        let projectNameTemplate = TemplateString.Token.projectName.rawValue
        xcodeFileName = xcodeFileName?.replacingOccurrences(of: projectNameTemplate,
                                                            with: model.name)

        return xcodeFileName
    }

    private func organizationNameOverride(from config: TuistCore.Config) -> String? {
        config.generationOptions.compactMap { item -> String? in
            switch item {
            case let .organizationName(name):
                return name
            default:
                return nil
            }
        }.first
    }
}
