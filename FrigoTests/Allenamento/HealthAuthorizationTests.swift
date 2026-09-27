import HealthKit
import Testing
@testable import Frigo

@MainActor
struct HealthAuthorizationTests {
    @Test func deniedAndUndeterminedPermissionsNeverEnableSaving() {
        for status in [HKAuthorizationStatus.sharingDenied, .notDetermined] {
            let manager = HealthManager(authorizationStatus: { _ in status })
            manager.refreshAuthorization()
            #expect(!manager.canSaveWorkouts)
            #expect(!manager.canSaveEnergy)
            #expect(manager.workoutAuthorizationStatus == status)
        }
    }

    @Test func workoutAndEnergyPermissionsRemainIndependent() {
        for workoutAllowed in [false, true] {
            for energyAllowed in [false, true] {
                let manager = HealthManager(authorizationStatus: { type in
                    let allowed = type == HKObjectType.workoutType() ? workoutAllowed : energyAllowed
                    return allowed ? .sharingAuthorized : .sharingDenied
                })
                manager.refreshAuthorization()
                #expect(manager.canSaveWorkouts == workoutAllowed)
                #expect(manager.canSaveEnergy == energyAllowed)
            }
        }
    }

    @Test func revocationIsObservedBeforeSaving() async {
        var status = HKAuthorizationStatus.sharingAuthorized
        let manager = HealthManager(authorizationStatus: { _ in status })
        manager.refreshAuthorization()
        #expect(manager.canSaveWorkouts)
        status = .sharingDenied
        // This must return before calling the real HealthKit save API.
        await manager.saveAppWorkout(duration: 60, totalVolume: 500, date: .now)
        #expect(!manager.canSaveWorkouts)
        #expect(!manager.canSaveEnergy)
    }
}
