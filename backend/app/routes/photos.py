from flask import Blueprint, request, jsonify
from app.middleware.auth_middleware import require_auth, get_current_user
from app.services.supabase_service import get_supabase_client, upload_file_to_storage, get_public_url
from app.services.exif_service import extract_exif_data, create_thumbnail
import uuid
from concurrent.futures import ThreadPoolExecutor, as_completed

bp = Blueprint('photos', __name__, url_prefix='/api/photos')


@bp.route('/upload/batch', methods=['POST'])
@require_auth
def upload_batch():
    """Upload multiple photos at once (from iOS album picker)"""
    try:
        user = get_current_user()
        user_id = user.user.id

        # Get files from request
        print(f"📥 Received upload request for user {user_id}")
        print(f"📋 Request files keys: {list(request.files.keys())}")
        print(f"📋 Content-Type: {request.content_type}")
        
        if 'photos' not in request.files:
            print(f"❌ ERROR: 'photos' key not found in request.files")
            return jsonify({'error': 'No photos provided'}), 400

        files = request.files.getlist('photos')

        if not files or len(files) == 0:
            print(f"❌ ERROR: files list is empty")
            return jsonify({'error': 'No photos provided'}), 400

        print(f"✅ Processing {len(files)} photos for user {user_id}")
        for i, file in enumerate(files):
            print(f"  Photo {i+1}: filename={file.filename}, content_type={file.content_type}")

        # Process photos in parallel
        processed_photos = []

        with ThreadPoolExecutor(max_workers=5) as executor:
            futures = {
                executor.submit(process_single_photo, file, user_id): file
                for file in files
            }

            for future in as_completed(futures):
                try:
                    result = future.result(timeout=30)  # 30 second timeout per photo
                    if result:
                        processed_photos.append(result)
                        print(f"✅ Added processed photo to results")
                    else:
                        print(f"⚠️ Photo processing returned None")
                except Exception as e:
                    print(f"❌ ERROR: Exception in photo processing: {str(e)}")
                    import traceback
                    traceback.print_exc()

        if not processed_photos:
            return jsonify({'error': 'Failed to process any photos'}), 500

        return jsonify({
            'photos': processed_photos,
            'count': len(processed_photos),
            'message': f'Successfully uploaded {len(processed_photos)} photos'
        }), 200

    except Exception as e:
        print(f"Batch upload error: {str(e)}")
        return jsonify({'error': str(e)}), 500


def process_single_photo(file, user_id: str) -> dict:
    """Process a single photo: extract EXIF, create thumbnail, upload"""
    try:
        print(f"📸 Processing photo: {file.filename if file.filename else 'unnamed'}")
        
        # Read file data
        file_data = file.read()
        if not file_data or len(file_data) == 0:
            print(f"❌ ERROR: Empty file data for {file.filename}")
            return None
        
        print(f"✅ Read {len(file_data)} bytes from file")

        # Extract EXIF data
        try:
            exif_data = extract_exif_data(file_data)
            print(f"✅ EXIF extracted: has_exif={exif_data.get('has_exif')}, location={exif_data.get('coordinates')}")
        except Exception as exif_error:
            print(f"⚠️ EXIF extraction error (non-fatal): {str(exif_error)}")
            exif_data = {'has_exif': False, 'coordinates': None, 'capture_date': None}

        # Generate unique filename
        photo_id = str(uuid.uuid4())
        file_extension = file.filename.split('.')[-1] if file.filename and '.' in file.filename else 'jpg'
        filename = f"{photo_id}.{file_extension}"
        print(f"📝 Generated filename: {filename}")

        # Upload original photo
        try:
            file_path = f"photos/{user_id}/{filename}"
            print(f"⬆️ Uploading to: {file_path}")
            upload_file_to_storage('photos', file_path, file_data, file.content_type or 'image/jpeg')
            print(f"✅ Original photo uploaded")
        except Exception as upload_error:
            print(f"❌ ERROR: Failed to upload original photo: {str(upload_error)}")
            import traceback
            traceback.print_exc()
            return None

        # Get public URL
        photo_url = get_public_url('photos', file_path)
        if not photo_url:
            print(f"⚠️ WARNING: Could not get public URL for {file_path}")

        # Create and upload thumbnail
        try:
            print(f"🖼️ Creating thumbnail...")
            thumbnail_data = create_thumbnail(file_data)
            thumbnail_path = f"thumbnails/{user_id}/{filename}"
            upload_file_to_storage('photos', thumbnail_path, thumbnail_data, 'image/jpeg')
            print(f"✅ Thumbnail uploaded")
        except Exception as thumb_error:
            print(f"⚠️ WARNING: Thumbnail creation/upload failed (non-fatal): {str(thumb_error)}")
            thumbnail_data = None
            thumbnail_path = None

        # Get thumbnail URL
        thumbnail_url = get_public_url('photos', thumbnail_path) if thumbnail_path else None

        # Build response
        photo_metadata = {
            'id': photo_id,
            'imageURL': photo_url,
            'thumbnailURL': thumbnail_url,
            'captureDate': exif_data.get('capture_date'),
            'location': exif_data.get('coordinates'),
            'hasExif': exif_data.get('has_exif', False)
        }

        print(f"✅ Successfully processed photo {photo_id}")
        return photo_metadata

    except Exception as e:
        print(f"❌ ERROR: Error processing single photo: {str(e)}")
        import traceback
        traceback.print_exc()
        return None


@bp.route('/upload', methods=['POST'])
@require_auth
def upload_single():
    """Upload a single photo"""
    try:
        user = get_current_user()
        user_id = user.user.id

        if 'photo' not in request.files:
            return jsonify({'error': 'No photo provided'}), 400

        file = request.files['photo']

        if not file:
            return jsonify({'error': 'No photo provided'}), 400

        result = process_single_photo(file, user_id)

        if not result:
            return jsonify({'error': 'Failed to process photo'}), 500

        return jsonify(result), 200

    except Exception as e:
        print(f"Upload error: {str(e)}")
        return jsonify({'error': str(e)}), 500


@bp.route('/<vacation_id>', methods=['GET'])
@require_auth
def get_vacation_photos(vacation_id):
    """Get all photos for a vacation"""
    try:
        supabase = get_supabase_client()

        # Get all locations for this vacation
        locations_result = supabase.table('locations').select('id').eq('vacation_id', vacation_id).execute()

        if not locations_result.data:
            return jsonify({'photos': []}), 200

        location_ids = [loc['id'] for loc in locations_result.data]

        # Get all photos for these locations
        photos_result = supabase.table('photos').select('*').in_('location_id', location_ids).execute()

        photos = []
        for photo in photos_result.data:
            photos.append({
                'id': photo['id'],
                'imageURL': photo['image_url'],
                'thumbnailURL': photo.get('thumbnail_url'),
                'captureDate': photo.get('capture_date'),
                'location': {
                    'latitude': photo.get('latitude'),
                    'longitude': photo.get('longitude')
                } if photo.get('latitude') else None,
                'caption': photo.get('caption')
            })

        return jsonify({'photos': photos}), 200

    except Exception as e:
        print(f"Get photos error: {str(e)}")
        return jsonify({'error': str(e)}), 500
