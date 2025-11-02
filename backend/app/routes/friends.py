from flask import Blueprint, request, jsonify
from app.middleware.auth_middleware import require_auth, get_current_user
from app.services.supabase_service import get_supabase_client
import uuid

bp = Blueprint('friends', __name__, url_prefix='/api/friends')


@bp.route('', methods=['GET'])
@require_auth
def get_friends():
    """Get user's friend list"""
    try:
        user = get_current_user()
        user_id = user.user.id

        supabase = get_supabase_client()

        # Get all friends (both directions)
        friends_result = supabase.table('friends').select('*').or_(f'user_id.eq.{user_id},friend_id.eq.{user_id}').eq('status', 'accepted').execute()

        friends = []

        for friendship in friends_result.data:
            # Determine which ID is the friend
            friend_id = friendship['friend_id'] if friendship['user_id'] == user_id else friendship['user_id']
            is_visible = friendship.get('is_visible', True) if friendship['user_id'] == user_id else True

            # Get friend's profile
            friend_result = supabase.table('users').select('*').eq('id', friend_id).execute()

            if friend_result.data:
                friend_profile = friend_result.data[0]

                # Get friend's vacation count
                vacation_count_result = supabase.table('vacations').select('id', count='exact').eq('user_id', friend_id).execute()
                vacation_count = vacation_count_result.count if vacation_count_result.count else 0

                # Get total location count for friend
                vacations_result = supabase.table('vacations').select('id').eq('user_id', friend_id).execute()
                vacation_ids = [v['id'] for v in vacations_result.data] if vacations_result.data else []

                location_count = 0
                if vacation_ids:
                    location_count_result = supabase.table('locations').select('id', count='exact').in_('vacation_id', vacation_ids).execute()
                    location_count = location_count_result.count if location_count_result.count else 0

                friends.append({
                    'id': friend_profile['id'],
                    'name': friend_profile['name'],
                    'color': friend_profile['color'],
                    'profileImage': friend_profile.get('profile_image'),
                    'vacationCount': vacation_count,
                    'locationCount': location_count,
                    'isVisible': is_visible
                })

        return jsonify({'friends': friends}), 200

    except Exception as e:
        print(f"Get friends error: {str(e)}")
        return jsonify({'error': str(e)}), 500


@bp.route('/add', methods=['POST'])
@require_auth
def add_friend():
    """Send friend request by email"""
    try:
        user = get_current_user()
        user_id = user.user.id

        data = request.get_json()
        friend_email = data.get('email')

        if not friend_email:
            return jsonify({'error': 'Email is required'}), 400

        supabase = get_supabase_client()

        # Find user by email
        friend_result = supabase.table('users').select('*').eq('email', friend_email).execute()

        if not friend_result.data:
            return jsonify({'error': 'User not found'}), 404

        friend_id = friend_result.data[0]['id']

        if friend_id == user_id:
            return jsonify({'error': 'Cannot add yourself as friend'}), 400

        # Check if friendship already exists
        existing_result = supabase.table('friends').select('*').or_(
            f'and(user_id.eq.{user_id},friend_id.eq.{friend_id}),and(user_id.eq.{friend_id},friend_id.eq.{user_id})'
        ).execute()

        if existing_result.data:
            return jsonify({'error': 'Friend request already exists or you are already friends'}), 400

        # Create friend request
        friendship_data = {
            'id': str(uuid.uuid4()),
            'user_id': user_id,
            'friend_id': friend_id,
            'status': 'pending',
            'is_visible': True
        }

        supabase.table('friends').insert(friendship_data).execute()

        return jsonify({'message': 'Friend request sent'}), 201

    except Exception as e:
        print(f"Add friend error: {str(e)}")
        return jsonify({'error': str(e)}), 500


@bp.route('/accept/<friendship_id>', methods=['POST'])
@require_auth
def accept_friend(friendship_id):
    """Accept friend request"""
    try:
        user = get_current_user()
        user_id = user.user.id

        supabase = get_supabase_client()

        # Get friend request
        friendship_result = supabase.table('friends').select('*').eq('id', friendship_id).eq('friend_id', user_id).execute()

        if not friendship_result.data:
            return jsonify({'error': 'Friend request not found'}), 404

        # Update status
        supabase.table('friends').update({'status': 'accepted'}).eq('id', friendship_id).execute()

        return jsonify({'message': 'Friend request accepted'}), 200

    except Exception as e:
        print(f"Accept friend error: {str(e)}")
        return jsonify({'error': str(e)}), 500


@bp.route('/<friend_id>', methods=['DELETE'])
@require_auth
def remove_friend(friend_id):
    """Remove friend"""
    try:
        user = get_current_user()
        user_id = user.user.id

        supabase = get_supabase_client()

        # Delete friendship (both directions)
        supabase.table('friends').delete().or_(
            f'and(user_id.eq.{user_id},friend_id.eq.{friend_id}),and(user_id.eq.{friend_id},friend_id.eq.{user_id})'
        ).execute()

        return jsonify({'message': 'Friend removed'}), 200

    except Exception as e:
        print(f"Remove friend error: {str(e)}")
        return jsonify({'error': str(e)}), 500


@bp.route('/<friend_id>/toggle-visibility', methods=['POST'])
@require_auth
def toggle_friend_visibility(friend_id):
    """Toggle visibility of friend's vacations on map"""
    try:
        user = get_current_user()
        user_id = user.user.id

        data = request.get_json()
        is_visible = data.get('isVisible', True)

        supabase = get_supabase_client()

        # Update visibility
        supabase.table('friends').update({'is_visible': is_visible}).eq('user_id', user_id).eq('friend_id', friend_id).execute()

        return jsonify({'message': 'Visibility updated'}), 200

    except Exception as e:
        print(f"Toggle visibility error: {str(e)}")
        return jsonify({'error': str(e)}), 500


@bp.route('/<friend_id>/vacations', methods=['GET'])
@require_auth
def get_friend_vacations(friend_id):
    """Get a friend's vacations"""
    try:
        user = get_current_user()
        user_id = user.user.id

        supabase = get_supabase_client()

        # Verify friendship
        friendship_result = supabase.table('friends').select('*').or_(
            f'and(user_id.eq.{user_id},friend_id.eq.{friend_id}),and(user_id.eq.{friend_id},friend_id.eq.{user_id})'
        ).eq('status', 'accepted').execute()

        if not friendship_result.data:
            return jsonify({'error': 'Not friends with this user'}), 403

        # Get friend's vacations
        vacations_result = supabase.table('vacations').select('*').eq('user_id', friend_id).execute()

        # Note: For simplicity, returning basic vacation data
        # Can expand to include full details like in vacations.py

        vacations = [
            {
                'id': v['id'],
                'title': v['title'],
                'startDate': v.get('start_date'),
                'endDate': v.get('end_date')
            }
            for v in vacations_result.data
        ]

        return jsonify({'vacations': vacations}), 200

    except Exception as e:
        print(f"Get friend vacations error: {str(e)}")
        return jsonify({'error': str(e)}), 500
