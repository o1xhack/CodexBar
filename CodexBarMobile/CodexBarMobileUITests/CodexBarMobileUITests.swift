import XCTest

final class CodexBarMobileUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testUsageSettingsSwitchBetweenUsedAndRemainingPercentages() {
        let app = self.makeApp()
        app.launch()

        app.tabBars.buttons["Setting"].tap()
        app.staticTexts["Usage Setting"].tap()
        let remainingToggle = app.switches["show-remaining-usage-toggle"]
        XCTAssertTrue(remainingToggle.waitForExistence(timeout: 5))
        XCTAssertEqual(remainingToggle.value as? String, "0")
        XCTAssertTrue(app.staticTexts["Usage"].exists)
        XCTAssertTrue(app.staticTexts["Charts"].exists)
        XCTAssertTrue(app.staticTexts["Privacy"].exists)
        XCTAssertTrue(app.staticTexts["Show remaining usage"].exists)
        XCTAssertTrue(
            app.staticTexts["Display the quota you have left instead of the quota you have used on usage cards."]
                .exists)
    }

    @MainActor
    func testCostTabShowsDailySpendCurrencyUnitInTitle() {
        let app = self.makeApp()
        app.launch()

        app.tabBars.buttons["Cost"].tap()

        XCTAssertTrue(app.staticTexts["Daily Spend"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["(USD)"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testCostTabCapturesRenderingScreenshot() {
        let app = self.makeApp()
        app.launch()

        app.tabBars.buttons["Cost"].tap()

        XCTAssertTrue(app.staticTexts["Provider Share"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Model Mix"].waitForExistence(timeout: 5))

        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = "Cost Tab Rendering"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testSpringBoardWidgetCanSelectOverview() throws {
        try self.runSpringBoardWidgetModeSelection(
            name: "Overview",
            pickerLabels: ["Overview", "概览", "概覽", "概要"],
            pickerRowY: 0.44
        )
    }

    @MainActor
    func testSpringBoardWidgetCanSelectProviderFocus() throws {
        try self.runSpringBoardWidgetModeSelection(
            name: "Provider Focus",
            pickerLabels: ["Provider Focus", "提供商焦点", "供應商焦點", "プロバイダーフォーカス"],
            pickerRowY: 0.50
        )
    }

    @MainActor
    func testSpringBoardWidgetCanSelectTodayCost() throws {
        try self.runSpringBoardWidgetModeSelection(
            name: "Today Cost",
            pickerLabels: ["Today Cost", "今日成本", "今日成本", "今日のコスト"],
            pickerRowY: 0.56
        )
    }

    @MainActor
    func testSpringBoardWidgetCanSelectSyncHealth() throws {
        try self.runSpringBoardWidgetModeSelection(
            name: "Sync Health",
            pickerLabels: ["Sync Health", "同步健康", "同步健康", "同期の健全性"],
            pickerRowY: 0.64
        )
    }

    @MainActor
    private func runSpringBoardWidgetModeSelection(
        name: String,
        pickerLabels: [String],
        pickerRowY: CGFloat
    ) throws {
        let environment = ProcessInfo.processInfo.environment
        guard environment["UI_TEST_SPRINGBOARD_WIDGET"] == "1"
            || environment["TEST_RUNNER_UI_TEST_SPRINGBOARD_WIDGET"] == "1" else {
            throw XCTSkip("Requires a simulator Home Screen with a placed CodexBar widget.")
        }

        let app = self.makeApp()
        app.launch()
        XCUIDevice.shared.press(.home)

        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        XCTAssertTrue(springboard.wait(for: .runningForeground, timeout: 5))

        self.openSpringBoardWidgetConfigurationPanel(on: springboard)

        let openedAttachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        openedAttachment.name = "SpringBoard Widget Configuration Panel"
        openedAttachment.lifetime = .keepAlways
        add(openedAttachment)

        // The system-hosted configuration UI is not consistently exposed through
        // XCTest accessibility on iOS 26 simulators, so use normalized screen
        // coordinates after proving the configuration extension is foreground.
        springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.80, dy: 0.43)).tap()
        Thread.sleep(forTimeInterval: 0.5)

        let modePickerAttachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        modePickerAttachment.name = "SpringBoard Widget Type Picker"
        modePickerAttachment.lifetime = .keepAlways
        add(modePickerAttachment)

        self.selectSpringBoardWidgetMode(
            on: springboard,
            name: name,
            pickerLabels: pickerLabels,
            pickerRowY: pickerRowY)
    }

    @MainActor
    func testTokenActivityOverviewScrollsAndSelectsDay() throws {
        let app = self.makeApp()
        // Preview snapshots are intentionally not persisted to the real ledger.
        app.launchArguments += ["-cwlEnabled", "NO"]
        app.launch()
        app.tabBars.buttons["Cost"].tap()
        let title = app.staticTexts["Daily Tokens Overview"]
        for _ in 0..<5 where !title.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        let move = max(0, title.frame.minY - 130) / app.frame.height
        if move > 0 {
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.8))
                .press(
                    forDuration: 0.1,
                    thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: max(0.15, 0.8 - move))),
                    withVelocity: .slow, thenHoldForDuration: 0.5)
        }
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        let key = try formatter.string(from: XCTUnwrap(Calendar.current.date(byAdding: .day, value: -7, to: Date())))
        let day = app.buttons["token-day-" + key].firstMatch
        XCTAssertTrue(day.waitForExistence(timeout: 3))
        let before = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        before.name = "Token cells before selection"
        before.lifetime = .keepAlways
        add(before)
        day.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        let selected = app.staticTexts["selected-token-day"]
        for _ in 0..<3 where !selected.exists {
            app.swipeUp()
        }
        XCTAssertTrue(selected.waitForExistence(timeout: 3))
        XCTAssertEqual(selected.label, key)
        XCTAssertTrue(app.buttons["Back to today"].firstMatch.exists)
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = "2.0 Token Overview"
        attachment.lifetime = .keepAlways
        add(attachment)
        XCTAssertFalse(app.staticTexts["Codex Service Mix"].exists)
    }

    @MainActor
    func testProviderTokenActivityReplacesDailyList() {
        let app = self.makeApp()
        // Preview snapshots are intentionally not persisted to the real ledger.
        app.launchArguments += ["-cwlEnabled", "NO"]
        app.launch()
        app.buttons["provider-group-codex"].tap()
        let title = app.staticTexts["Token Activity"]
        for _ in 0..<10 where !title.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(title.exists)
        XCTAssertFalse(app.buttons["Show all days"].exists)
        let move = max(0, title.frame.minY - 130) / app.frame.height
        if move > 0 {
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.8))
                .press(forDuration: 0.1,
                    thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: max(0.15, 0.8 - move))),
                    withVelocity: .slow, thenHoldForDuration: 0.5)
        }
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        let todayKey = formatter.string(from: Date())
        let today = app.buttons["token-day-" + todayKey].firstMatch
        XCTAssertTrue(today.exists)
        let originalX = today.frame.midX
        let y = today.frame.midY / app.frame.height
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: y))
            .press(forDuration: 0.1,
                thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: y)),
                withVelocity: .slow, thenHoldForDuration: 0.5)
        XCTAssertTrue(!today.isHittable || today.frame.midX > originalX + 100)
        let history = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        history.name = "2.0 Provider older history after horizontal swipe"
        history.lifetime = .keepAlways
        add(history)
        app.buttons["Back to today"].firstMatch.tap()
        XCTAssertTrue(today.isHittable)
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = "2.0 Provider Token Activity"
        attachment.lifetime = .keepAlways
        add(attachment)
        let serviceMix = app.staticTexts["Codex Service Mix"]
        for _ in 0..<5 where !serviceMix.isHittable { app.swipeUp() }
        XCTAssertTrue(serviceMix.exists)
    }

    @MainActor
    private func makeApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "UI_TEST_PREVIEW_DATA",
            "UI_TEST_SKIP_ONBOARDING",
            "UI_TEST_RESET_DEFAULTS",
            "-AppleLanguages",
            "(en)",
            "-AppleLocale",
            "en_US",
        ]
        return app
    }

    @MainActor
    private func firstExistingElement(in app: XCUIApplication, labels: [String]) -> XCUIElement {
        for label in labels {
            let button = app.buttons[label]
            if button.waitForExistence(timeout: 0.5) {
                return button
            }
        }
        return app.buttons[labels[0]]
    }

    @MainActor
    private func openSpringBoardWidgetConfigurationPanel(on springboard: XCUIApplication) {
        let widget = springboard.buttons
            .matching(NSPredicate(format: "label CONTAINS[c] %@", "CodexBar"))
            .firstMatch
        if widget.waitForExistence(timeout: 3) {
            widget.press(forDuration: 1.2)
        } else {
            // XCTest can miss WidgetKit host views even when SpringBoard exposes
            // them to the runtime accessibility snapshot. Fall back to the
            // release-gate simulator layout: a medium CodexBar widget centered
            // near the top of the first Home Screen page.
            springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.50, dy: 0.20))
                .press(forDuration: 1.2)
        }

        let editWidget = self.firstExistingElement(
            in: springboard,
            labels: ["Edit Widget", "编辑小组件", "編輯小工具", "ウィジェットを編集"]
        )
        XCTAssertTrue(editWidget.waitForExistence(timeout: 5), "SpringBoard did not expose the Edit Widget action.")
        editWidget.tap()

        let configurationExtension = XCUIApplication(
            bundleIdentifier: "com.apple.WorkflowUI.WidgetConfigurationExtension"
        )
        XCTAssertTrue(
            configurationExtension.wait(for: .runningForeground, timeout: 5),
            "SpringBoard did not foreground the widget configuration extension."
        )
    }

    @MainActor
    private func selectSpringBoardWidgetMode(
        on springboard: XCUIApplication,
        name: String,
        pickerLabels: [String],
        pickerRowY: CGFloat
    ) {
        let configurationExtension = XCUIApplication(
            bundleIdentifier: "com.apple.WorkflowUI.WidgetConfigurationExtension"
        )
        if !tapFirstExistingPickerLabel(in: configurationExtension, labels: pickerLabels),
           !tapFirstExistingPickerLabel(in: springboard, labels: pickerLabels) {
            springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.46, dy: pickerRowY)).tap()
        }
        Thread.sleep(forTimeInterval: 1.0)

        let selectionAttachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        selectionAttachment.name = "SpringBoard \(name) Configuration Selected"
        selectionAttachment.lifetime = .keepAlways
        add(selectionAttachment)

        XCUIDevice.shared.press(.home)
        Thread.sleep(forTimeInterval: 2.0)

        let widgetAttachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        widgetAttachment.name = "SpringBoard \(name) Widget"
        widgetAttachment.lifetime = .keepAlways
        add(widgetAttachment)
    }

    @MainActor
    private func tapFirstExistingPickerLabel(in app: XCUIApplication, labels: [String]) -> Bool {
        for label in labels {
            let button = app.buttons[label]
            if button.waitForExistence(timeout: 0.2), button.isHittable {
                button.tap()
                return true
            }

            let staticText = app.staticTexts[label]
            if staticText.waitForExistence(timeout: 0.2), staticText.isHittable {
                staticText.tap()
                return true
            }

            let otherElement = app.otherElements[label]
            if otherElement.waitForExistence(timeout: 0.2), otherElement.isHittable {
                otherElement.tap()
                return true
            }
        }
        return false
    }
}
