//
//  ContactPickerView.swift
//  Roam
//
//  Contact picker to select friends from phone contacts
//

import SwiftUI
import Contacts

struct ContactPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var contacts: [ContactInfo] = []
    @State private var searchText = ""
    @State private var isLoading = false
    @State private var permissionDenied = false
    
    let onSelectContact: (ContactInfo) -> Void
    
    var filteredContacts: [ContactInfo] {
        if searchText.isEmpty {
            return contacts
        }
        return contacts.filter { contact in
            contact.name.localizedCaseInsensitiveContains(searchText) ||
            (contact.email?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            (contact.phoneNumber?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if permissionDenied {
                    ContentUnavailableView(
                        "Contacts Access Denied",
                        systemImage: "person.crop.circle.badge.xmark",
                        description: Text("Please enable Contacts access in Settings to find friends")
                    )
                } else if isLoading {
                    ProgressView("Loading contacts...")
                } else if contacts.isEmpty {
                    ContentUnavailableView(
                        "No Contacts",
                        systemImage: "person.crop.circle",
                        description: Text("No contacts found on your device")
                    )
                } else {
                    List(filteredContacts) { contact in
                        Button(action: {
                            onSelectContact(contact)
                            dismiss()
                        }) {
                            ContactRow(contact: contact)
                        }
                    }
                    .searchable(text: $searchText, prompt: "Search contacts")
                }
            }
            .navigationTitle("Select Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                requestContactsAccess()
            }
        }
    }
    
    private func requestContactsAccess() {
        isLoading = true
        let store = CNContactStore()
        
        store.requestAccess(for: .contacts) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    fetchContacts(store: store)
                } else {
                    permissionDenied = true
                    isLoading = false
                }
            }
        }
    }
    
    private func fetchContacts(store: CNContactStore) {
        let keysToFetch: [CNKeyDescriptor] = [
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactEmailAddressesKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor
        ]
        
        let request = CNContactFetchRequest(keysToFetch: keysToFetch)
        
        var fetchedContacts: [ContactInfo] = []
        
        do {
            try store.enumerateContacts(with: request) { contact, _ in
                let name = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
                let email = contact.emailAddresses.first?.value as String?
                let phoneNumber = contact.phoneNumbers.first?.value.stringValue
                
                // Only include contacts with at least a name and either email or phone
                if !name.isEmpty && (email != nil || phoneNumber != nil) {
                    fetchedContacts.append(ContactInfo(
                        id: contact.identifier,
                        name: name,
                        email: email,
                        phoneNumber: phoneNumber
                    ))
                }
            }
            
            DispatchQueue.main.async {
                self.contacts = fetchedContacts.sorted { $0.name < $1.name }
                self.isLoading = false
            }
        } catch {
            print("Error fetching contacts: \(error)")
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
    }
}

// MARK: - Contact Row View
struct ContactRow: View {
    let contact: ContactInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(contact.name)
                .font(.headline)
            
            if let email = contact.email {
                Text(email)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let phone = contact.phoneNumber {
                Text(phone)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Contact Info Model
struct ContactInfo: Identifiable {
    let id: String
    let name: String
    let email: String?
    let phoneNumber: String?
}

#Preview {
    ContactPickerView { contact in
        print("Selected: \(contact.name)")
    }
}

