import SwiftUI

/// View for creating a new sample
struct SampleCreateView: View {
    @Binding var isPresented: Bool
    let projectID: String
    var onSampleCreated: ((SampleDisplayItem) -> Void)?

    @State private var sampleName = ""
    @State private var sampleType = "Material"
    @State private var isLoading = false

    private let sampleTypes = ["Material", "Tissue", "Chemical", "Biological", "Other"]

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.09, green: 0.17, blue: 0.26),
                        Color(red: 0.12, green: 0.20, blue: 0.30)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                Form {
                    Section {
                        TextField("Sample Name", text: $sampleName)
                    } header: {
                        Text("Name")
                    }

                    Section {
                        Picker("Type", selection: $sampleType) {
                            ForEach(sampleTypes, id: \.self) { type in
                                Text(type).tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                    } header: {
                        Text("Sample Type")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("New Sample")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createSample()
                    }
                    .disabled(sampleName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func createSample() {
        let newSample = SampleDisplayItem(
            id: UUID().uuidString,
            name: sampleName.trimmingCharacters(in: .whitespaces),
            type: sampleType,
            date: Date(),
            imageCount: 0,
            hasAnalysis: false,
            analysisStatus: .pending
        )
        onSampleCreated?(newSample)
        isPresented = false
    }
}

#Preview {
    SampleCreateView(isPresented: .constant(true), projectID: "1")
}
