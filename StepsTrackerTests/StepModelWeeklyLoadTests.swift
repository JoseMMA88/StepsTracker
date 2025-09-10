import XCTest
@testable import StepsTracker

public final class StepDataProviderMock: StepDataProviding {
    var stepsByDate: [Date: Int] = [:]
    func stepsForDay(_ date: Date, completion: @escaping (Int) -> Void) {
        // Simulate async completion to mirror real provider
        DispatchQueue.global().async {
            completion(self.stepsByDate[date] ?? 0)
        }
    }
}

final class StepModelWeeklyLoadTests: XCTestCase {
    func testLoadWeeklyData_populatesSevenDays() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let mock = StepDataProviderMock()
        // Pre-fill mock data for 7 days
        var expected: [Date: Int] = [:]
        for dayOffset in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
            let steps = (dayOffset + 1) * 100
            expected[date] = steps
        }
        mock.stepsByDate = expected

        let model = StepModel(enableSideEffects: false, stepDataProvider: mock)
        let expectationPopulated = expectation(description: "weeklySteps populated")

        model.loadWeeklyData()

        // Wait briefly for async completions
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.2) {
            if model.weeklySteps.count == 7 {
                expectationPopulated.fulfill()
            }
        }

        wait(for: [expectationPopulated], timeout: 1.0)

        // Verify all seven entries and values
        XCTAssertEqual(model.weeklySteps.count, 7)
        for (date, steps) in expected {
            XCTAssertEqual(model.weeklySteps[date], steps)
        }
    }
}







