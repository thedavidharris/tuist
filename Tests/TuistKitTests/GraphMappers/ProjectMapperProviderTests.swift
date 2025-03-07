import Foundation
import TuistCache
import TuistCoreTesting
import TuistGenerator
import TuistScale
import TuistSupport
import XCTest

@testable import TuistCore
@testable import TuistKit
@testable import TuistSigning
@testable import TuistSupportTesting

final class ProjectMapperProviderTests: TuistUnitTestCase {
    var subject: ProjectMapperProvider!

    override func setUp() {
        super.setUp()
        subject = ProjectMapperProvider()
    }

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    func test_mapper_returns_a_sequential_mapper_with_the_autogenerated_schemes_project_mapper() throws {
        // Given
        subject = ProjectMapperProvider()

        // When
        let got = subject.mapper(config: Config.test(scale: .test(options: [])))

        // Then
        let sequentialProjectMapper = try XCTUnwrap(got as? SequentialProjectMapper)
        XCTAssertEqual(sequentialProjectMapper.mappers.filter { $0 is AutogeneratedSchemesProjectMapper }.count, 1)
    }

    func test_mappers_returns_theSigningMapper() throws {
        // Given
        subject = ProjectMapperProvider()

        // When
        let got = subject.mapper(config: Config.test())

        // Then
        let sequentialProjectMapper = try XCTUnwrap(got as? SequentialProjectMapper)
        XCTAssertEqual(sequentialProjectMapper.mappers.filter { $0 is SigningMapper }.count, 1)
    }
}
