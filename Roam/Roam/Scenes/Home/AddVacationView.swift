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
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    @State private var createdVacation: Vacation?
    
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
                                Text("Creating Vacation...")
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
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .alert("Success!", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                if let vacation = createdVacation {
                    Text("Vacation \"\(vacation.title)\" has been created with \(vacation.locations.count) locations!")
                } else {
                    Text("Vacation created successfully!")
                }
            }
        }
    }
    
    private func handleUpload() {
        guard !vacationTitle.isEmpty, !selectedPhotos.isEmpty else {
            return
        }
        
        isUploading = true
        
        Task {
            do {
                print("📸 Starting vacation creation process...")
                print("📝 Title: \(vacationTitle)")
                print("📷 Photos: \(selectedPhotos.count)")
                
                // Step 1: Convert PhotosPickerItems to UIImage/Data
                let imageData = try await loadImagesFromPickerItems(selectedPhotos)
                print("✅ Loaded \(imageData.count) images")
                
                // Step 2: Upload photos
                let uploadedPhotos = try await uploadPhotosBatch(imageData)
                print("✅ Uploaded \(uploadedPhotos.count) photos")
                
                // Step 3: Generate itinerary with AI
                let vacation = try await generateItineraryFromPhotos(uploadedPhotos, title: vacationTitle)
                print("✅ Created vacation: \(vacation.title)")
                
                // Success!
                await MainActor.run {
                    self.createdVacation = vacation
                    self.isUploading = false
                    self.showSuccess = true
                }
                
            } catch {
                print("❌ ERROR: Vacation creation failed")
                print("🔍 Error type: \(type(of: error))")
                print("📝 Error description: \(error.localizedDescription)")
                
                await MainActor.run {
                    self.isUploading = false
                    self.errorMessage = formatError(error)
                    self.showError = true
                }
            }
        }
    }
    
    private func loadImagesFromPickerItems(_ items: [PhotosPickerItem]) async throws -> [Data] {
        var imageDataArray: [Data] = []
        
        for item in items {
            // Use loadTransferable to get image data
            // For JPEG and HEIC formats, EXIF metadata is preserved in the raw data
            // The backend will extract GPS coordinates and dates from EXIF
            if let data = try? await item.loadTransferable(type: Data.self) {
                // Use original data directly without conversion
                // This preserves EXIF metadata (GPS, dates, etc.) if present
                // Backend's exif_service.py will extract this automatically
                imageDataArray.append(data)
                print("✅ Loaded photo data (EXIF will be extracted by backend)")
            } else {
                print("⚠️ Failed to load photo data")
            }
        }
        
        return imageDataArray
    }
    
    private func uploadPhotosBatch(_ imageData: [Data]) async throws -> [PhotoMetadata] {
        guard let url = URL(string: APIConfig.Endpoints.uploadPhotosBatch) else {
            throw APIError.invalidResponse
        }

        guard let token = AuthService.shared.authToken else {
            print("❌ ERROR: No auth token available")
            throw APIError.unauthorized
        }

        print("✅ DEBUG: Starting photo upload")
        print("📸 DEBUG: Uploading \(imageData.count) photos")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        // Create multipart/form-data body
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        for (index, data) in imageData.enumerated() {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"photos\"; filename=\"photo\(index).jpg\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(data)
            body.append("\r\n".data(using: .utf8)!)
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        let (responseData, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        print("📡 DEBUG: Upload response status: \(httpResponse.statusCode)")

        if httpResponse.statusCode != 200 {
            let errorBody = String(data: responseData, encoding: .utf8) ?? "No error body"
            print("❌ ERROR: Upload failed with status \(httpResponse.statusCode)")
            print("📄 ERROR Response body: \(errorBody)")
            throw APIError.serverError(httpResponse.statusCode)
        }

        let uploadResponse = try JSONDecoder().decode(BatchUploadResponse.self, from: responseData)
        print("✅ DEBUG: Successfully uploaded \(uploadResponse.count) photos")
        return uploadResponse.photos
    }

    private func generateItineraryFromPhotos(_ photos: [PhotoMetadata], title: String) async throws -> Vacation {
        guard let url = URL(string: APIConfig.Endpoints.generateItinerary) else {
            throw APIError.invalidResponse
        }

        guard let token = AuthService.shared.authToken else {
            throw APIError.unauthorized
        }

        print("🤖 DEBUG: Starting AI itinerary generation")
        print("📸 DEBUG: Processing \(photos.count) photos")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        // Create request body
        let requestBody: [String: Any] = [
            "photos": photos.map { photo in
                var dict: [String: Any] = [
                    "imageURL": photo.imageURL,
                    "captureDate": photo.captureDate ?? ""
                ]
                if let location = photo.location {
                    dict["coordinates"] = [
                        "latitude": location.latitude,
                        "longitude": location.longitude
                    ]
                }
                return dict
            },
            "title": title
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (responseData, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        print("📡 DEBUG: AI generation response status: \(httpResponse.statusCode)")

        if httpResponse.statusCode != 201 && httpResponse.statusCode != 200 {
            let errorBody = String(data: responseData, encoding: .utf8) ?? "No error body"
            print("❌ ERROR: AI generation failed with status \(httpResponse.statusCode)")
            print("📄 ERROR Response body: \(errorBody)")
            throw APIError.serverError(httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let aiResponse = try decoder.decode(AIGenerationResponse.self, from: responseData)
        print("✅ DEBUG: Successfully generated vacation: \(aiResponse.vacation.title)")
        return aiResponse.vacation
    }
    
    private func formatError(_ error: Error) -> String {
        if let apiError = error as? APIError {
            switch apiError {
            case .unauthorized:
                return "You are not logged in. Please log in and try again."
            case .networkError:
                return "Network connection error. Check your internet connection."
            case .serverError(let code):
                return "Server error (code \(code)). Please try again later."
            case .decodingError:
                return "Failed to process server response. Please check backend logs."
            default:
                return "Failed to create vacation: \(error.localizedDescription)"
            }
        } else {
            return "Failed to create vacation: \(error.localizedDescription)"
        }
    }
}

#Preview {
    AddVacationView()
}

