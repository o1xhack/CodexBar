import Foundation
import os.log

struct ClaudeStatusSnapshot {
    let sessionPercentLeft: Int?
    let weeklyPercentLeft: Int?
    let opusPercentLeft: Int?
    let accountEmail: String?
    let accountOrganization: String?
    let loginMethod: String?
    let primaryResetDescription: String?
    let secondaryResetDescription: String?
    let opusResetDescription: String?
    let rawText: String
}

enum ClaudeStatusProbeError: LocalizedError {
    case claudeNotInstalled
    case parseFailed(String)
    case timedOut

    var errorDescription: String? {
        switch self {
        case .claudeNotInstalled:
            "Claude CLI is not installed or not on PATH."
        case let .parseFailed(msg):
            "Could not parse Claude usage: \(msg)"
        case .timedOut:
            "Claude usage probe timed out."
        }
    }
}

/// Runs `claude` inside a PTY, sends `/usage`, and parses the rendered text panel.
struct ClaudeStatusProbe {
    var claudeBinary: String = "claude"
    var timeout: TimeInterval = 20.0

    func fetch() async throws -> ClaudeStatusSnapshot {
        guard TTYCommandRunner.which(self.claudeBinary) != nil else { throw ClaudeStatusProbeError.claudeNotInstalled }

        // Run both commands in parallel; /usage provides quotas, /status may provide org/account metadata.
        async let usageText = self.capture(subcommand: "/usage")
        async let statusText = self.capture(subcommand: "/status")

        let usage = try await usageText
        let status = try? await statusText
        let snap = try Self.parse(text: usage, statusText: status)

        if #available(macOS 13.0, *) {
            os_log(
                "[ClaudeStatusProbe] CLI scrape ok — session %d%% left, week %d%% left, opus %d%% left",
                log: .default,
                type: .info,
                snap.sessionPercentLeft ?? -1,
                snap.weeklyPercentLeft ?? -1,
                snap.opusPercentLeft ?? -1)
        }
        return snap
    }

    // MARK: - Parsing helpers

    static func parse(text: String, statusText: String? = nil) throws -> ClaudeStatusSnapshot {
        let clean = TextParsing.stripANSICodes(text)
        guard !clean.isEmpty else { throw ClaudeStatusProbeError.timedOut }

        if let usageError = self.extractUsageError(text: clean) {
            throw ClaudeStatusProbeError.parseFailed(usageError)
        }

        var sessionPct = self.extractPercent(labelSubstring: "Current session", text: clean)
        var weeklyPct = self.extractPercent(labelSubstring: "Current week (all models)", text: clean)
        var opusPct = self.extractPercent(labelSubstring: "Current week (Opus)", text: clean)

        // Fallback: order-based percent scraping if labels change or get localized.
        if sessionPct == nil || weeklyPct == nil || opusPct == nil {
            let ordered = self.allPercents(clean)
            if sessionPct == nil, ordered.indices.contains(0) { sessionPct = ordered[0] }
            if weeklyPct == nil, ordered.indices.contains(1) { weeklyPct = ordered[1] }
            if opusPct == nil, ordered.indices.contains(2) { opusPct = ordered[2] }
        }

        // Prefer usage text for identity; fall back to /status if present.
        let email = self.extractFirst(pattern: #"(?i)Account:\s+([^\s@]+@[^\s@]+)"#, text: clean)
            ?? self.extractFirst(pattern: #"(?i)Account:\s+([^\s@]+@[^\s@]+)"#, text: statusText ?? "")
        let orgRaw = self.extractFirst(pattern: #"(?i)Org:\s*(.+)"#, text: clean)
            ?? self.extractFirst(pattern: #"(?i)Org:\s*(.+)"#, text: statusText ?? "")
        let org: String? = {
            guard let orgText = orgRaw?.trimmingCharacters(in: .whitespacesAndNewlines), !orgText.isEmpty else {
                return nil
            }
            // Suppress org if it’s just the email prefix (common in CLI panels).
            if let email, orgText.lowercased().hasPrefix(email.lowercased()) { return nil }
            return orgText
        }()
        // Prefer explicit login method from /status, then fall back to /usage header heuristics.
        let login = self.extractLoginMethod(text: statusText ?? "") ?? self.extractLoginMethod(text: clean)

        guard let sessionPct, let weeklyPct else {
            throw ClaudeStatusProbeError.parseFailed("Missing Current session or Current week (all models)")
        }

        // Capture reset strings for UI display.
        let resets = self.allResets(clean)

        return ClaudeStatusSnapshot(
            sessionPercentLeft: sessionPct,
            weeklyPercentLeft: weeklyPct,
            opusPercentLeft: opusPct,
            accountEmail: email,
            accountOrganization: org,
            loginMethod: login,
            primaryResetDescription: resets.first,
            secondaryResetDescription: resets.count > 1 ? resets[1] : nil,
            opusResetDescription: resets.count > 2 ? resets[2] : nil,
            rawText: text + (statusText ?? ""))
    }

    private static func extractPercent(labelSubstring: String, text: String) -> Int? {
        let lines = text.components(separatedBy: .newlines)
        for (idx, line) in lines.enumerated() where line.lowercased().contains(labelSubstring.lowercased()) {
            let window = lines.dropFirst(idx).prefix(4)
            for candidate in window {
                if let pct = percentFromLine(candidate) { return pct }
            }
        }
        return nil
    }

    private static func percentFromLine(_ line: String) -> Int? {
        let pattern = #"([0-9]{1,3})%\s*(used|left)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        let range = NSRange(line.startIndex..<line.endIndex, in: line)
        guard let match = regex.firstMatch(in: line, options: [], range: range),
              match.numberOfRanges >= 3,
              let valRange = Range(match.range(at: 1), in: line),
              let kindRange = Range(match.range(at: 2), in: line)
        else { return nil }
        let rawVal = Int(line[valRange]) ?? 0
        let isUsed = line[kindRange].lowercased().contains("used")
        return isUsed ? max(0, 100 - rawVal) : rawVal
    }

    private static func extractFirst(pattern: String, text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range),
              match.numberOfRanges >= 2,
              let r = Range(match.range(at: 1), in: text) else { return nil }
        return String(text[r]).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func extractUsageError(text: String) -> String? {
        if let jsonHint = self.extractUsageErrorJSON(text: text) { return jsonHint }

        let lower = text.lowercased()
        if lower.contains("token_expired") || lower.contains("token has expired") {
            return "Claude CLI token expired. Run `claude login` to refresh."
        }
        if lower.contains("authentication_error") {
            return "Claude CLI authentication error. Run `claude login`."
        }
        if lower.contains("failed to load usage data") {
            return "Claude CLI could not load usage data. Open the CLI and retry `/usage`."
        }
        return nil
    }

    // Collect percentages in the order they appear; used as a backup when labels move/rename.
    private static func allPercents(_ text: String) -> [Int] {
        let patterns = ["([0-9]{1,3})%\\s*left", "([0-9]{1,3})%\\s*used", "([0-9]{1,3})%"]
        var results: [Int] = []
        for pat in patterns {
            guard let regex = try? NSRegularExpression(pattern: pat, options: [.caseInsensitive]) else { continue }
            let nsrange = NSRange(text.startIndex..<text.endIndex, in: text)
            regex.enumerateMatches(in: text, options: [], range: nsrange) { match, _, _ in
                guard let match,
                      let r = Range(match.range(at: 1), in: text),
                      let val = Int(text[r]) else { return }
                let used: Int = if pat.contains("left") {
                    max(0, 100 - val)
                } else {
                    val
                }
                results.append(used)
            }
            if results.count >= 3 { break }
        }
        return results
    }

    // Capture all "Resets ..." strings to surface in the menu.
    private static func allResets(_ text: String) -> [String] {
        let pat = #"Resets[^\n]*"#
        guard let regex = try? NSRegularExpression(pattern: pat, options: [.caseInsensitive]) else { return [] }
        let nsrange = NSRange(text.startIndex..<text.endIndex, in: text)
        var results: [String] = []
        regex.enumerateMatches(in: text, options: [], range: nsrange) { match, _, _ in
            guard let match,
                  let r = Range(match.range(at: 0), in: text) else { return }
            // TTY capture sometimes appends a stray ")" at line ends; trim it to keep snapshots stable.
            let raw = String(text[r]).trimmingCharacters(in: .whitespacesAndNewlines)
            var cleaned = raw.trimmingCharacters(in: CharacterSet(charactersIn: " )"))
            let openCount = cleaned.filter { $0 == "(" }.count
            let closeCount = cleaned.filter { $0 == ")" }.count
            if openCount > closeCount { cleaned.append(")") }
            results.append(cleaned)
        }
        return results
    }

    // Extract login/plan string from CLI output.
    private static func extractLoginMethod(text: String) -> String? {
        guard !text.isEmpty else { return nil }
        if let explicit = self.extractFirst(pattern: #"(?i)login\s+method:\s*(.+)"#, text: text) {
            return explicit.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        // Capture any "Claude <...>" phrase (e.g., Max/Pro/Ultra/Team) to avoid future plan-name churn.
        // Strip any leading ANSI that may have survived (rare) before matching.
        let planPattern = #"(?i)(claude\s+[a-z0-9][a-z0-9\s._-]{0,24})"#
        var candidates: [String] = []
        if let regex = try? NSRegularExpression(pattern: planPattern, options: []) {
            let nsrange = NSRange(text.startIndex..<text.endIndex, in: text)
            regex.enumerateMatches(in: text, options: [], range: nsrange) { match, _, _ in
                guard let match,
                      match.numberOfRanges >= 2,
                      let r = Range(match.range(at: 1), in: text) else { return }
                let raw = String(text[r])
                let val = TextParsing.stripANSICodes(raw).trimmingCharacters(in: .whitespacesAndNewlines)
                candidates.append(val)
            }
        }
        if let plan = candidates.first(where: { cand in
            let lower = cand.lowercased()
            return !lower.contains("code v") && !lower.contains("code version") && !lower.contains("code")
        }) {
            return plan
        }
        return nil
    }

    private static func extractUsageErrorJSON(text: String) -> String? {
        let pattern = #"Failed to load usage data:\s*(\{.*\})"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else {
            return nil
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range),
              match.numberOfRanges >= 2,
              let jsonRange = Range(match.range(at: 1), in: text)
        else {
            return nil
        }

        let jsonString = String(text[jsonRange])
        guard let data = jsonString.data(using: .utf8),
              let payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let error = payload["error"] as? [String: Any]
        else {
            return nil
        }

        let message = (error["message"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let details = error["details"] as? [String: Any]
        let code = (details?["error_code"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)

        var parts: [String] = []
        if let message, !message.isEmpty { parts.append(message) }
        if let code, !code.isEmpty { parts.append("(\(code))") }

        guard !parts.isEmpty else { return nil }
        let hint = parts.joined(separator: " ")

        if let code, code.lowercased().contains("token") {
            return "\(hint). Run `claude login` to refresh."
        }
        return "Claude CLI error: \(hint)"
    }

    // MARK: - Process helpers

    // Run `script -q /dev/null claude <subcommand>` with a hard timeout; avoids fragile PTY keystrokes.
    private func capture(subcommand: String) async throws -> String {
        try await Task.detached(priority: .utility) { [claudeBinary = self.claudeBinary, timeout = self.timeout] in
            let process = Process()
            process.launchPath = "/usr/bin/script"
            process.arguments = [
                "-q",
                "/dev/null",
                claudeBinary,
                subcommand,
                "--allowed-tools",
                "",
                "--dangerously-skip-permissions",
            ]
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = Pipe()
            process.standardInput = nil

            do {
                try process.run()
            } catch {
                throw ClaudeStatusProbeError.claudeNotInstalled
            }

            DispatchQueue.global().asyncAfter(deadline: .now() + timeout) {
                if process.isRunning { process.terminate() }
            }

            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard !data.isEmpty else { throw ClaudeStatusProbeError.timedOut }
            return String(data: data, encoding: .utf8) ?? ""
        }.value
    }
}
