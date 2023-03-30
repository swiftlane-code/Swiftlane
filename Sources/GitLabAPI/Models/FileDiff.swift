//

import Foundation

public struct FileDiff: Decodable {
    public init(
        oldPath: String,
        newPath: String,
        aMode: String,
        bMode: String,
        newFile: Bool,
        renamedFile: Bool,
        deletedFile: Bool,
        diff: String
    ) {
        self.oldPath = oldPath
        self.newPath = newPath
        self.aMode = aMode
        self.bMode = bMode
        self.newFile = newFile
        self.renamedFile = renamedFile
        self.deletedFile = deletedFile
        self.diff = diff
    }

    public let oldPath: String
    public let newPath: String
    public let aMode: String
    public let bMode: String
    public let newFile: Bool
    public let renamedFile: Bool
    public let deletedFile: Bool
    public let diff: String
}
