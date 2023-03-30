//

import Foundation

extension NetworkingRequest {
    internal func buildURLRequest(logger: NetworkingLoggerProtocol?) -> URLRequest {
        let url = urlWithQueryItems(logger: logger)
        var request = URLRequest(url: url)

        request.httpMethod = method.rawValue
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        if let timeout = timeout {
            request.timeoutInterval = timeout
        }

        request.httpBody = body

        return request
    }

    private func urlWithQueryItems(logger: NetworkingLoggerProtocol?) -> URL {
        /// # Why are we appending after getting `absoluteString`?
        ///
        /// We want to support `route`s like `"builds?filter=all"`.
        ///
        ///	This is wrong:
        /// ```
        /// URL(string: "myapi.com").appendingPathComponent("builds?filter=all").absoluteString
        /// // returns `"myapi.com/builds%3Ffilter%3Dall"`.
        /// ```
        ///
        ///	And what we want is:
        /// ```
        /// URL(string: "myapi.com").absoluteString.appendingPathComponent("builds?filter=all")
        /// // returns `"myapi.com/builds?filter=all"`.
        /// ```
        let urlString = baseURL.absoluteString.appendingPathComponent(route)
        let url = URL(string: urlString) ?? baseURL.appendingPathComponent(route)
        guard !queryItems.isEmpty else {
            return url
        }

        /// This allows us to specify some query items in the `route`.
        guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url
        }

        var items = urlComponents.queryItems ?? [URLQueryItem]()
        queryItems.forEach { item in
            /// `"arrayItem[]=value"` syntax
            (item.value as? [Any])?.forEach {
                items.append(URLQueryItem(name: item.key + "[]", value: "\($0)"))
            }
            items.append(URLQueryItem(name: item.key, value: "\(item.value)"))
        }
        urlComponents.queryItems = items

        guard let urlWithQueryItems = urlComponents.url else {
            logger?.log(unexpectedBehaviour: "\(self) > urlWithQueryItems is nil. Investigate!")
            return url
        }

        return urlWithQueryItems
    }
}
