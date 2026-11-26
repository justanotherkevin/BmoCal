import Foundation

struct UpdateChecker {
    private struct Release: Decodable {
        let tag_name: String
        let html_url: String
    }

    /// Numeric dotted version compare; a leading "v" is ignored, missing parts count as 0.
    static func isNewer(_ remote: String, than local: String) -> Bool {
        func parts(_ s: String) -> [Int]? {
            let t = s.hasPrefix("v") ? String(s.dropFirst()) : s
            let p = t.split(separator: ".", omittingEmptySubsequences: false).map { Int($0) }
            return p.contains(nil) ? nil : p.compactMap { $0 }
        }
        guard var r = parts(remote), var l = parts(local) else { return false }
        let n = max(r.count, l.count)
        r += Array(repeating: 0, count: n - r.count)
        l += Array(repeating: 0, count: n - l.count)
        return r.lexicographicallyPrecedes(l) == false && r != l
    }

    /// Silent on any failure; calls back on the main queue only when a newer release exists.
    func check(completion: @escaping (_ version: String, _ url: URL) -> Void) {
        guard let api = URL(string: "https://api.github.com/repos/justanotherkevin/BmoCal-menu-bar-calendar/releases/latest"),
              let local = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else { return }
        var request = URLRequest(url: api)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        URLSession.shared.dataTask(with: request) { data, response, _ in
            guard (response as? HTTPURLResponse)?.statusCode == 200,
                  let data, let release = try? JSONDecoder().decode(Release.self, from: data),
                  let url = URL(string: release.html_url),
                  UpdateChecker.isNewer(release.tag_name, than: local) else { return }
            DispatchQueue.main.async { completion(release.tag_name, url) }
        }.resume()
    }
}
