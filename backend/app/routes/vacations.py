from flask import Blueprint, request, jsonify
from app.middleware.auth_middleware import require_auth, get_current_user
from app.services.supabase_service import get_supabase_client
import uuid

bp = Blueprint('vacations', __name__, url_prefix='/api/vacations')


@bp.route('', methods=['GET'])
def get_vacations():
    """Get all vacations for user and their visible friends"""
    try:
        # Use a default user ID for demo (no auth required)
        user_id = "00000000-0000-0000-0000-000000000001"

        supabase = get_supabase_client()

        # Get user's friends where is_visible is true
        friends_result = supabase.table('friends').select('friend_id').eq('user_id', user_id).eq('is_visible', True).eq('status', 'accepted').execute()

        friend_ids = [f['friend_id'] for f in friends_result.data] if friends_result.data else []

        # Get all user IDs to query (user + visible friends)
        all_user_ids = [user_id] + friend_ids

        # Get vacations for all these users
        vacations_result = supabase.table('vacations').select('*').in_('user_id', all_user_ids).execute()

        vacations = []

        for vacation in vacations_result.data:
            vacation_data = build_vacation_response(vacation, supabase)
            vacations.append(vacation_data)

        return jsonify({'vacations': vacations}), 200

    except Exception as e:
        print(f"Get vacations error: {str(e)}")
        return jsonify({'error': str(e)}), 500


def build_vacation_response(vacation, supabase):
    """Build complete vacation response with locations, activities, photos"""

    # Get owner info
    owner_result = supabase.table('users').select('*').eq('id', vacation['user_id']).execute()
    owner = owner_result.data[0] if owner_result.data else None

    # Get locations
    locations_result = supabase.table('locations').select('*').eq('vacation_id', vacation['id']).execute()

    locations = []

    for location in locations_result.data:
        # Get activities
        activities_result = supabase.table('activities').select('*').eq('location_id', location['id']).execute()

        activities = [
            {
                'id': act['id'],
                'title': act['title'],
                'description': act['description'],
                'time': act.get('time'),
                'aiGenerated': act.get('ai_generated', False)
            }
            for act in activities_result.data
        ] if activities_result.data else []

        # Get photos
        photos_result = supabase.table('photos').select('*').eq('location_id', location['id']).execute()

        photos = [
            {
                'id': photo['id'],
                'imageURL': photo['image_url'],
                'thumbnailURL': photo.get('thumbnail_url'),
                'captureDate': photo.get('capture_date'),
                'location': {
                    'latitude': photo.get('latitude'),
                    'longitude': photo.get('longitude')
                } if photo.get('latitude') else None,
                'caption': photo.get('caption')
            }
            for photo in photos_result.data
        ] if photos_result.data else []

        locations.append({
            'id': location['id'],
            'name': location['name'],
            'coordinate': {
                'latitude': location['latitude'],
                'longitude': location['longitude']
            },
            'visitDate': location.get('visit_date'),
            'photos': photos,
            'activities': activities,
            'articles': []
        })

    return {
        'id': vacation['id'],
        'title': vacation['title'],
        'startDate': vacation.get('start_date'),
        'endDate': vacation.get('end_date'),
        'owner': {
            'id': owner['id'],
            'name': owner['name'],
            'color': owner['color']
        } if owner else None,
        'locations': locations,
        'aiGeneratedItinerary': vacation.get('ai_itinerary')
    }


@bp.route('/<vacation_id>', methods=['GET'])
def get_vacation(vacation_id):
    """Get specific vacation details"""
    try:
        supabase = get_supabase_client()

        vacation_result = supabase.table('vacations').select('*').eq('id', vacation_id).execute()

        if not vacation_result.data:
            return jsonify({'error': 'Vacation not found'}), 404

        vacation = vacation_result.data[0]
        vacation_data = build_vacation_response(vacation, supabase)

        return jsonify(vacation_data), 200

    except Exception as e:
        print(f"Get vacation error: {str(e)}")
        return jsonify({'error': str(e)}), 500


@bp.route('', methods=['POST'])
def create_vacation():
    """Create a new vacation manually"""
    try:
        # Use a default user ID for demo (no auth required)
        user_id = "00000000-0000-0000-0000-000000000001"

        data = request.get_json()

        vacation_id = str(uuid.uuid4())

        vacation_data = {
            'id': vacation_id,
            'user_id': user_id,
            'title': data.get('title', 'My Vacation'),
            'start_date': data.get('startDate'),
            'end_date': data.get('endDate'),
            'ai_itinerary': data.get('aiGeneratedItinerary')
        }

        supabase = get_supabase_client()
        supabase.table('vacations').insert(vacation_data).execute()

        return jsonify({
            'id': vacation_id,
            'message': 'Vacation created successfully'
        }), 201

    except Exception as e:
        print(f"Create vacation error: {str(e)}")
        return jsonify({'error': str(e)}), 500


@bp.route('/<vacation_id>', methods=['PUT'])
def update_vacation(vacation_id):
    """Update vacation details"""
    try:
        # Use a default user ID for demo (no auth required)
        user_id = "00000000-0000-0000-0000-000000000001"

        data = request.get_json()

        supabase = get_supabase_client()

        # Verify ownership
        vacation_result = supabase.table('vacations').select('*').eq('id', vacation_id).eq('user_id', user_id).execute()

        if not vacation_result.data:
            return jsonify({'error': 'Vacation not found or unauthorized'}), 404

        # Update vacation
        update_data = {}
        if 'title' in data:
            update_data['title'] = data['title']
        if 'startDate' in data:
            update_data['start_date'] = data['startDate']
        if 'endDate' in data:
            update_data['end_date'] = data['endDate']

        if update_data:
            supabase.table('vacations').update(update_data).eq('id', vacation_id).execute()

        return jsonify({'message': 'Vacation updated successfully'}), 200

    except Exception as e:
        print(f"Update vacation error: {str(e)}")
        return jsonify({'error': str(e)}), 500


@bp.route('/<vacation_id>', methods=['DELETE'])
def delete_vacation(vacation_id):
    """Delete a vacation"""
    try:
        # Use a default user ID for demo (no auth required)
        user_id = "00000000-0000-0000-0000-000000000001"

        supabase = get_supabase_client()

        # Verify ownership
        vacation_result = supabase.table('vacations').select('*').eq('id', vacation_id).eq('user_id', user_id).execute()

        if not vacation_result.data:
            return jsonify({'error': 'Vacation not found or unauthorized'}), 404

        # Delete vacation (cascade will handle related data if configured)
        supabase.table('vacations').delete().eq('id', vacation_id).execute()

        return jsonify({'message': 'Vacation deleted successfully'}), 200

    except Exception as e:
        print(f"Delete vacation error: {str(e)}")
        return jsonify({'error': str(e)}), 500
