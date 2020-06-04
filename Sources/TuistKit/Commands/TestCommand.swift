import ArgumentParser
import Foundation
import TSCBasic

/// Command that builds a target from the project in the current directory.
struct TestCommand: ParsableCommand {
    static var configuration: CommandConfiguration {
        CommandConfiguration(commandName: "test",
                             abstract: "Tests a project")
    }
    
    @Argument(default: nil,
              help: "The scheme to be tested. By default it builds all the buildable schemes of the project in the current directory")
    var scheme: String?

    func run() throws {
        try TestService().run(schemeName: scheme)
    }
}
