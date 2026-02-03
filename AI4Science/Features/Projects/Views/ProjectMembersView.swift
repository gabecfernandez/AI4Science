import SwiftUI

struct ProjectMembersView: View {
    let project: Project
    @State private var members: [ProjectMember] = []
    @State private var inviteEmail = ""
    @State private var selectedRole: String = "viewer"
    @State private var showInviteForm = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
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

            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Team Members")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)

                        Text("\(members.count) members")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }

                    Spacer()

                    Button(action: { showInviteForm = true }) {
                        Image(systemName: "person.badge.plus.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                    }
                }
                .padding(20)

                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(members) { member in
                            MemberCard(member: member) {
                                // Handle member action
                            }
                        }
                    }
                    .padding(20)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showInviteForm) {
            InviteMemberSheet(
                isPresented: $showInviteForm,
                projectName: project.title
            ) { email, role in
                let newMember = ProjectMember(
                    id: UUID().uuidString,
                    name: email,
                    email: email,
                    role: role,
                    joinedDate: Date()
                )
                members.append(newMember)
            }
        }
        .onAppear {
            loadMembers()
        }
    }

    private func loadMembers() {
        // Load project members
        members = [
            ProjectMember(id: "1", name: "You", email: "user@example.com", role: "owner", joinedDate: project.createdAt),
            ProjectMember(id: "2", name: "Dr. Smith", email: "smith@example.com", role: "editor", joinedDate: Date().addingTimeInterval(-86400 * 7)),
            ProjectMember(id: "3", name: "Jane Doe", email: "jane@example.com", role: "viewer", joinedDate: Date().addingTimeInterval(-86400 * 3))
        ]
    }
}

struct MemberCard: View {
    let member: ProjectMember
    let action: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.3))

                Text(String(member.name.prefix(1)))
                    .font(.headline)
                    .foregroundColor(.blue)
            }
            .frame(width: 44, height: 44)

            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(member.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)

                    if member.role == "owner" {
                        Label("Owner", systemImage: "crown.fill")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.3))
                            .foregroundColor(.orange)
                            .cornerRadius(4)
                    }
                }

                Text(member.email)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            // Role picker
            Menu {
                Button(action: {}) {
                    Label("Owner", systemImage: "crown.fill")
                }

                Button(action: {}) {
                    Label("Editor", systemImage: "pencil.circle.fill")
                }

                Button(action: {}) {
                    Label("Viewer", systemImage: "eye.circle.fill")
                }

                if member.role != "owner" {
                    Divider()

                    Button(role: .destructive, action: {}) {
                        Label("Remove", systemImage: "trash.circle.fill")
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle.fill")
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.08))
        .cornerRadius(10)
    }
}

struct InviteMemberSheet: View {
    @Binding var isPresented: Bool
    let projectName: String
    let onInvite: (String, String) -> Void
    @State private var email = ""
    @State private var role = "viewer"

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

                VStack(spacing: 20) {
                    Text("Invite Member")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)

                    VStack(alignment: .leading, spacing: 8) {
                        Label("Email Address", systemImage: "envelope.fill")
                            .font(.subheadline)
                            .foregroundColor(.white)

                        TextField("Enter email", text: $email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .padding(12)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                            .foregroundColor(.white)
                    }
                    .padding(16)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)

                    VStack(alignment: .leading, spacing: 8) {
                        Label("Role", systemImage: "person.badge.fill")
                            .font(.subheadline)
                            .foregroundColor(.white)

                        Picker("Role", selection: $role) {
                            Text("Viewer").tag("viewer")
                            Text("Editor").tag("editor")
                            Text("Owner").tag("owner")
                        }
                        .pickerStyle(.segmented)
                    }

                    Spacer()

                    HStack(spacing: 12) {
                        Button("Cancel") { isPresented = false }
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .foregroundColor(.blue)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.blue, lineWidth: 1)
                            )

                        Button(action: {
                            onInvite(email, role)
                            isPresented = false
                        }) {
                            Text("Send Invite")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                        }
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .disabled(email.isEmpty)
                    }
                }
                .padding(20)
            }
        }
    }
}

struct ProjectMember: Identifiable {
    let id: String
    let name: String
    let email: String
    let role: String
    let joinedDate: Date
}

// Preview disabled - Project constructor mismatch
// #Preview {
//     ProjectMembersView(...)
// }
