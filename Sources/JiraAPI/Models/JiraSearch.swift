//

import Foundation

public struct JiraSearch: Encodable {
    let jql: String
    let startAt: Int = 0
    let maxResults: Int = 500
    let fields: [String] = []
    //	let fieldsByKeys = false // In API V2 not found
}
