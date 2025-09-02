import XCTest
@testable import StepsTracker

final class StepModelProgressTests: XCTestCase {
    func testProgress_withZeroGoal_returnsZero() {
        let model = StepModel(enableSideEffects: false)
        model.goalSteps = 0
        model.todaySteps = 100
        XCTAssertEqual(model.progress(), 0.0, accuracy: 1e-9)
    }

    func testProgress_withNegativeTodaySteps_returnsZero() {
        let model = StepModel(enableSideEffects: false)
        model.goalSteps = 1000
        model.todaySteps = -10
        XCTAssertEqual(model.progress(), 0.0, accuracy: 1e-9)
    }

    func testProgress_basicFraction() {
        let model = StepModel(enableSideEffects: false)
        model.goalSteps = 8000
        model.todaySteps = 4000
        XCTAssertEqual(model.progress(), 0.5, accuracy: 1e-9)
    }

    func testProgress_capsAtOne() {
        let model = StepModel(enableSideEffects: false)
        model.goalSteps = 5000
        model.todaySteps = 6000
        XCTAssertEqual(model.progress(), 1.0, accuracy: 1e-9)
    }
}


