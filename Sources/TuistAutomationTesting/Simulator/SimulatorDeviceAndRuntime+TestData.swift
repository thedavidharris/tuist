import Foundation
import TSCBasic
@testable import TuistAutomation

extension SimulatorDeviceAndRuntime {
    static func test(device: SimulatorDevice = .test(),
                     runtime: SimulatorRuntime = .test()) -> SimulatorDeviceAndRuntime {
        SimulatorDeviceAndRuntime(device: device, runtime: runtime)
    }
}
