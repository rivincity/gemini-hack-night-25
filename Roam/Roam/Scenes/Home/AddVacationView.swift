//
//  AddVacationView.swift
//  Roam
//
//  Created by Eswar Karavadi on 11/2/25.
//

import SwiftUI
import PhotosUI
import Photos

struct AddVacationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var vacationTitle = ""
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var isUploading = false
    @State private var uploadProgress: Double = 0
    @State private var showError = false
    @State private var errorMessage = ""
    
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
                            VStack(spacing: 8) {
                                ProgressView(value: uploadProgress, total: 1.0)
                                Text("Uploading \(Int(uploadProgress * 100))%")
                                    .font(.caption)
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
        }
    }
    
    private func handleUpload() {
        print("🚀 [Upload] Starting upload process...")
        print("📝 [Upload] Title: \(vacationTitle)")
        print("📸 [Upload] Photos selected: \(selectedPhotos.count)")
        
        isUploading = true
        uploadProgress = 0
        
        Task {
            do {
                // Step 1: Load images and extract metadata (20%)
                print("📥 [Upload] Step 1: Loading photos and extracting metadata...")
                uploadProgress = 0.1
                let photosData = try await loadPhotosWithMetadata()
                uploadProgress = 0.2
                print("✅ [Upload] Loaded \(photosData.count) photos with metadata")
                
                // Step 2: Upload to backend (60%)
                print("☁️ [Upload] Step 2: Uploading to backend...")
                print("🌐 [Upload] Endpoint: \(APIConfig.Endpoints.uploadPhotosBatch)")
                uploadProgress = 0.3
                let vacation = try await uploadToBackend(photos: photosData)
                uploadProgress = 0.9
                print("✅ [Upload] Upload successful! Vacation ID: \(vacation.id)")
                
                // Step 3: Success (100%)
                uploadProgress = 1.0
                print("🎉 [Upload] Complete! Dismissing view...")
                try? await Task.sleep(nanoseconds: 500_000_000)
                
                isUploading = false
                dismiss()
                
            } catch {
                print("❌ [Upload] Error: \(error.localizedDescription)")
                print("❌ [Upload] Full error: \(error)")
                isUploading = false
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
    
    private func loadPhotosWithMetadata() async throws -> [(image: Data, metadata: VacationPhotoMetadata)] {
        print("📷 [Metadata] Loading \(selectedPhotos.count) photos...")
        var results: [(Data, VacationPhotoMetadata)] = []
        
        for (index, item) in selectedPhotos.enumerated() {
            print("📷 [Metadata] Processing photo \(index + 1)/\(selectedPhotos.count)...")
            
            // Load image data
            guard let imageData = try? await item.loadTransferable(type: Data.self) else {
                print("⚠️ [Metadata] Failed to load photo \(index + 1), skipping...")
                continue
            }
            
            print("✅ [Metadata] Photo \(index + 1) loaded, size: \(imageData.count) bytes")
            
            // Extract metadata from PhotosPickerItem
            var metadata = VacationPhotoMetadata()
            
            // Try to get PHAsset for EXIF data
            if let assetIdentifier = item.itemIdentifier {
                let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [assetIdentifier], options: nil)
                if let asset = fetchResult.firstObject {
                    metadata.latitude = asset.location?.coordinate.latitude
                    metadata.longitude = asset.location?.coordinate.longitude
                    metadata.timestamp = asset.creationDate?.ISO8601Format()
                    
                    if let lat = metadata.latitude, let lng = metadata.longitude {
                        print("📍 [Metadata] Photo \(index + 1) location: \(lat), \(lng)")
                    } else {
                        print("⚠️ [Metadata] Photo \(index + 1) has no location data")
                    }
                    
                    if let timestamp = metadata.timestamp {
                        print("🕐 [Metadata] Photo \(index + 1) timestamp: \(timestamp)")
                    }
                }
            }
            
            results.append((imageData, metadata))
            
            // Update progress
            let progress = 0.2 + (Double(index + 1) / Double(selectedPhotos.count)) * 0.1
            await MainActor.run {
                uploadProgress = progress
            }
        }
        
        print("✅ [Metadata] All photos loaded: \(results.count) photos ready")
        return results
    }
    
    private func uploadToBackend(photos: [(image: Data, metadata: VacationPhotoMetadata)]) async throws -> Vacation {
        print("🌐 [Backend] Preparing upload to backend...")
        
        guard let url = URL(string: APIConfig.Endpoints.uploadPhotosBatch) else {
            print("❌ [Backend] Invalid URL: \(APIConfig.Endpoints.uploadPhotosBatch)")
            throw UploadError.invalidURL
        }
        
        print("🌐 [Backend] URL: \(url.absoluteString)")
        
        // Create multipart form data
        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Add auth token if available
        if let token = AuthService.shared.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("🔐 [Backend] Auth token added")
        } else {
            print("⚠️ [Backend] No auth token available")
        }
        
        var body = Data()
        
        // Add vacation title
        print("📝 [Backend] Adding title: \(vacationTitle)")
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"title\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(vacationTitle)\r\n".data(using: .utf8)!)
        
        // Add photos
        print("📸 [Backend] Adding \(photos.count) photos to request...")
        for (index, (imageData, metadata)) in photos.enumerated() {
            print("📸 [Backend] Adding photo \(index + 1)/\(photos.count), size: \(imageData.count) bytes")
            
            // Add image
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"photos\"; filename=\"photo\(index).jpg\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(imageData)
            body.append("\r\n".data(using: .utf8)!)
            
            // Add metadata
            if let metadataJSON = try? JSONEncoder().encode(metadata),
               let metadataString = String(data: metadataJSON, encoding: .utf8) {
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"metadata[\(index)]\"\r\n\r\n".data(using: .utf8)!)
                body.append("\(metadataString)\r\n".data(using: .utf8)!)
                print("📍 [Backend] Metadata for photo \(index + 1): \(metadataString)")
            }
            
            // Update progress
            let progress = 0.3 + (Double(index + 1) / Double(photos.count)) * 0.6
            await MainActor.run {
                uploadProgress = progress
            }
        }
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        print("📦 [Backend] Request body size: \(body.count) bytes")
        print("🚀 [Backend] Sending request to server...")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        print("📥 [Backend] Received response")
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ [Backend] Invalid response type")
            throw UploadError.invalidResponse
        }
        
        print("📊 [Backend] Status code: \(httpResponse.statusCode)")
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("📄 [Backend] Response body: \(responseString)")
        }
        
        guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            print("❌ [Backend] Server error with status code: \(httpResponse.statusCode)")
            throw UploadError.serverError(httpResponse.statusCode)
        }
        
        print("🎯 [Backend] Decoding response...")
        
        // Backend returns photo upload response, not vacation object
        // We need to create a vacation from the uploaded photos
        struct UploadResponse: Codable {
            let count: Int
            let message: String
            let photos: [UploadedPhoto]
        }
        
        struct UploadedPhoto: Codable {
            let id: String
            let imageURL: String
            let thumbnailURL: String?
            let captureDate: String?
            let location: LocationData?
            let hasExif: Bool
        }
        
        struct LocationData: Codable {
            let latitude: Double
            let longitude: Double
        }
        
        let uploadResponse = try JSONDecoder().decode(UploadResponse.self, from: data)
        print("✅ [Backend] Successfully decoded: \(uploadResponse.count) photos uploaded")
        
        // Create a vacation object from the uploaded photos
        let locations = uploadResponse.photos.compactMap { photo -> VacationLocation? in
            guard let location = photo.location else { return nil }
            
            let coordinate = Coordinate(latitude: location.latitude, longitude: location.longitude)
            let photoObj = Photo(
                id: UUID(uuidString: photo.id) ?? UUID(),
                imageURL: photo.imageURL,
                captureDate: Date()
            )
            
            return VacationLocation(
                name: "Unknown Location", // TODO: Reverse geocode
                coordinate: coordinate,
                visitDate: Date(),
                photos: [photoObj],
                activities: []
            )
        }
        
        let vacation = Vacation(
            title: vacationTitle,
            startDate: Date(),
            endDate: Date(),
            locations: locations
        )
        
        print("✅ [Backend] Created vacation with \(locations.count) locations")
        return vacation
    }
}

// MARK: - Photo Metadata (for upload)
private struct VacationPhotoMetadata: Codable {
    var latitude: Double?
    var longitude: Double?
    var timestamp: String?
}

// MARK: - Upload Errors
enum UploadError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(Int)
    case noPhotosSelected
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid server URL"
        case .invalidResponse:
            return "Invalid server response"
        case .serverError(let code):
            return "Server error (code: \(code))"
        case .noPhotosSelected:
            return "No photos selected"
        }
    }
}

#Preview {
    AddVacationView()
}

