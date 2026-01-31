import SwiftUI

struct LabAffiliationView: View {
    @State private var selectedLab: LabAffiliation?
    @State private var searchText = ""
    @State private var isCustom = false
    @State private var customLabName = ""
    @Environment(\.dismiss) var dismiss

    let labs: [LabAffiliation] = [
        LabAffiliation(id: "1", name: "MIT Department of Materials Science", location: "Cambridge, MA"),
        LabAffiliation(id: "2", name: "Stanford Materials Research Lab", location: "Stanford, CA"),
        LabAffiliation(id: "3", name: "Harvard School of Engineering", location: "Cambridge, MA"),
        LabAffiliation(id: "4", name: "Berkeley Lab - Advanced Light Source", location: "Berkeley, CA"),
        LabAffiliation(id: "5", name: "Caltech Materials Science", location: "Pasadena, CA"),
    ]

    var filteredLabs: [LabAffiliation] {
        if searchText.isEmpty {
            return labs
        }
        return labs.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.2, blue: 0.3),
                    Color(red: 0.15, green: 0.25, blue: 0.35)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("Lab Affiliation")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)

                    Text("Select or create your lab affiliation")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)

                // Search bar
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white.opacity(0.5))

                    TextField("Search labs...", text: $searchText)
                        .textInputAutocapitalization(.words)
                        .foregroundColor(.white)

                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                }
                .padding(12)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal, 20)

                // Lab list
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(filteredLabs) { lab in
                            LabCard(
                                lab: lab,
                                isSelected: selectedLab?.id == lab.id,
                                action: { selectedLab = lab }
                            )
                        }

                        // Create custom lab
                        Button(action: { isCustom = true }) {
                            HStack(spacing: 12) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.blue)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Create New Lab")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)

                                    Text("Add a lab not listed above")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.6))
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            .padding(16)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                            )
                        }

                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 20)
                }

                // Continue button
                Button(action: { dismiss() }) {
                    Text("Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                }
                .background(selectedLab != nil ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(8)
                .disabled(selectedLab == nil)
                .opacity(selectedLab == nil ? 0.6 : 1.0)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isCustom) {
            CreateLabSheet(isPresented: $isCustom) { labName in
                selectedLab = LabAffiliation(id: UUID().uuidString, name: labName, location: "")
            }
        }
    }
}

struct LabCard: View {
    let lab: LabAffiliation
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(lab.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)

                    if !lab.location.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.caption)
                            Text(lab.location)
                                .font(.caption)
                        }
                        .foregroundColor(.white.opacity(0.6))
                    }
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .blue : .white.opacity(0.3))
            }
            .padding(16)
            .background(isSelected ? Color.blue.opacity(0.2) : Color.white.opacity(0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.transparent, lineWidth: 2)
            )
        }
    }
}

struct CreateLabSheet: View {
    @Binding var isPresented: Bool
    @State private var labName = ""
    let onCreated: (String) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.1, green: 0.2, blue: 0.3),
                        Color(red: 0.15, green: 0.25, blue: 0.35)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 20) {
                    Text("Create New Lab")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)

                    VStack(alignment: .leading, spacing: 8) {
                        Label("Lab Name", systemImage: "building.2.fill")
                            .font(.subheadline)
                            .foregroundColor(.white)

                        TextField("Enter lab name", text: $labName)
                            .textInputAutocapitalization(.words)
                            .padding(12)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                            .foregroundColor(.white)
                    }
                    .padding(16)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)

                    Spacer()

                    HStack(spacing: 12) {
                        Button("Cancel") { isPresented = false }
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .foregroundColor(.blue)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.blue, lineWidth: 1)
                            )

                        Button(action: {
                            onCreated(labName)
                            isPresented = false
                        }) {
                            Text("Create")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                        }
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .disabled(labName.isEmpty)
                    }
                }
                .padding(20)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct LabAffiliation: Identifiable {
    let id: String
    let name: String
    let location: String
}

extension Color {
    static var transparent: Color {
        Color.clear
    }
}

#Preview {
    NavigationStack {
        LabAffiliationView()
    }
}
