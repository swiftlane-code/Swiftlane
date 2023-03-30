//

import Foundation
import SwiftlaneCore

// sourcery: AutoMockable
public protocol ExpiringToDoResponsibilityProviding {
    func isNilAuthorAllowed() -> Bool
    func isAuthorAllowed(username: String) -> Bool
    func shouldToDoBlock(username: String, todoAuthor: String?) -> Bool
}

public struct ExpiringToDoBlockingConfig: Codable {
    public let strategy: StrategyParams
    public let teams: [String: [String]]

    public struct StrategyParams: Codable {
        public let listedUsersBlock: BlockingStrategy
        public let unlistedTODOAuthorsBlockEveryone: Bool
        public let unlistedTODOAuthorsAllowed: Bool
        public let unauthoredTODOAllowed: Bool
        public let unauthoredTODOBlockEveryone: Bool
    }

    public enum BlockingStrategy: String, Codable {
        case author
        case team
        case everyone
    }
}

public class ExpiringToDoResponsibilityProvider {
    private let config: ExpiringToDoBlockingConfig

    public init(config: ExpiringToDoBlockingConfig) {
        self.config = config
    }

    private func team(ofUser username: String) -> (name: String, members: [String])? {
        config.teams.first {
            $0.value.contains(username)
        }.map {
            (name: $0.key, members: $0.value)
        }
    }
}

extension ExpiringToDoResponsibilityProvider: ExpiringToDoResponsibilityProviding {
    public func isNilAuthorAllowed() -> Bool {
        config.strategy.unauthoredTODOAllowed
    }

    public func isAuthorAllowed(username: String) -> Bool {
        config.strategy.unlistedTODOAuthorsAllowed || team(ofUser: username) != nil
    }

    public func shouldToDoBlock(username: String, todoAuthor: String?) -> Bool {
        guard let todoAuthor = todoAuthor else {
            // unauthored TODO
            return config.strategy.unauthoredTODOBlockEveryone
        }

        if todoAuthor == username {
            return true /// always block the author of todo
        }

        guard let authorTeam = team(ofUser: todoAuthor) else {
            // unlisted author
            return config.strategy.unlistedTODOAuthorsBlockEveryone
        }

        switch config.strategy.listedUsersBlock {
        case .author:
            /// always `false` because ** author -> `true` is checked above **
            return todoAuthor == username

        case .team:
            return authorTeam.members.contains(username)

        case .everyone:
            return true
        }
    }
}
