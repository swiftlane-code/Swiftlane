//

import Foundation
import SwiftlaneCore

public struct Fields: Codable {
    public struct Project: Codable {
        public let id: String
    }

    public let assignee: User?
    public let creator: User
    public let fixVersions: [FullVersion]
    public let labels: [String]
    public let reporter: User
    public let priority: Priority
    public let status: Status
    public let type: Issue.IssueType
    public let subtasks: [Issue.Subtasks]
    public let project: Project
    public let summary: String
    public let parent: Issue.ParentTask?
    public let allData: [String: AnyDecodableValue]

    public enum CodingKeys: String, CodingKey {
        case assignee, creator, fixVersions, labels, reporter, priority, status, subtasks, project, summary, parent
        case type = "issuetype"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        assignee = try container.decodeIfPresent(User.self, forKey: .assignee)
        creator = try container.decode(User.self, forKey: .creator)
        fixVersions = try container.decode([FullVersion].self, forKey: .fixVersions)
        labels = try container.decode([String].self, forKey: .labels)
        reporter = try container.decode(User.self, forKey: .reporter)
        priority = try container.decode(Priority.self, forKey: .priority)
        status = try container.decode(Status.self, forKey: .status)
        subtasks = try container.decode([Issue.Subtasks].self, forKey: .subtasks)
        project = try container.decode(Project.self, forKey: .project)
        summary = try container.decode(String.self, forKey: .summary)
        parent = try container.decodeIfPresent(Issue.ParentTask.self, forKey: .parent)
        type = try container.decode(Issue.IssueType.self, forKey: .type)

        struct DynamicKey: CodingKey {
            var stringValue: String
            var intValue: Int?

            init?(stringValue: String) {
                self.stringValue = stringValue
            }

            init?(intValue _: Int) {
                nil
            }
        }

        let dynamicContainer = try decoder.container(keyedBy: DynamicKey.self)
        allData = try Dictionary(uniqueKeysWithValues: dynamicContainer.allKeys.map {
            ($0.stringValue, try dynamicContainer.decode(AnyDecodableValue.self, forKey: $0))
        })
    }

    public init(
        assignee: User?,
        creator: User,
        fixVersions: [FullVersion],
        labels: [String],
        reporter: User,
        priority: Priority,
        status: Status,
        type: Issue.IssueType,
        subtasks: [Issue.Subtasks],
        project: Project,
        summary: String,
        parent: Issue.ParentTask?,
        allData: [String: AnyDecodableValue]
    ) {
        self.assignee = assignee
        self.creator = creator
        self.fixVersions = fixVersions
        self.labels = labels
        self.reporter = reporter
        self.priority = priority
        self.status = status
        self.type = type
        self.subtasks = subtasks
        self.project = project
        self.summary = summary
        self.parent = parent
        self.allData = allData
    }
}
