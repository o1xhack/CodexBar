import Testing
@testable import CodexBar

struct KeychainMigrationTests {
    @Test
    func `migration list covers known keychain items`() {
        let items = Set(KeychainMigration.itemsToMigrate.map(\.label))
        let expected: Set = [
            "com.o1xhack.CodexBar:codex-cookie",
            "com.o1xhack.CodexBar:claude-cookie",
            "com.o1xhack.CodexBar:cursor-cookie",
            "com.o1xhack.CodexBar:factory-cookie",
            "com.o1xhack.CodexBar:minimax-cookie",
            "com.o1xhack.CodexBar:minimax-api-token",
            "com.o1xhack.CodexBar:augment-cookie",
            "com.o1xhack.CodexBar:copilot-api-token",
            "com.o1xhack.CodexBar:zai-api-token",
            "com.o1xhack.CodexBar:synthetic-api-key",
        ]

        let missing = expected.subtracting(items)
        #expect(missing.isEmpty, "Missing migration entries: \(missing.sorted())")
    }
}
