//
//  AddVacationView.swift
//  Roam
//
//  Created by Eswar Karavadi on 11/2/25.
//

import SwiftUI
import PhotosUI

struct AddVacationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var vacationTitle = ""
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var isUploading = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Vacation Details") {
                    TextField("Trip Name", text: $vacationTitle)
                        .textInputAutocapitalization(.words)
                }
                
                Section("Photos") {
                    PhotosPicker(
                        selection: $selectedPhotos,
                        maxSelectionCount: 50,
                        matching: .images
                    ) {
                        Label("Select Photos", systemImage: "photo.on.rectangle.angled")
                    }
                    
                    if !selectedPhotos.isEmpty {
                        Text("\(selectedPhotos.count) photo(s) selected")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Text("Upload photos from your vacation and we'll automatically generate an itinerary using AI!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section {
                    Button(action: handleUpload) {
                        if isUploading {
                            HStack {
                                ProgressView()
                                Text("Uploading...")
                            }
                        } else {
                            Text("Create Vacation")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(vacationTitle.isEmpty || selectedPhotos.isEmpty || isUploading)
                }
            }
            .navigationTitle("Add Vacation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func handleUpload() {
        // TODO: Implement photo upload and AI processing
        isUploading = true
        
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            isUploading = false
            dismiss()
        }
    }
}

#Preview {
    AddVacationView()
}

