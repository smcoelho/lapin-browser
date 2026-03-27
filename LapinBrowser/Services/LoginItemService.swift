import Foundation
import OSLog
import ServiceManagement

private let logger = Logger(subsystem: "pt.lapin.browser", category: "LoginItemService")

enum LoginItemService {
    static var isRegistered: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static func enable(completion: @escaping @MainActor (Bool, Error?) -> Void) {
        Task.detached(priority: .userInitiated) {
            do {
                try SMAppService.mainApp.register()
                await MainActor.run { completion(true, nil) }
            } catch let error as NSError where error.code == kSMErrorAlreadyRegistered {
                await MainActor.run { completion(true, nil) }
            } catch {
                logger.error("SMAppService register failed: \(error)")
                await MainActor.run { completion(false, error) }
            }
        }
    }

    static func disable(completion: @escaping @MainActor (Bool, Error?) -> Void) {
        SMAppService.mainApp.unregister { error in
            Task { @MainActor in
                if let nsError = error as? NSError, nsError.code == kSMErrorJobNotFound {
                    completion(true, nil)
                } else if let error {
                    logger.error("SMAppService unregister failed: \(error)")
                    completion(false, error)
                } else {
                    completion(true, nil)
                }
            }
        }
    }
}
