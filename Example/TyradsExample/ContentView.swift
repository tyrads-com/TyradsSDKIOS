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
            ScrollView {
                VStack(spacing: 16) {
                    FormSection(title: "Credentials") {
                        PlainField("API Key", text: $vm.apiKey)
                        Divider()
                        PlainField("API Secret", text: $vm.apiSecret)
                        Divider()
                        PlainField("Encryption Key", text: $vm.encKey)
                    }

                    FormSection(title: "Placement") {
                        PlainField("Engagement ID", text: $vm.engagementId)
                        Divider()
                        PlainField("Placement ID", text: $vm.placementId)
                    }

                    FormSection(title: "APNs Token") {
                        Text(vm.apnsToken ?? "Not available yet")
                            .font(.system(.footnote, design: .monospaced))
                            .foregroundColor(vm.apnsToken == nil ? .secondary : .primary)
                            .textSelection(.enabled)
                    }

                    FormSection(title: "User") {
                        PlainField("User ID (empty = default)", text: $vm.userId)
                        Divider()
                        AgeRow(selected: $vm.selectedAge)
                        Divider()
                        GenderRow(selected: $vm.selectedGender, label: vm.genderLabel)
                        Divider()
                        UserGroupField(text: $vm.userGroup, isJSON: vm.userGroupIsJSON)
                    }

                    Button(action: vm.showOfferwall) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12).fill(teal)
                            if vm.isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Label("Open Offerwall", systemImage: "play.fill")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(height: 50)
                    }
                    .disabled(vm.isLoading)
                }
                .padding(16)
            }
            .navigationTitle("Tyrads iOS SDK")
            .navigationBarTitleDisplayMode(.inline)
            .alert(vm.errorTitle ?? "Login Failed", isPresented: Binding(
                get: { vm.errorMessage != nil },
                set: { if !$0 { vm.errorTitle = nil; vm.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(vm.errorMessage ?? "")
            }
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

// MARK: - Shared Components

private struct FormSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.footnote)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, 16)
                .padding(.bottom, 6)
            VStack(spacing: 0) {
                content()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }
}

private struct PlainField: View {
    let placeholder: String
    @Binding var text: String

    init(_ placeholder: String, text: Binding<String>) {
        self.placeholder = placeholder
        self._text = text
    }

    var body: some View {
        TextField(placeholder, text: $text)
            .padding(.vertical, 4)
            .autocapitalization(.none)
            .autocorrectionDisabled()
    }
}

private struct UserGroupField: View {
    @Binding var text: String
    let isJSON: Bool?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            TextField("User Group (text or JSON)", text: $text)
                .font(.system(.body, design: .monospaced))
                .autocapitalization(.none)
                .autocorrectionDisabled()
            if let isJSON {
                Text(isJSON ? "Sent as JSON string" : "Sent as plain text")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct AgeRow: View {
    @Binding var selected: Int?

    var body: some View {
        HStack {
            Text("Age").foregroundColor(.secondary)
            Spacer()
            Menu {
                Button("Any") { selected = nil }
                ForEach(18...80, id: \.self) { age in
                    Button("\(age)") { selected = age }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(selected.map { "\($0)" } ?? "Any").foregroundColor(.primary)
                    Image(systemName: "chevron.up.chevron.down").font(.caption).foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

private struct GenderRow: View {
    @Binding var selected: Int?
    let label: String

    var body: some View {
        HStack {
            Text("Gender").foregroundColor(.secondary)
            Spacer()
            Menu {
                Button("Any")    { selected = nil }
                Button("Male")   { selected = 1 }
                Button("Female") { selected = 2 }
            } label: {
                HStack(spacing: 4) {
                    Text(selected == nil ? "Any" : label).foregroundColor(.primary)
                    Image(systemName: "chevron.up.chevron.down").font(.caption).foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ContentView()
}
