import SwiftUI

struct PreferencesView: View {
    @State private var panelWidth = AppSettings.panelWidth
    @State private var topInset = AppSettings.topInset
    @State private var launchAtLogin = AppSettings.launchAtLogin
    @State private var launchAtLoginError: String?
    @State private var showLaunchAtLoginError = false

    var body: some View {
        Form {
            Section("Panel") {
                HStack {
                    Text("Width")
                    Slider(value: $panelWidth, in: 280...480, step: 10)
                    Text("\(Int(panelWidth)) pt")
                        .monospacedDigit()
                        .frame(width: 48, alignment: .trailing)
                }

                HStack {
                    Text("Top spacing")
                    Slider(value: $topInset, in: 60...160, step: 10)
                    Text("\(Int(topInset)) pt")
                        .monospacedDigit()
                        .frame(width: 48, alignment: .trailing)
                }
            }

            Section("Shortcuts") {
                LabeledContent("Toggle panel") {
                    ShortcutRecorderView()
                }
            }

            Section("General") {
                Toggle("Launch at login", isOn: $launchAtLogin)
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 420, height: 280)
        .onAppear {
            launchAtLogin = AppSettings.isLaunchAtLoginEnabled
        }
        .onChange(of: panelWidth) { _, value in
            AppSettings.panelWidth = value
            NotificationCenter.default.post(name: .panelWidthChanged, object: nil)
        }
        .onChange(of: topInset) { _, value in
            AppSettings.topInset = value
            NotificationCenter.default.post(name: .panelPreferencesChanged, object: nil)
        }
        .onChange(of: launchAtLogin) { oldValue, newValue in
            if let error = AppSettings.applyLaunchAtLogin(newValue) {
                launchAtLogin = oldValue
                launchAtLoginError = error
                showLaunchAtLoginError = true
            }
        }
        .alert("Launch at login", isPresented: $showLaunchAtLoginError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(launchAtLoginError ?? "")
        }
    }
}
