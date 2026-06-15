import SwiftUI
import TyradsSDKIOS

private let teal = Color(red: 2/255, green: 181/255, blue: 190/255)

// MARK: - Root

struct ContentView: View {
    @StateObject private var vm = ContentViewModel()

    var body: some View {
        TabView {
            OfferwallTab(vm: vm)
                .tabItem { Label("Offerwall", systemImage: "play.rectangle.fill") }
            WidgetTab(vm: vm)
                .tabItem { Label("Premium Widgets", systemImage: "rectangle.stack.fill") }
        }
        .accentColor(teal)
        .onAppear { vm.loadStoredAndInit() }
    }
}

// MARK: - Offerwall Tab

private struct OfferwallTab: View {
    @ObservedObject var vm: ContentViewModel

    var body: some View {
        NavigationView {
            List {
                // Environment
                Section("Environment") {
                    Picker("Config", selection: $vm.selectedConfig) {
                        ForEach(vm.configOptions) { opt in
                            Text(opt.label).tag(opt.value)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                    .onChange(of: vm.selectedConfig) { vm.onConfigChanged($0) }
                }

                // Credentials
                Section("Credentials") {
                    LabeledField("API Key", text: $vm.apiKey)
                    LabeledField("API Secret", text: $vm.apiSecret)
                    LabeledField("Encryption Key", text: $vm.encKey)
                }

                // Placement
                Section("Placement") {
                    LabeledField("Engagement ID", text: $vm.engagementId)
                    LabeledField("Placement ID", text: $vm.placementId)
                }

                // User
                Section("User") {
                    LabeledField("User ID (empty = default)", text: $vm.userId)
                    AgeRow(selected: $vm.selectedAge)
                    GenderRow(selected: $vm.selectedGender, label: vm.genderLabel)
                }

                // CTA
                Section {
                    Button(action: vm.showOfferwall) {
                        HStack {
                            Spacer()
                            if vm.isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Label("Open Offerwall", systemImage: "play.fill")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 6)
                    }
                    .listRowBackground(teal)
                    .disabled(vm.isLoading)
                }
            }
            .navigationTitle("Tyrads iOS SDK")
            .navigationBarTitleDisplayMode(.automatic)
        }
        .navigationViewStyle(.stack)
    }
}

// MARK: - Widget Tab

private struct WidgetTab: View {
    @ObservedObject var vm: ContentViewModel

    var body: some View {
        VStack(spacing: 0) {
            Text("Premium Widget")
                .font(.largeTitle.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)

            HStack(spacing: 0) {
                ForEach([(true, "Slider"), (false, "List")], id: \.0) { (isSlider, label) in
                    Button(label) { vm.widgetIsSlider = isSlider }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(vm.widgetIsSlider == isSlider ? Color(.systemBackground) : Color.clear)
                        .foregroundColor(.primary)
                        .cornerRadius(7)
                }
            }
            .padding(2)
            .background(Color(.systemFill))
            .cornerRadius(9)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            
            Spacer()

            Tyrads.instance.topOffersWidget(widgetStyle: vm.widgetStyle)
                .frame(height: vm.widgetIsSlider ? 340 : 320)
                .padding(.horizontal, 16)

            Spacer()
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - List Row Components

private struct LabeledField: View {
    let label: String
    @Binding var text: String

    init(_ label: String, text: Binding<String>) {
        self.label = label
        self._text = text
    }

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
                .frame(width: 130, alignment: .leading)
            TextField(label, text: $text)
                .autocapitalization(.none)
                .autocorrectionDisabled()
        }
    }
}

private struct AgeRow: View {
    @Binding var selected: Int?

    var body: some View {
        HStack {
            Text("Age").foregroundColor(.secondary).frame(width: 130, alignment: .leading)
            Menu {
                Button("Any") { selected = nil }
                ForEach(18...80, id: \.self) { age in
                    Button("\(age)") { selected = age }
                }
            } label: {
                HStack {
                    Text(selected.map { "\($0)" } ?? "Any")
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

private struct GenderRow: View {
    @Binding var selected: Int?
    let label: String

    var body: some View {
        HStack {
            Text("Gender").foregroundColor(.secondary).frame(width: 130, alignment: .leading)
            Menu {
                Button("Any")    { selected = nil }
                Button("Male")   { selected = 1 }
                Button("Female") { selected = 2 }
            } label: {
                HStack {
                    Text(selected == nil ? "Any" : label)
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
