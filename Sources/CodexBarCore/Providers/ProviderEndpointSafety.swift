import Foundation

public enum ProviderEndpointSafety {
    public static func trustedHTTPSURL(
        _ raw: String?,
        allowedHostSuffixes: [String]) -> URL?
    {
        guard let cleaned = self.cleaned(raw) else { return nil }

        let candidate: URL? = if let url = URL(string: cleaned), url.scheme != nil {
            url
        } else {
            URL(string: "https://\(cleaned)")
        }

        guard let url = candidate,
              url.scheme?.lowercased() == "https",
              let host = url.host?.lowercased(),
              self.isTrustedHost(host, allowedHostSuffixes: allowedHostSuffixes)
        else {
            return nil
        }

        return url
    }

    private static func isTrustedHost(
        _ host: String,
        allowedHostSuffixes: [String]) -> Bool
    {
        allowedHostSuffixes.contains { suffix in
            let normalized = suffix.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "."))
            return host == normalized || host.hasSuffix(".\(normalized)")
        }
    }

    private static func cleaned(_ raw: String?) -> String? {
        guard var value = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
            return nil
        }

        if (value.hasPrefix("\"") && value.hasSuffix("\"")) ||
            (value.hasPrefix("'") && value.hasSuffix("'"))
        {
            value.removeFirst()
            value.removeLast()
        }

        value = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
