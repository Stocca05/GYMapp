import Testing
@testable import Frigo

struct ConsumptionFractionTests {
    @Test func calculatesTheSelectedFractionOfTheRemainingQuantity() {
        #expect(ConsumptionFraction.oneQuarter.quantity(of: 1_000) == 250)
        #expect(ConsumptionFraction.oneHalf.quantity(of: 750) == 375)
        #expect(ConsumptionFraction.twoThirds.quantity(of: 900) == 600)
    }

    @Test func roundsSmallContinuousAmountsWithoutExceedingAvailability() {
        #expect(ConsumptionFraction.oneEighth.quantity(of: 3) == 1)
        #expect(ConsumptionFraction.sevenEighths.quantity(of: 1) == 1)
        #expect(ConsumptionFraction.oneHalf.quantity(of: 0) == 0)
    }
}
