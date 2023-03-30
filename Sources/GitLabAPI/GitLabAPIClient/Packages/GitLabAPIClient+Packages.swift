//

import Combine
import Foundation
import Networking
import SwiftlaneCore

public struct PackagesListRequest: Codable {
    /// The field to use as order.
    public enum Order: String, Codable {
        case createdAt = "created_at"
        case name
        case version
        case type
    }

    public var order_by: Order? = nil
    public var sort: GitLabAPIClient.Sort? = nil
    public var package_type: Package.PackageType? = nil
    /// Name matching is not strict.
    public var package_name: String? = nil
    public var include_versionless: Bool? = nil
    public var status: Package.Status? = nil
    public var page: UInt? = nil
    public var per_page: UInt? = nil {
        didSet {
            if let per_page = per_page, per_page > 100 {
                self.per_page = 100 // gitlab limitation
            }
        }
    }

    public static func make(_ closure: (inout Self) -> Void = { _ in }) -> Self {
        var request = Self()
        closure(&request)
        return request
    }
}

public extension GitLabAPIClient {
    enum Sort: String, Codable {
        case ascending = "asc"
        case descending = "desc"
    }

    private func apiPackagePath(
        space: GitLab.Space,
        name: String,
        version: String,
        fileName: String
    ) -> String {
        space.apiPath(suffix: "packages") + "/generic/\(name)/\(version)/\(fileName)"
    }

    /// Recursively load `listPackages` for all available pages.
    /// - Parameters:
    ///   - name: find packages by name, name matching is not strict.
    ///   - loadAtLeast: stop loading pages when total packages loaded >= `loadAtLeast`.
    ///   - baseRequest: request model to be used as a base to load pages.
    /// - Returns: array of all packages.
    func allPackages(
        space: GitLab.Space,
        loadAtLeast: Int?,
        baseRequest: PackagesListRequest
    ) -> AnyPublisher<[Package], NetworkingError> {
        Publishers.loadAllPages(
            pageRequest: { pageIndex -> AnyPublisher<[Package], NetworkingError> in
                var request = baseRequest
                request.page = UInt(pageIndex)
                return self.listPackages(space: space, request: request)
            },
            nextPageExists: { (loadedPages: [[Package]]) in
                let loadedCount = loadedPages.map(\.count).reduce(0, +)
                let loadedEnough = loadedCount >= (loadAtLeast ?? .max)
                let lastPageIsEmpty = (loadedPages.last ?? []).isEmpty
                return !lastPageIsEmpty && !loadedEnough
            },
            startPageIndex: 1
        )
        .map { (allPages: [[Package]]) in
            allPages.flatMap { $0 }
        }
        .eraseToAnyPublisher()
    }

    func listPackages(
        space: GitLab.Space,
        request: PackagesListRequest
    ) -> AnyPublisher<[Package], NetworkingError> {
        client
            .get(space.apiPath(suffix: "packages"))
            .with(queryItemsEncodable: request)
            .perform()
    }

    func downloadPackage(
        space: GitLab.Space,
        name: String,
        version: String,
        fileName: String,
        timeout: TimeInterval
    ) -> AnyPublisher<ProgressOrResult<NetworkingProgress, Data>, NetworkingError> {
        client
            .get(
                apiPackagePath(
                    space: space,
                    name: name,
                    version: version,
                    fileName: fileName
                )
            )
            .with(timeout: timeout)
            .performWithProgress()
    }

    func uploadPackage(
        space: GitLab.Space,
        name: String,
        version: String,
        fileName: String,
        data: Data,
        timeout: TimeInterval
    ) -> AnyPublisher<ProgressOrResult<NetworkingProgress, PackageUploadResult>, NetworkingError> {
        client
            .put(
                apiPackagePath(
                    space: space,
                    name: name,
                    version: version,
                    fileName: fileName
                )
            )
            .with(body: data)
            .with(timeout: timeout)
            .performWithProgress()
    }

    func deletePackage(
        space: GitLab.Space,
        id: Int
    ) -> AnyPublisher<Void, NetworkingError> {
        client
            .delete(space.apiPath(suffix: "packages/\(id)"))
            .perform()
    }
}
