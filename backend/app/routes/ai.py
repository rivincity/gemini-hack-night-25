from flask import Blueprint, request, jsonify
from app.middleware.auth_middleware import require_auth, get_current_user
from app.services.gemini_service import generate_itinerary_from_photos, analyze_single_photo
from app.services.supabase_service import get_supabase_client
import uuid

bp = Blueprint('ai', __name__, url_prefix='/api/ai')


@bp.route('/generate-itinerary', methods=['POST'])
def generate_itinerary():
    """
    Generate AI itinerary from uploaded photos

    Request body:
    {
        "photos": [
            {
                "imageURL": "https://...",
                "captureDate": "2024-10-01T10:30:00Z",
                "coordinates": {"latitude": 48.8566, "longitude": 2.3522}
            }
        ],
        "title": "European Adventure" (optional)
    }
    """
    try:
        # Use a default user ID for demo (no auth required)
        user_id = "demo-user-123"

        data = request.get_json()
        photos = data.get('photos', [])
        title = data.get('title', 'My Vacation')

        if not photos or len(photos) == 0:
            return jsonify({'error': 'No photos provided'}), 400

        print(f"Generating itinerary from {len(photos)} photos")

        # Generate itinerary using Gemini
        result = generate_itinerary_from_photos(photos)

        if result.get('error'):
            return jsonify({'error': result['error']}), 400

        # Create vacation in database
        vacation_id = str(uuid.uuid4())

        # Extract date range from photos
        dates = [p.get('captureDate') for p in photos if p.get('captureDate')]
        dates.sort()
        start_date = dates[0] if dates else None
        end_date = dates[-1] if dates else None

        vacation_data = {
            'id': vacation_id,
            'user_id': user_id,
            'title': title,
            'start_date': start_date,
            'end_date': end_date,
            'ai_itinerary': result['itinerary']
        }

        supabase = get_supabase_client()
        supabase.table('vacations').insert(vacation_data).execute()

        # Create locations
        for location in result['locations']:
            location_id = str(uuid.uuid4())

            location_data = {
                'id': location_id,
                'vacation_id': vacation_id,
                'name': location['name'],
                'latitude': location['coordinate']['latitude'],
                'longitude': location['coordinate']['longitude'],
                'visit_date': location.get('visitDate')
            }

            supabase.table('locations').insert(location_data).execute()

            # Create activities for this location
            for activity in location.get('activities', []):
                activity_data = {
                    'id': str(uuid.uuid4()),
                    'location_id': location_id,
                    'title': activity['title'],
                    'description': activity['description'],
                    'time': activity.get('time'),
                    'ai_generated': activity.get('aiGenerated', True)
                }

                supabase.table('activities').insert(activity_data).execute()

            # Associate photos with this location
            for photo in photos:
                photo_coords = photo.get('coordinates')
                if photo_coords:
                    # Check if photo is close to this location
                    photo_lat = photo_coords['latitude']
                    photo_lon = photo_coords['longitude']
                    loc_lat = location['coordinate']['latitude']
                    loc_lon = location['coordinate']['longitude']

                    # Simple distance check (within ~10km)
                    if abs(photo_lat - loc_lat) < 0.1 and abs(photo_lon - loc_lon) < 0.1:
                        photo_data = {
                            'id': str(uuid.uuid4()),
                            'location_id': location_id,
                            'image_url': photo['imageURL'],
                            'thumbnail_url': photo.get('thumbnailURL'),
                            'capture_date': photo.get('captureDate'),
                            'latitude': photo_lat,
                            'longitude': photo_lon
                        }

                        supabase.table('photos').insert(photo_data).execute()

        # Return complete vacation data
        return jsonify({
            'vacation': {
                'id': vacation_id,
                'title': title,
                'startDate': start_date,
                'endDate': end_date,
                'aiGeneratedItinerary': result['itinerary'],
                'locations': result['locations']
            },
            'message': 'Itinerary generated successfully'
        }), 201

    except Exception as e:
        print(f"Generate itinerary error: {str(e)}")
        return jsonify({'error': str(e)}), 500


@bp.route('/analyze-photo', methods=['POST'])
def analyze_photo():
    """Analyze a single photo using Gemini Vision"""
    try:
        if 'photo' not in request.files:
            return jsonify({'error': 'No photo provided'}), 400

        file = request.files['photo']
        file_data = file.read()

        result = analyze_single_photo(file_data)

        return jsonify(result), 200

    except Exception as e:
        print(f"Analyze photo error: {str(e)}")
        return jsonify({'error': str(e)}), 500
