import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                Section("Account") {
                    Button(role: .destructive) {
                        authViewModel.signOut()
                    } label: {
                        Text("Sign Out")
                    }
                }

                Section("Data & Privacy") {
                    NavigationLink("Privacy Policy") { PrivacyPolicyView() }
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Text("Delete My Account & All Data")
                    }
                }
            }
            .navigationTitle("Settings")
            .confirmationDialog(
                "Delete Account",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Everything", role: .destructive) {
                    // TODO: Call DELETE /api/users/:id then sign out
                    authViewModel.signOut()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete your account, all photos, and AI-generated images. This cannot be undone.")
            }
        }
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            Text("Privacy Policy content here.")
                .padding()
        }
        .navigationTitle("Privacy Policy")
    }
}
