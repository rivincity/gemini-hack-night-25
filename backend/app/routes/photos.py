from flask import Blueprint, request, jsonify
from app.middleware.auth_middleware import require_auth, get_current_user
from app.services.supabase_service import get_supabase_client, upload_file_to_storage, get_public_url
from app.services.exif_service import extract_exif_data, create_thumbnail
import uuid

bp = Blueprint('photos', __name__, url_prefix='/api/photos')


@bp.route('/upload/batch', methods=['POST'])
def upload_batch():
    """Upload multiple photos at once (from iOS album picker)"""
    try:
        # Use a default user ID for demo (no auth required)
        user_id = "demo-user-123"

        # Get files from request
        if 'photos' not in request.files:
            return jsonify({'error': 'No photos provided'}), 400

        files = request.files.getlist('photos')

        if not files or len(files) == 0:
            return jsonify({'error': 'No photos provided'}), 400

        print(f"Processing {len(files)} photos for user {user_id}")

        # Process photos sequentially
        processed_photos = []

        for file in files:
            try:
                result = process_single_photo(file, user_id)
                if result:
                    processed_photos.append(result)
            except Exception as e:
                print(f"Error processing photo: {str(e)}")

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
        # Read file data
        file_data = file.read()

        # Extract EXIF data
        exif_data = extract_exif_data(file_data)

        # Generate unique filename
        photo_id = str(uuid.uuid4())
        file_extension = file.filename.split('.')[-1] if '.' in file.filename else 'jpg'
        filename = f"{photo_id}.{file_extension}"

        # Upload original photo
        file_path = f"photos/{user_id}/{filename}"
        upload_file_to_storage('photos', file_path, file_data, file.content_type)

        # Get public URL
        photo_url = get_public_url('photos', file_path)

        # Create and upload thumbnail
        thumbnail_data = create_thumbnail(file_data)
        thumbnail_path = f"thumbnails/{user_id}/{filename}"
        upload_file_to_storage('photos', thumbnail_path, thumbnail_data, 'image/jpeg')

        # Get thumbnail URL
        thumbnail_url = get_public_url('photos', thumbnail_path)

        # Build response
        photo_metadata = {
            'id': photo_id,
            'imageURL': photo_url,
            'thumbnailURL': thumbnail_url,
            'captureDate': exif_data.get('capture_date'),
            'location': exif_data.get('coordinates'),
            'hasExif': exif_data.get('has_exif', False)
        }

        return photo_metadata

    except Exception as e:
        print(f"Error processing single photo: {str(e)}")
        return None


@bp.route('/upload', methods=['POST'])
def upload_single():
    """Upload a single photo"""
    try:
        # Use a default user ID for demo (no auth required)
        user_id = "demo-user-123"

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
