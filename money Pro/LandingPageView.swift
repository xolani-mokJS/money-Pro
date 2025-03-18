import SwiftUI

struct LandingPageView: View {
    @State private var name = ""
    @State private var initialBalance = ""
    @State private var isTrackingStarted = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.pie.fill")
                .resizable()
                .frame(width: 100, height: 100)
                .padding(.top, 50)
            
            Text("MONEY PRO")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 20)
            
            Text("Before you can start tracking your finances.")
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Form {
                Section(header: Text("What should we call you?")) {
                    TextField("Preferred Name", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Section(header: Text("Bank balance plus cash on hand *")) {
                    TextField("Current Balance Total", text: $initialBalance)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
            .padding(.horizontal)
            
            Button(action: startTracking) {
                Text("Start Tracking")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            .disabled(name.isEmpty || initialBalance.isEmpty)
            
            Spacer()
        }
        .padding()
        .fullScreenCover(isPresented: $isTrackingStarted) {
            ContentView()
        }
    }
    
    private func startTracking() {
        if let balance = Double(initialBalance) {
            UserDefaults.standard.set(name, forKey: "userName")
            UserDefaults.standard.set(balance, forKey: "initialBalance")
            isTrackingStarted = true
        }
    }
}

#Preview {
    LandingPageView()
} 