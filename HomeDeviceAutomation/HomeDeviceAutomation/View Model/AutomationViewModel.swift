import Foundation
import HomeKit

class AutomationViewModel: NSObject, ObservableObject {
    
    func setupFanAutomation(for home: HMHome, lowerBound: Double, upperBound: Double, turnFanOn: Bool) {
        let sceneName = turnFanOn ? "Turn Fan On" : "Turn Fan Off"

        if let existingScene = home.actionSets.first(where: { $0.name == sceneName }) {
            //createTemperatureTrigger(for: home, scene: existingScene, temperatureThreshold: threshold)
            createTemperatureTriggers(for: home, scene: existingScene, lowerBound: lowerBound, upperBound: upperBound, turnFanOn: turnFanOn)
        } else {
            createFanScene(for: home, turnOn: turnFanOn) { scene in
                guard let scene = scene else { return }
                self.createTemperatureTriggers(for: home, scene: scene, lowerBound: lowerBound, upperBound: upperBound, turnFanOn: turnFanOn)
                //self.createTemperatureTrigger(for: home, scene: scene, temperatureThreshold: threshold)
            }
        }
    }
    
    func createFanScene(for home: HMHome, turnOn: Bool, completion: @escaping (HMActionSet?) -> Void) {
        let sceneName = turnOn ? "Turn Fan On" : "Turn Fan Off"
        let targetValue = NSNumber(value: turnOn)

        guard let fanAccessory = home.accessories.first(where: {
            $0.services.contains(where: { $0.serviceType == HMServiceTypeFan })
        }),
        let fanService = fanAccessory.services.first(where: { $0.serviceType == HMServiceTypeFan }),
        let powerCharacteristic = fanService.characteristics.first(where: {
            $0.characteristicType == HMCharacteristicTypePowerState
        }) else {
            print("Fan accessory/service/characteristic missing")
            completion(nil)
            return
        }

        home.addActionSet(withName: sceneName) { actionSet, error in
            if let error = error {
                print("Scene creation failed: \(error.localizedDescription)")
                completion(nil)
                return
            }

            guard let actionSet = actionSet else {
                print("Action set was nil after creation")
                completion(nil)
                return
            }

            let action = HMCharacteristicWriteAction(characteristic: powerCharacteristic, targetValue: targetValue)

            actionSet.addAction(action) { error in
                if let error = error {
                    print("Failed to add action to scene: \(error.localizedDescription)")
                } else {
                    print("Action added to scene '\(sceneName)' successfully.")
                }
                completion(actionSet)
            }
        }
    }

//    func setupTemperatureTrigger(in home: HMHome, temperatureThreshold: Double) {
//          // Find the temperature sensor accessory
//          guard let accessory = home.accessories.first(where: { accessory in
//              // Check for any temperature characteristic
//              accessory.services.contains(where: { service in
//                  service.characteristics.contains(where: {
//                      $0.characteristicType == HMCharacteristicTypeCurrentTemperature
//                  })
//              })
//          }) else {
//              print("No temperature sensor found")
//              return
//          }
//
//          // Find the temperature characteristic
//          guard let temperatureCharacteristic = accessory.services.flatMap({ $0.characteristics }).first(where: {
//              $0.characteristicType == HMCharacteristicTypeCurrentTemperature
//          }) else {
//              print("Temperature characteristic not found")
//              return
//          }
//        // Create a characteristic event for when temperature rises above 25°C
//        //let condition = HMCharacteristicThresholdCondition(thresholdValue: 25, comparisonOperator: .greaterThan)
//        
//        //let characteristicEvent = HMCharacteristicEvent(characteristic: temperatureCharacteristic, triggerValue: 25, condition: condition)
//        
//        // Create event trigger
//        let triggerName = "Temperature Above 25°C Trigger"
//        let eventTrigger = HMEventTrigger(name: triggerName, events: [characteristicEvent], predicate: nil)
//        
//        // Add the trigger to the home
//        home.addTrigger(eventTrigger) { error in
//            if let error = error {
//                print("Failed to add event trigger: \(error.localizedDescription)")
//            } else {
//                print("Event trigger added successfully!")
//            }
//        }
//    }
    
    func createTemperatureTriggers(for home: HMHome, scene: HMActionSet, lowerBound: Double, upperBound: Double, turnFanOn: Bool) {
        guard let tempAccessory = home.accessories.first(where: {
            $0.services.contains(where: { $0.serviceType == HMServiceTypeTemperatureSensor })
        }),
        let tempService = tempAccessory.services.first(where: {
            $0.serviceType == HMServiceTypeTemperatureSensor
        }),
        let tempCharacteristic = tempService.characteristics.first(where: {
            $0.characteristicType == HMCharacteristicTypeCurrentTemperature
        }) else {
            print("Temperature sensor/characteristic not found")
            return
        }

        let epsilon = 0.0001
        var triggerName: String
        var thresholdRange: HMNumberRange

        if turnFanOn {
            // Turn fan ON if temperature rises above upperBound
            triggerName = "\(scene.name) Trigger Above \(upperBound)°C"
            thresholdRange = HMNumberRange(
                minValue: NSNumber(value: upperBound + epsilon),
                maxValue: NSNumber(value: Double.greatestFiniteMagnitude)
            )
        } else {
            // Turn fan OFF if temperature falls below lowerBound
            triggerName = "\(scene.name) Trigger Below \(lowerBound)°C"
            thresholdRange = HMNumberRange(
                minValue: NSNumber(value: -Double.greatestFiniteMagnitude),
                maxValue: NSNumber(value: lowerBound - epsilon)
            )
        }

        if existingTrigger(named: triggerName, in: home) == nil {
            let thresholdEvent = HMCharacteristicThresholdRangeEvent(characteristic: tempCharacteristic, thresholdRange: thresholdRange)
            let trigger = HMEventTrigger(name: triggerName, events: [thresholdEvent], predicate: nil)

            home.addTrigger(trigger) { error in
                if let error = error {
                    print("Failed to add trigger '\(triggerName)': \(error.localizedDescription)")
                    return
                }
                trigger.addActionSet(scene) { error in
                    if let error = error {
                        print("Failed to link scene to trigger '\(triggerName)': \(error.localizedDescription)")
                    } else {
                        print("Trigger '\(triggerName)' linked to scene '\(scene.name)'")
                    }
                }
            }
        } else {
            print("Trigger '\(triggerName)' already exists, skipping creation.")
        }
    }


    
//    func createTemperatureTrigger(for home: HMHome, scene: HMActionSet, temperatureThreshold: Double) {
//        let triggerName = "\(scene.name) Trigger at \(temperatureThreshold)°C"
//        
//        if let _ = existingTrigger(named: triggerName, in: home) {
//            print("Trigger '\(triggerName)' already exists, skipping creation.")
//            return
//        }
//        
////        guard let tempAccessory = home.accessories.first(where: { accessory in
////            // Check for any temperature characteristic
////            accessory.services.contains(where: { service in
////                service.characteristics.contains(where: {
////                    $0.characteristicType == HMCharacteristicTypeCurrentTemperature
////                })
////            })
////        }) else {
////            print("No temperature sensor found")
////            return
////        }
////        print ("Temp accessory: \(tempAccessory)")
////
////        // Find the temperature characteristic
////        guard let tempCharacteristic = tempAccessory.services.flatMap({ $0.characteristics }).first(where: {
////            $0.characteristicType == HMCharacteristicTypeCurrentTemperature
////        }) else {
////            print("Temperature characteristic not found")
////            return
////        }
////
////        print("tempCharacteristic: \(tempCharacteristic)")
//
//        guard let tempAccessory = home.accessories.first(where: {
//            $0.services.contains(where: { $0.serviceType == HMServiceTypeTemperatureSensor })
//        }),
//        let tempService = tempAccessory.services.first(where: {
//            $0.serviceType == HMServiceTypeTemperatureSensor
//        }),
//        let tempCharacteristic = tempService.characteristics.first(where: {
//            $0.characteristicType == HMCharacteristicTypeCurrentTemperature
//            
//        }) else {
//            print("Temperature sensor/characteristic not found")
//            return
//        }
//        
//
//        let triggerValue = NSNumber(value: temperatureThreshold)
//        let tempEvent = HMCharacteristicEvent(characteristic: tempCharacteristic, triggerValue: triggerValue)
//        let trigger = HMEventTrigger(name: triggerName, events: [tempEvent], predicate: nil)
//        
//
//        home.addTrigger(trigger) { error in
//            if let error = error {
//                print("Failed to add trigger: \(error.localizedDescription)")
//                return
//            }
//
//            trigger.addActionSet(scene) { error in
//                if let error = error {
//                    print("Failed to link scene to trigger: \(error.localizedDescription)")
//                } else {
//                    print("Trigger '\(triggerName)' linked to scene '\(scene.name)'")
//                }
//            }
//        }
//    }

    
    func existingTrigger(named name: String, in home: HMHome) -> HMEventTrigger? {
        return home.triggers.compactMap { $0 as? HMEventTrigger }.first(where: { $0.name == name })
    }
    
    func setTriggerEnabled(_ enabled: Bool, for home: HMHome, triggerName: String) {
        guard let trigger = home.triggers.first(where: { $0.name == triggerName }) else {
            print("Trigger \(triggerName) not found")
            return
        }
        
        trigger.enable(enabled) { error in
            if let error = error {
                print("Failed to \(enabled ? "enable" : "disable") trigger: \(error.localizedDescription)")
            } else {
                print("Trigger '\(trigger.name)' \(enabled ? "enabled" : "disabled") successfully")
            }
        }
    }


}
