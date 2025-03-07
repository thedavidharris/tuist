import ArgumentParser
import Foundation
import TSCBasic
import TuistCore
import TuistSigning
import TuistSupport

struct DecryptCommand: ParsableCommand {
    static var configuration: CommandConfiguration {
        CommandConfiguration(commandName: "decrypt",
                             abstract: "Decrypts all files in Tuist/Signing directory")
    }

    @Option(
        name: .shortAndLong,
        help: "The path to the folder containing the encrypted certificates"
    )
    var path: String?

    func run() throws {
        try DecryptService().run(path: path)
    }
}
