import SwiftUI
import HomeKit

struct FanView: View {
    @ObservedObject var fanViewModel: FanControllerViewModel
    @ObservedObject var homeKitManager: HomeKitManager
    @ObservedObject var automationViewModel: AutomationViewModel
    
    var accessory: HMAccessory

    var body: some View {
        VStack(alignment: .leading) {
            Text("Exhaust Fan")
                .font(.title)
                .padding(.top)

            Toggle(isOn: Binding(
                get: { fanViewModel.fanStates[accessory.uniqueIdentifier] ?? false },
                set: { fanViewModel.toggleFan(accessory, isOn: $0) }
            )) {
                Text("\(accessory.name) Power")
            }
            .frame(width: 350)
            .padding(.vertical, 4)
            
            if let home = homeKitManager.selectedHome {
                let onTriggerName = "Turn Fan On Trigger Above 25.0°C"
                let offTriggerName = "Turn Fan Off Trigger Below 20.0°C"

                let hasOnTrigger = automationViewModel.existingTrigger(named: onTriggerName, in: home) != nil
                let hasOffTrigger = automationViewModel.existingTrigger(named: offTriggerName, in: home) != nil

                if hasOnTrigger && hasOffTrigger {
                    Toggle(isOn: Binding(
                        get: { fanViewModel.automationStates[accessory.uniqueIdentifier] ?? false },
                        set: { fanViewModel.toggleAutomation(for: accessory, isEnabled: $0) }
                    )) {
                        Text("\(accessory.name) Automation")
                    }
                } else {
                    Text("Automation not configured")
                        .font(.title)
                        .padding(.top)
                    Button("Add scene") {
                        automationViewModel.setupFanAutomation(for: home, lowerBound: 20.0, upperBound: 25.0, turnFanOn: true)
                        automationViewModel.setupFanAutomation(for: home, lowerBound: 20.0, upperBound: 25.0, turnFanOn: false)
                        //automationViewModel.setupFanAutomation(for: home, lowerBound: 20.0, upperBound: 25.0, turnFanOn: false)
                        
                    }
                    .frame(width: 300)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(20)
                }
            } else {
                Text("No Home Selected")
                    .foregroundColor(.red)
            }

        }
        .onAppear {
            fanViewModel.observeFanAccessories()
        }
        
    }
}
