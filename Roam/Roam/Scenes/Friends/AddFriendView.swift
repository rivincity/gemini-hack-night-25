//
//  AddFriendView.swift
//  Roam
//
//  Created by Eswar Karavadi on 11/2/25.
//

import SwiftUI
import MessageUI

struct AddFriendView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var showContactPicker = false
    @State private var showMailComposer = false
    @State private var showMessageComposer = false
    @State private var selectedContact: ContactInfo?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
    var body: some View {
        NavigationStack {
            List {
                // Search by email section
                Section {
                    TextField("friend@example.com", text: $searchText)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                    
                    if !searchText.isEmpty && isValidEmail(searchText) {
                        Button(action: sendFriendRequestByEmail) {
                            HStack {
                                Image(systemName: "person.badge.plus")
                                Text("Send Friend Request")
                                Spacer()
                                if isLoading {
                                    ProgressView()
                                }
                            }
                        }
                        .disabled(isLoading)
                    }
                } header: {
                    Text("Add by Email")
                } footer: {
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                    } else if let success = successMessage {
                        Text(success)
                            .foregroundColor(.green)
                    }
                }
                
                // Import from contacts section
                Section {
                    Button(action: { showContactPicker = true }) {
                        HStack {
                            Image(systemName: "person.crop.circle.badge.plus")
                                .foregroundColor(.blue)
                            Text("Add from Contacts")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Import from Contacts")
                } footer: {
                    Text("Select contacts from your phone to invite them to Roam or add them as friends if they already have an account.")
                }
            }
            .navigationTitle("Add Friend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showContactPicker) {
                ContactPickerView { contact in
                    selectedContact = contact
                    handleContactSelection(contact)
                }
            }
            .sheet(isPresented: $showMailComposer) {
                if let contact = selectedContact {
                    MailComposerView(
                        recipients: [contact.email ?? ""],
                        subject: "Join me on Roam!",
                        body: """
                        Hey \(contact.name),
                        
                        I'm using Roam to share my travel adventures with friends. Join me and let's explore the world together!
                        
                        Download Roam: [App Store Link]
                        
                        See you there!
                        """
                    )
                }
            }
            .alert("Invite Friend", isPresented: $showMessageComposer) {
                Button("Send SMS") {
                    sendSMSInvite()
                }
                Button("Send Email") {
                    showMailComposer = true
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                if let contact = selectedContact {
                    Text("How would you like to invite \(contact.name)?")
                }
            }
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,64}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES[c] %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func sendFriendRequestByEmail() {
        guard isValidEmail(searchText) else {
            errorMessage = "Please enter a valid email address"
            return
        }
        
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        Task {
            do {
                try await APIService.shared.sendFriendRequest(email: searchText)
                successMessage = "Friend request sent! 🎉"
                searchText = ""
                
                // Dismiss after 2 seconds
                try await Task.sleep(nanoseconds: 2_000_000_000)
                dismiss()
            } catch {
                if let apiError = error as? APIError {
                    errorMessage = apiError.errorDescription
                } else {
                    errorMessage = "Failed to send friend request: \(error.localizedDescription)"
                }
            }
            isLoading = false
        }
    }
    
    private func handleContactSelection(_ contact: ContactInfo) {
        guard let email = contact.email else {
            // No email, show invite options
            showMessageComposer = true
            return
        }
        
        // Try to add as friend by email
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        Task {
            do {
                try await APIService.shared.sendFriendRequest(email: email)
                successMessage = "Friend request sent to \(contact.name)! 🎉"
                
                // Dismiss after 2 seconds
                try await Task.sleep(nanoseconds: 2_000_000_000)
                dismiss()
            } catch APIError.notFound {
                // User not found, offer to invite
                showMessageComposer = true
            } catch {
                errorMessage = "Failed to add friend: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }
    
    private func sendSMSInvite() {
        guard let contact = selectedContact, let phone = contact.phoneNumber else { return }
        
        let message = "Hey! Check out Roam - let's share our travel adventures! [App Store Link]"
        let urlString = "sms:\(phone)&body=\(message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Mail Composer View
struct MailComposerView: UIViewControllerRepresentable {
    let recipients: [String]
    let subject: String
    let body: String
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = context.coordinator
        composer.setToRecipients(recipients)
        composer.setSubject(subject)
        composer.setMessageBody(body, isHTML: false)
        return composer
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(dismiss: dismiss)
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let dismiss: DismissAction
        
        init(dismiss: DismissAction) {
            self.dismiss = dismiss
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            dismiss()
        }
    }
}

#Preview {
    AddFriendView()
}

