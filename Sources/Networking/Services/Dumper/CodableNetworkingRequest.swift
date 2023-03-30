//

import Foundation

public protocol NetworkingDumperProtocol {
    func dump(response: NetworkingResponse, requestUUID: UUID)
}
