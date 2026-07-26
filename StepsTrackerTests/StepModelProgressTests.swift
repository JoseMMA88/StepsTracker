import XCTest
@testable import StepsTracker

@MainActor
final class StepModelProgressTests: XCTestCase {
    func testProgressReturnsZeroForNegativeSteps() {
        let model = makeModel()
        model.goalSteps = 1_000
        model.todaySteps = -1
        XCTAssertEqual(model.progress(), 0)
    }

    func testProgressCapsAtOne() {
        let model = makeModel()
        model.goalSteps = 5_000
        model.todaySteps = 6_000

        XCTAssertEqual(model.progress(), 1)
    }

    func testUpdatingGoalPersistsItsValidatedValue() async {
        let settings = InMemoryGoalSettingsStore(goalSteps: 8_000)
        let model = makeModel(settings: settings)

        await model.updateGoal(0)

        XCTAssertEqual(model.goalSteps, 1)
        XCTAssertEqual(settings.goalSteps, 1)
    }

    func testUpdatingGoalCapsItsValidatedValue() async {
        let settings = InMemoryGoalSettingsStore(goalSteps: 8_000)
        let model = makeModel(settings: settings)

        await model.updateGoal(250_000)

        XCTAssertEqual(model.goalSteps, 100_000)
        XCTAssertEqual(settings.goalSteps, 100_000)
    }

    private func makeModel(settings: InMemoryGoalSettingsStore? = nil) -> StepModel {
        StepModel(
            enableSideEffects: false,
            stepDataProvider: StepDataProviderStub(),
            settingsStore: settings ?? InMemoryGoalSettingsStore(),
            notificationScheduler: NotificationSchedulerSpy(),
            now: { Self.today }
        )
    }

    private static let today = Calendar(identifier: .gregorian).date(
        from: DateComponents(year: 2026, month: 7, day: 26)
    )!
}
