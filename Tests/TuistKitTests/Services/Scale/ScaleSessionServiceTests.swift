import Foundation
import TSCBasic
import TuistCore
import TuistCoreTesting
import TuistLoader
import TuistLoaderTesting
import TuistScaleTesting
import TuistSupport
import XCTest

@testable import TuistKit
@testable import TuistSupportTesting

final class CloudSessionServiceErrorTests: TuistUnitTestCase {
    func test_description_when_missingScaleURL() {
        // Given
        let subject = ScaleSessionServiceError.missingScaleURL

        // When
        let got = subject.description

        // Then
        XCTAssertEqual(got, "The scale URL attribute is missing in your project's configuration.")
    }

    func test_type_when_missingCloudURL() {
        // Given
        let subject = ScaleSessionServiceError.missingScaleURL

        // When
        let got = subject.type

        // Then
        XCTAssertEqual(got, .abort)
    }
}

final class CloudSessionServiceTests: TuistUnitTestCase {
    var scaleSessionController: MockScaleSessionController!
    var generatorModelLoader: MockGeneratorModelLoader!
    var subject: ScaleSessionService!

    override func setUp() {
        super.setUp()
        scaleSessionController = MockScaleSessionController()
        generatorModelLoader = MockGeneratorModelLoader(basePath: FileHandler.shared.currentPath)
        subject = ScaleSessionService(scaleSessionController: scaleSessionController,
                                      generatorModelLoader: generatorModelLoader)
    }

    override func tearDown() {
        super.tearDown()
        scaleSessionController = nil
        generatorModelLoader = nil
        subject = nil
    }

    func test_printSession_when_cloudURL_is_missing() {
        // Given
        generatorModelLoader.mockConfig("") { (_) -> Config in
            Config.test(scale: nil)
        }

        // Then
        XCTAssertThrowsSpecific(try subject.printSession(), ScaleSessionServiceError.missingScaleURL)
    }

    func test_printSession() throws {
        // Given
        let scaleURL = URL.test()
        generatorModelLoader.mockConfig("") { (_) -> Config in
            Config.test(scale: Scale(url: scaleURL, projectId: "123", options: []))
        }

        // When
        try subject.printSession()

        // Then
        XCTAssertTrue(scaleSessionController.printSessionArgs.contains(scaleURL))
    }
}
