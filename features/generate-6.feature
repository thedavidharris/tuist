Feature: Generate a new project using Tuist (suite 6)

Scenario: The project is an iOS application using environment variables (framework_with_environment_variables)
    Given that tuist is available
    And I have a working directory
    Then I copy the fixture framework_with_environment_variables into the working directory
    Then tuist generates the project with environment variable TUIST_FRAMEWORK_NAME and value FrameworkA
    Then I should be able to build for macOS the scheme FrameworkA
    Then tuist generates the project with environment variable TUIST_FRAMEWORK_NAME and value FrameworkB
    Then I should be able to build for macOS the scheme FrameworkB

Scenario: The project is an iOS application with core data models (ios_app_with_coredata)
    Given that tuist is available
    And I have a working directory
    Then I copy the fixture ios_app_with_coredata into the working directory
    Then tuist generates the project
    Then I should be able to build for iOS the scheme App
    Then the product 'App.app' with destination 'Debug-iphoneos' contains resource 'Users.momd'
    Then the product 'App.app' with destination 'Debug-iphoneos' contains resource '1_2.cdm'