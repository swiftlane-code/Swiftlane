//

import Foundation

public enum GitCreateStashOption: String, Hashable {
    /// All ignored and untracked files are also stashed and then cleaned up with git clean.
    case all

    /// All untracked files are also stashed and then cleaned up with git clean.
    case includeUntracked

    /// All changes already added to the index are left intact.
    case keepIndex
}
