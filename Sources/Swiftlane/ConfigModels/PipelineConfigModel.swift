//

import Foundation

public struct PipelineConfigModel: Decodable {
    public struct Variable: Decodable {
        public let key: String
        public let value: String
    }

    public let variables: [Variable]
}
