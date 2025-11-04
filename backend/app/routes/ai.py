from flask import Blueprint, request, jsonify
from app.middleware.auth_middleware import require_auth, get_current_user
from app.services.gemini_service import (
    generate_itinerary_from_photos,
    analyze_single_photo,
    generate_trip_name,
    generate_memory_highlights,
    generate_trip_summary,
    suggest_vacation_tags
)
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
        # Use a fixed demo user UUID
        demo_user_id = "00000000-0000-0000-0000-000000000001"
        
        # Ensure demo user exists in database
        supabase = get_supabase_client()
        try:
            existing_user = supabase.table('users').select('id').eq('id', demo_user_id).execute()
            if not existing_user.data or len(existing_user.data) == 0:
                # Create demo user
                demo_user = {
                    'id': demo_user_id,
                    'email': 'demo@roam.app',
                    'name': 'Demo User',
                    'color': '#FF6B6B'
                }
                supabase.table('users').insert(demo_user).execute()
                print("✅ Created demo user in database")
        except Exception as user_error:
            print(f"⚠️ Demo user check: {user_error}")
        
        user_id = demo_user_id

        data = request.get_json()
        photos = data.get('photos', [])
        title = data.get('title', 'My Vacation')

        if not photos or len(photos) == 0:
            return jsonify({'error': 'No photos provided'}), 400

        print(f"Generating itinerary from {len(photos)} photos for user {user_id}")

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

        # Fetch user info for owner field
        user_response = supabase.table('users').select('id, name, color').eq('id', user_id).execute()
        user_info = user_response.data[0] if user_response.data else None

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
        vacation_response = {
            'id': vacation_id,
            'title': title,
            'startDate': start_date,
            'endDate': end_date,
            'aiGeneratedItinerary': result['itinerary'],
            'locations': result['locations']
        }

        # Add owner info if available
        if user_info:
            vacation_response['owner'] = {
                'id': user_info['id'],
                'name': user_info['name'],
                'color': user_info['color']
            }

        return jsonify({
            'vacation': vacation_response,
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


@bp.route('/vacations/<vacation_id>/generate-highlights', methods=['POST'])
def generate_highlights_endpoint(vacation_id):
    """
    Generate AI memory highlights for a vacation.

    Path Parameters:
        vacation_id (str): UUID of the vacation

    Returns:
        {
            "highlights": [
                {
                    "title": "Golden Hour Beach Sunset",
                    "description": "A breathtaking sunset captured...",
                    "photo_id": "uuid",
                    "photo_url": "https://...",
                    "highlight_type": "scenic_view",
                    "confidence": 0.9
                }
            ],
            "count": 3
        }
    """
    try:
        supabase = get_supabase_client()

        # Fetch vacation with all photos
        vacation_response = supabase.table('vacations') \
            .select('''
                id,
                title,
                start_date,
                end_date,
                locations(
                    id,
                    name,
                    photos(id, image_url, thumbnail_url, capture_date)
                )
            ''') \
            .eq('id', vacation_id) \
            .execute()

        if not vacation_response.data:
            return jsonify({'error': 'Vacation not found'}), 404

        vacation = vacation_response.data[0]

        # Collect all photos
        all_photos = []
        for loc in vacation.get('locations', []):
            all_photos.extend(loc.get('photos', []))

        if not all_photos:
            return jsonify({'error': 'No photos found for this vacation'}), 400

        print(f"Generating highlights for vacation {vacation_id} with {len(all_photos)} photos...")

        # Generate highlights
        highlights = generate_memory_highlights(vacation, all_photos)

        if not highlights:
            return jsonify({'error': 'Failed to generate highlights'}), 500

        # Store highlights in database
        for highlight in highlights:
            highlight_data = {
                'id': str(uuid.uuid4()),
                'vacation_id': vacation_id,
                'title': highlight['title'],
                'description': highlight['description'],
                'photo_id': highlight['photo_id'],
                'highlight_type': highlight['highlight_type'],
                'ai_confidence': highlight.get('confidence', 0.8)
            }

            supabase.table('memory_highlights').insert(highlight_data).execute()

        return jsonify({
            'highlights': highlights,
            'count': len(highlights),
            'message': 'Memory highlights generated successfully'
        }), 200

    except Exception as e:
        print(f"Generate highlights error: {str(e)}")
        return jsonify({'error': str(e)}), 500


@bp.route('/vacations/<vacation_id>/highlights', methods=['GET'])
def get_highlights(vacation_id):
    """
    Get existing memory highlights for a vacation.

    Path Parameters:
        vacation_id (str): UUID of the vacation

    Returns:
        List of memory highlights
    """
    try:
        supabase = get_supabase_client()

        # Fetch highlights
        response = supabase.table('memory_highlights') \
            .select('''
                id,
                title,
                description,
                highlight_type,
                ai_confidence,
                created_at,
                photos(id, image_url, thumbnail_url)
            ''') \
            .eq('vacation_id', vacation_id) \
            .execute()

        highlights = response.data if response.data else []

        return jsonify({
            'highlights': highlights,
            'count': len(highlights)
        }), 200

    except Exception as e:
        print(f"Get highlights error: {str(e)}")
        return jsonify({'error': str(e)}), 500


@bp.route('/generate-trip-name', methods=['POST'])
def generate_trip_name_endpoint():
    """
    Generate AI trip name.

    Request Body:
        {
            "locations": ["Paris", "Rome"],
            "start_date": "2024-10-01T00:00:00Z",
            "end_date": "2024-10-10T00:00:00Z",
            "tags": ["cultural", "food"]  // optional
        }

    Returns:
        {
            "trip_name": "2024 European Cultural Journey"
        }
    """
    try:
        data = request.get_json()

        locations = data.get('locations', [])
        start_date = data.get('start_date')
        end_date = data.get('end_date')
        tags = data.get('tags', [])

        if not locations or not start_date:
            return jsonify({'error': 'locations and start_date are required'}), 400

        # Generate trip name
        trip_name = generate_trip_name(locations, start_date, end_date or start_date, tags)

        return jsonify({
            'trip_name': trip_name
        }), 200

    except Exception as e:
        print(f"Generate trip name error: {str(e)}")
        return jsonify({'error': str(e)}), 500


@bp.route('/vacations/<vacation_id>/generate-summary', methods=['POST'])
def generate_summary_endpoint(vacation_id):
    """
    Generate AI trip summary for a vacation.

    Path Parameters:
        vacation_id (str): UUID of the vacation

    Returns:
        {
            "summary": "A wonderful journey through..."
        }
    """
    try:
        supabase = get_supabase_client()

        # Fetch vacation data
        vacation_response = supabase.table('vacations') \
            .select('''
                id,
                title,
                start_date,
                end_date,
                locations(
                    id,
                    name,
                    activities(id, title, description)
                )
            ''') \
            .eq('id', vacation_id) \
            .execute()

        if not vacation_response.data:
            return jsonify({'error': 'Vacation not found'}), 404

        vacation = vacation_response.data[0]

        # Generate summary
        summary = generate_trip_summary(vacation)

        # Update vacation with summary
        supabase.table('vacations') \
            .update({'summary': summary}) \
            .eq('id', vacation_id) \
            .execute()

        return jsonify({
            'summary': summary
        }), 200

    except Exception as e:
        print(f"Generate summary error: {str(e)}")
        return jsonify({'error': str(e)}), 500


@bp.route('/suggest-tags', methods=['POST'])
def suggest_tags_endpoint():
    """
    Suggest vacation tags based on photos and locations.

    Request Body:
        {
            "photos": [{"image_url": "https://..."}],
            "locations": ["Paris", "Rome"]
        }

    Returns:
        {
            "tags": ["cultural", "city", "food"]
        }
    """
    try:
        data = request.get_json()

        photos = data.get('photos', [])
        locations = data.get('locations', [])

        if not photos and not locations:
            return jsonify({'error': 'photos or locations required'}), 400

        # Suggest tags
        tags = suggest_vacation_tags(photos, locations)

        return jsonify({
            'tags': tags
        }), 200

    except Exception as e:
        print(f"Suggest tags error: {str(e)}")
        return jsonify({'error': str(e)}), 500


@bp.route('/vacations/<vacation_id>/add-tags', methods=['POST'])
def add_tags_to_vacation(vacation_id):
    """
    Add tags to a vacation.

    Path Parameters:
        vacation_id (str): UUID of the vacation

    Request Body:
        {
            "tags": ["beach", "adventure", "cultural"]
        }

    Returns:
        {
            "message": "Tags added successfully",
            "tags": [...]
        }
    """
    try:
        data = request.get_json()
        tags = data.get('tags', [])

        if not tags:
            return jsonify({'error': 'tags required'}), 400

        supabase = get_supabase_client()

        # Verify vacation exists
        vacation_response = supabase.table('vacations') \
            .select('id') \
            .eq('id', vacation_id) \
            .execute()

        if not vacation_response.data:
            return jsonify({'error': 'Vacation not found'}), 404

        # Add tags
        inserted_tags = []
        for tag in tags:
            tag_data = {
                'id': str(uuid.uuid4()),
                'vacation_id': vacation_id,
                'tag': tag.lower()
            }

            try:
                response = supabase.table('vacation_tags') \
                    .insert(tag_data) \
                    .execute()

                if response.data:
                    inserted_tags.append(response.data[0])
            except Exception as e:
                # Tag might already exist (duplicate), skip
                print(f"Tag {tag} might already exist: {e}")
                continue

        return jsonify({
            'message': 'Tags added successfully',
            'tags': inserted_tags,
            'count': len(inserted_tags)
        }), 200

    except Exception as e:
        print(f"Add tags error: {str(e)}")
        return jsonify({'error': str(e)}), 500
