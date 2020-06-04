import Foundation
import TuistSupport
import XCTest

@testable import TuistAutomationTesting
@testable import TuistCoreTesting
@testable import TuistKit
@testable import TuistSupportTesting

final class BuildServiceErrorTests: TuistUnitTestCase {
    func test_description() {
        XCTAssertEqual(BuildServiceError.schemeNotFound(scheme: "A", existing: ["B", "C"]).description, "Couldn't find scheme A. The available schemes are: B, C.")
    }

    func test_type() {
        XCTAssertEqual(BuildServiceError.schemeNotFound(scheme: "A", existing: ["B", "C"]).type, .abort)
    }
}

final class BuildServiceTests: TuistUnitTestCase {
    var projectGenerator: MockProjectGenerator!
    var xcodebuildController: MockXcodeBuildController!
    var buildgraphInspector: MockBuildGraphInspector!
    var subject: BuildService!

    override func setUp() {
        super.setUp()
        projectGenerator = MockProjectGenerator()
        xcodebuildController = MockXcodeBuildController()
        buildgraphInspector = MockBuildGraphInspector()
        subject = BuildService(projectGenerator: projectGenerator,
                               xcodebuildController: xcodebuildController,
                               buildGraphInspector: buildgraphInspector)
    }

    override func tearDown() {
        super.tearDown()
        projectGenerator = nil
        xcodebuildController = nil
        buildgraphInspector = nil
        subject = nil
    }

    func test_run_when_generate_is_true() throws {
        XCTFail("TODO")
    }

    func test_run_when_thereisnt_a_workspace_and_generate_is_false() throws {
        XCTFail("TODO")
    }

    func test_run_when_the_project_is_already_generated() throws {
        XCTFail("TODO")
    }
}
