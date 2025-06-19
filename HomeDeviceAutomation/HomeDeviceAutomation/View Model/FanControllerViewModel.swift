import Foundation
import HomeKit
import Combine

class FanControllerViewModel: NSObject, ObservableObject, HMAccessoryDelegate { // conform here
    @Published var fanStates: [UUID: Bool] = [:]
    @Published var automationStates: [UUID: Bool] = [:] // add this for automation toggling
    
    private let automationViewModel: AutomationViewModel
    private let homeKitManager: HomeKitManager

    init(homeKitManager: HomeKitManager, automationViewModel: AutomationViewModel) {
        self.homeKitManager = homeKitManager
        self.automationViewModel = automationViewModel
        super.init()
        observeFanAccessories()
        /*refreshAutomationStates()*/ // <- Add this
    }


    func observeFanAccessories() {
        guard homeKitManager.selectedHome != nil else { return }

        for accessory in homeKitManager.getFanAccessories() {
            accessory.delegate = self // now valid because of conformance

            if let service = accessory.services.first(where: { $0.serviceType == HMServiceTypeFan }),
               let powerChar = service.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypePowerState }) {

                powerChar.enableNotification(true) { error in
                    if let error = error {
                        print("Error enabling Fan notification: \(error.localizedDescription)")
                    }
                }

                powerChar.readValue { [weak self] error in
                    if let isOn = powerChar.value as? NSNumber {
                        DispatchQueue.main.async {
                            self?.fanStates[accessory.uniqueIdentifier] = isOn.boolValue
                        }
                    }
                }
            }
        }
    }

    func toggleFan(_ accessory: HMAccessory, isOn: Bool) {
        fanStates[accessory.uniqueIdentifier] = isOn
        guard let service = accessory.services.first(where: { $0.serviceType == HMServiceTypeFan }),
              let powerChar = service.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypePowerState }) else { return }

        powerChar.writeValue(isOn) { [weak self] error in
            if error == nil {
                DispatchQueue.main.async {
                    self?.fanStates[accessory.uniqueIdentifier] = isOn
                }
            }
        }
        
    }

    func toggleAutomation(for accessory: HMAccessory, isEnabled: Bool) {
        automationStates[accessory.uniqueIdentifier] = isEnabled
        DispatchQueue.main.async {
            self.automationStates[accessory.uniqueIdentifier] = isEnabled
        }

        guard let home = homeKitManager.selectedHome else {
            print("No selected home for automation")
            return
        }

        let triggerNameOn = "Turn Fan On Trigger Above 25.0°C"
        let triggerNameOff = "Turn Fan Off Trigger Below 20.0°C"

        if isEnabled {
            print("Enabling automation for fan: \(accessory.name)")
            automationViewModel.setTriggerEnabled(true, for: home, triggerName: triggerNameOn)
            automationViewModel.setTriggerEnabled(true, for: home, triggerName: triggerNameOff)
        } else {
            print("Disabling automation for fan: \(accessory.name)")
            automationViewModel.setTriggerEnabled(false, for: home, triggerName: triggerNameOn)
            automationViewModel.setTriggerEnabled(false, for: home, triggerName: triggerNameOff)
        }
    }

    // Methods to update states from HomeKit events if needed
    func updateFanState(_ accessory: HMAccessory, isOn: Bool) {
        DispatchQueue.main.async {
            self.fanStates[accessory.uniqueIdentifier] = isOn
        }
    }

    func updateAutomationState(_ accessory: HMAccessory, isEnabled: Bool) {
        DispatchQueue.main.async {
            self.automationStates[accessory.uniqueIdentifier] = isEnabled
        }
    }
    
//    func refreshAutomationStates() {
//        guard let home = homeKitManager.selectedHome else { return }
//
//        for accessory in homeKitManager.getFanAccessories() {
//            let uuid = accessory.uniqueIdentifier
//
//            let triggerNameOn = "Turn Fan On Trigger Above 25.0°C"
//            let triggerNameOff = "Turn Fan Off Trigger Below 20.0°C"
//
//            let triggerOn = automationViewModel.existingTrigger(named: triggerNameOn, in: home)
//            let triggerOff = automationViewModel.existingTrigger(named: triggerNameOff, in: home)
//
//            let isEnabled = (triggerOn?.isEnabled ?? false) && (triggerOff?.isEnabled ?? false)
//
//            DispatchQueue.main.async {
//                self.automationStates[uuid] = isEnabled
//            }
//        }
//    }

    
    func accessory(_ accessory: HMAccessory, service: HMService, didUpdateValueFor characteristic: HMCharacteristic) {
        if characteristic.characteristicType == HMCharacteristicTypePowerState,
           let value = characteristic.value as? NSNumber {
            DispatchQueue.main.async {
                self.fanStates[accessory.uniqueIdentifier] = value.boolValue
            }
        }
    }
}
