//

import Foundation

public protocol StdIOWrapping {
    func setupbuf(stdoutp: UnsafeMutablePointer<FILE>!, wtf: UnsafeMutablePointer<CChar>!)
}

public struct StdIOWrapper {}

extension StdIOWrapper: StdIOWrapping {
    public func setupbuf(stdoutp: UnsafeMutablePointer<FILE>!, wtf: UnsafeMutablePointer<CChar>!) {
        setbuf(stdoutp, wtf)
    }
}
