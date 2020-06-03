import ArgumentParser
import Foundation
import TSCBasic

/// Command that builds a target from the project in the current directory.
struct BuildCommand: ParsableCommand {
    static var configuration: CommandConfiguration {
        CommandConfiguration(commandName: "build",
                             abstract: "Builds a project")
    }
    
    @Argument(default: nil,
              help: "The scheme to be built. By default it builds all the buildable schemes of the project in the current directory")
    var scheme: String?

    func run() throws {
        try BuildService().run(scheme: scheme)
    }
}
