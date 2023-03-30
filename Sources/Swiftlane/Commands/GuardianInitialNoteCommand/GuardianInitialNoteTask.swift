//

import Foundation
import Git
import GitLabAPI
import Guardian
import SwiftlaneCore

private enum SwiftlaneGifs: String, CaseIterable {
    /// https://giphy.com/gifs/star-wars-Swiftlane-r2d2-UOpdmwKA7la0g
    case dontGetTechnicalWithMe = "https://media0.giphy.com/media/UOpdmwKA7la0g/giphy.gif"

    /// https://giphy.com/gifs/starwars-movie-star-wars-3o84sBJxpPt6g6MRdC
    case imGoingToRegretThis = "https://media0.giphy.com/media/3o84sBJxpPt6g6MRdC/giphy.gif"

    /// https://giphy.com/gifs/starwars-star-wars-episode-2-3ohuAckjLoRKKZgmS4
    case blessMyCircuits = "https://media2.giphy.com/media/3ohuAckjLoRKKZgmS4/giphy.gif"

    /// https://giphy.com/gifs/starwars-star-wars-episode-2-3ohuAmg26r2xctmALK
    case imProgrammedForEtiquiteNotDestruction = "https://media2.giphy.com/media/3ohuAmg26r2xctmALK/giphy.gif"

    /// https://giphy.com/gifs/star-wars-c3p0-eJnXPUTnDE7V6
    case weAreDoomed = "https://media4.giphy.com/media/eJnXPUTnDE7V6/giphy.gif"

    /// https://giphy.com/gifs/starwars-season-1-star-wars-3o84sH4BQlPfMYKSvm
    case imSwiftlaneAndThisIsR2D2 = "https://media1.giphy.com/media/3o84sH4BQlPfMYKSvm/giphy.gif"

    /// https://giphy.com/gifs/oscars-bb8-r2d2-c3p0-dSPN68X2EBo3e
    case dontLeaveMe = "https://media2.giphy.com/media/dSPN68X2EBo3e/giphy.gif"

    /// https://giphy.com/gifs/disneylandparis-disney-parade-disneyland-paris-4YZNUwXuo8XYJDKnun
    case turningAround = "https://media2.giphy.com/media/4YZNUwXuo8XYJDKnun/giphy.gif"
}

public final class GuardianInitialNoteTask: GuardianBaseTask {
    private let reporter: MergeRequestReporting
    private let gitlabCIEnvironmentReader: GitLabCIEnvironmentReading

    public init(
        logger: Logging,
        mergeRequestReporter: MergeRequestReporting,
        gitlabCIEnvironmentReader: GitLabCIEnvironmentReading
    ) {
        reporter = mergeRequestReporter
        self.gitlabCIEnvironmentReader = gitlabCIEnvironmentReader
        super.init(reporter: reporter, logger: logger)
    }

    override public func executeChecksOnly() throws {
        let url = try SwiftlaneGifs.allCases.randomElement().unwrap().rawValue
        let text = "<img src=\(url.quoted) width=\"100%\"/>"
        reporter.markdown(text)
    }
}
