"""
Sharing Routes
Handles vacation sharing with friends, public links, and collaborative trips.
"""

from flask import Blueprint, jsonify, request
import uuid
import secrets
import string
from app.services.supabase_service import get_supabase_client
from app.middleware.auth import require_auth, get_current_user_id

sharing_bp = Blueprint('sharing', __name__)
supabase = get_supabase_client()


def generate_share_code() -> str:
    """Generate a random 8-character share code"""
    chars = string.ascii_uppercase + string.digits
    return ''.join(secrets.choice(chars) for _ in range(8))


@sharing_bp.route('/vacations/<vacation_id>/share', methods=['POST'])
# @require_auth  # Uncomment when auth is enabled
def share_vacation(vacation_id):
    """
    Share a vacation with specific friends.

    Path Parameters:
        vacation_id (str): UUID of the vacation to share

    Request Body:
        {
            "user_ids": ["uuid1", "uuid2"],  // Friends to share with
            "permission": "view" | "edit"     // Permission level (default: "view")
        }

    Returns:
        {
            "message": "Vacation shared successfully",
            "shared_with": 2,
            "shares": [...]
        }
    """
    try:
        # Get current user
        user_id = get_current_user_id() or '00000000-0000-0000-0000-000000000001'

        # Parse request body
        data = request.get_json()
        if not data:
            return jsonify({'error': 'Request body required'}), 400

        user_ids = data.get('user_ids', [])
        permission = data.get('permission', 'view')

        if not user_ids:
            return jsonify({'error': 'user_ids required'}), 400

        if permission not in ['view', 'edit']:
            return jsonify({'error': 'permission must be "view" or "edit"'}), 400

        # Verify vacation belongs to current user
        vacation_response = supabase.table('vacations') \
            .select('id, user_id') \
            .eq('id', vacation_id) \
            .execute()

        if not vacation_response.data:
            return jsonify({'error': 'Vacation not found'}), 404

        vacation = vacation_response.data[0]
        if vacation['user_id'] != user_id:
            return jsonify({'error': 'Unauthorized: You do not own this vacation'}), 403

        # Create share records
        shares_created = []
        for friend_id in user_ids:
            # Check if friendship exists
            friendship_response = supabase.table('friends') \
                .select('id') \
                .eq('user_id', user_id) \
                .eq('friend_id', friend_id) \
                .eq('status', 'accepted') \
                .execute()

            if not friendship_response.data:
                continue  # Skip non-friends

            # Create or update share
            share_data = {
                'vacation_id': vacation_id,
                'shared_by': user_id,
                'shared_with': friend_id,
                'permission': permission
            }

            # Try to insert, or update if already exists
            try:
                share_response = supabase.table('shared_vacations') \
                    .upsert(share_data, on_conflict='vacation_id,shared_with') \
                    .execute()

                if share_response.data:
                    shares_created.append(share_response.data[0])
            except Exception as e:
                print(f"Error creating share for {friend_id}: {str(e)}")
                continue

        return jsonify({
            'message': 'Vacation shared successfully',
            'shared_with': len(shares_created),
            'shares': shares_created
        }), 200

    except Exception as e:
        print(f"Error in share_vacation: {str(e)}")
        return jsonify({'error': 'Failed to share vacation'}), 500


@sharing_bp.route('/vacations/<vacation_id>/share/<shared_with_user_id>', methods=['DELETE'])
# @require_auth  # Uncomment when auth is enabled
def revoke_share(vacation_id, shared_with_user_id):
    """
    Revoke sharing of a vacation with a specific user.

    Path Parameters:
        vacation_id (str): UUID of the vacation
        shared_with_user_id (str): UUID of the user to revoke access from

    Returns:
        {"message": "Sharing revoked successfully"}
    """
    try:
        # Get current user
        user_id = get_current_user_id() or '00000000-0000-0000-0000-000000000001'

        # Verify ownership
        vacation_response = supabase.table('vacations') \
            .select('user_id') \
            .eq('id', vacation_id) \
            .execute()

        if not vacation_response.data:
            return jsonify({'error': 'Vacation not found'}), 404

        if vacation_response.data[0]['user_id'] != user_id:
            return jsonify({'error': 'Unauthorized'}), 403

        # Delete share record
        delete_response = supabase.table('shared_vacations') \
            .delete() \
            .eq('vacation_id', vacation_id) \
            .eq('shared_with', shared_with_user_id) \
            .execute()

        return jsonify({'message': 'Sharing revoked successfully'}), 200

    except Exception as e:
        print(f"Error in revoke_share: {str(e)}")
        return jsonify({'error': 'Failed to revoke sharing'}), 500


@sharing_bp.route('/vacations/shared-with-me', methods=['GET'])
# @require_auth  # Uncomment when auth is enabled
def get_shared_with_me():
    """
    Get all vacations shared with the current user.

    Returns:
        {
            "vacations": [
                {
                    "vacation": {...},
                    "shared_by": {...},
                    "permission": "view",
                    "shared_at": "2024-10-30T12:00:00"
                }
            ],
            "count": 5
        }
    """
    try:
        # Get current user
        user_id = get_current_user_id() or '00000000-0000-0000-0000-000000000001'

        # Query shared vacations
        response = supabase.table('shared_vacations') \
            .select('''
                id,
                vacation_id,
                shared_by,
                permission,
                created_at,
                vacations(
                    id,
                    title,
                    start_date,
                    end_date,
                    trip_name_ai,
                    summary,
                    ai_itinerary,
                    locations(
                        id,
                        name,
                        latitude,
                        longitude,
                        photos(id, thumbnail_url)
                    )
                ),
                users!shared_vacations_shared_by_fkey(
                    id,
                    name,
                    email,
                    color
                )
            ''') \
            .eq('shared_with', user_id) \
            .execute()

        if not response.data:
            return jsonify({'vacations': [], 'count': 0}), 200

        # Format response
        shared_vacations = []
        for item in response.data:
            shared_vacations.append({
                'vacation': item.get('vacations'),
                'shared_by': item.get('users'),
                'permission': item.get('permission'),
                'shared_at': item.get('created_at')
            })

        return jsonify({
            'vacations': shared_vacations,
            'count': len(shared_vacations)
        }), 200

    except Exception as e:
        print(f"Error in get_shared_with_me: {str(e)}")
        return jsonify({'error': 'Failed to fetch shared vacations'}), 500


@sharing_bp.route('/vacations/<vacation_id>/generate-link', methods=['POST'])
# @require_auth  # Uncomment when auth is enabled
def generate_public_link(vacation_id):
    """
    Generate a public share link for a vacation.

    Path Parameters:
        vacation_id (str): UUID of the vacation

    Returns:
        {
            "share_code": "ABC12345",
            "share_url": "https://roam.app/trip/ABC12345",
            "is_public": true
        }
    """
    try:
        # Get current user
        user_id = get_current_user_id() or '00000000-0000-0000-0000-000000000001'

        # Verify ownership
        vacation_response = supabase.table('vacations') \
            .select('user_id, share_code') \
            .eq('id', vacation_id) \
            .execute()

        if not vacation_response.data:
            return jsonify({'error': 'Vacation not found'}), 404

        vacation = vacation_response.data[0]
        if vacation['user_id'] != user_id:
            return jsonify({'error': 'Unauthorized'}), 403

        # Check if share code already exists
        existing_code = vacation.get('share_code')
        if existing_code:
            return jsonify({
                'share_code': existing_code,
                'share_url': f'https://roam.app/trip/{existing_code}',
                'is_public': True,
                'message': 'Using existing share link'
            }), 200

        # Generate new share code
        share_code = generate_share_code()

        # Ensure uniqueness
        max_retries = 5
        for _ in range(max_retries):
            # Check if code already exists
            check_response = supabase.table('vacations') \
                .select('id') \
                .eq('share_code', share_code) \
                .execute()

            if not check_response.data:
                break  # Code is unique

            share_code = generate_share_code()

        # Update vacation with share code and public flag
        update_response = supabase.table('vacations') \
            .update({
                'share_code': share_code,
                'is_public': True
            }) \
            .eq('id', vacation_id) \
            .execute()

        if not update_response.data:
            return jsonify({'error': 'Failed to generate share link'}), 500

        return jsonify({
            'share_code': share_code,
            'share_url': f'https://roam.app/trip/{share_code}',
            'is_public': True
        }), 200

    except Exception as e:
        print(f"Error in generate_public_link: {str(e)}")
        return jsonify({'error': 'Failed to generate public link'}), 500


@sharing_bp.route('/vacations/<vacation_id>/revoke-link', methods=['POST'])
# @require_auth  # Uncomment when auth is enabled
def revoke_public_link(vacation_id):
    """
    Revoke public share link for a vacation.

    Path Parameters:
        vacation_id (str): UUID of the vacation

    Returns:
        {"message": "Public link revoked successfully"}
    """
    try:
        # Get current user
        user_id = get_current_user_id() or '00000000-0000-0000-0000-000000000001'

        # Verify ownership
        vacation_response = supabase.table('vacations') \
            .select('user_id') \
            .eq('id', vacation_id) \
            .execute()

        if not vacation_response.data:
            return jsonify({'error': 'Vacation not found'}), 404

        if vacation_response.data[0]['user_id'] != user_id:
            return jsonify({'error': 'Unauthorized'}), 403

        # Remove share code and set public to false
        update_response = supabase.table('vacations') \
            .update({
                'share_code': None,
                'is_public': False
            }) \
            .eq('id', vacation_id) \
            .execute()

        return jsonify({'message': 'Public link revoked successfully'}), 200

    except Exception as e:
        print(f"Error in revoke_public_link: {str(e)}")
        return jsonify({'error': 'Failed to revoke public link'}), 500


@sharing_bp.route('/vacations/public/<share_code>', methods=['GET'])
def get_public_vacation(share_code):
    """
    Get vacation by public share code (no auth required).

    Path Parameters:
        share_code (str): 8-character share code

    Returns:
        {
            "vacation": {...},
            "owner": {...},
            "is_public": true
        }
    """
    try:
        # Query vacation by share code
        response = supabase.table('vacations') \
            .select('''
                id,
                title,
                start_date,
                end_date,
                trip_name_ai,
                summary,
                ai_itinerary,
                is_public,
                locations(
                    id,
                    name,
                    latitude,
                    longitude,
                    visit_date,
                    photos(
                        id,
                        image_url,
                        thumbnail_url,
                        capture_date
                    ),
                    activities(
                        id,
                        title,
                        description,
                        time
                    )
                ),
                users(
                    id,
                    name,
                    color
                )
            ''') \
            .eq('share_code', share_code) \
            .eq('is_public', True) \
            .execute()

        if not response.data:
            return jsonify({'error': 'Vacation not found or not public'}), 404

        vacation = response.data[0]

        return jsonify({
            'vacation': vacation,
            'owner': vacation.get('users'),
            'is_public': True
        }), 200

    except Exception as e:
        print(f"Error in get_public_vacation: {str(e)}")
        return jsonify({'error': 'Failed to fetch public vacation'}), 500


@sharing_bp.route('/vacations/<vacation_id>/collaborators', methods=['GET'])
# @require_auth  # Uncomment when auth is enabled
def get_collaborators(vacation_id):
    """
    Get all collaborators for a vacation.

    Path Parameters:
        vacation_id (str): UUID of the vacation

    Returns:
        {
            "collaborators": [
                {
                    "user": {...},
                    "role": "editor",
                    "status": "accepted",
                    "invited_at": "2024-10-30T12:00:00"
                }
            ],
            "count": 3
        }
    """
    try:
        # Get current user
        user_id = get_current_user_id() or '00000000-0000-0000-0000-000000000001'

        # Verify user has access to vacation
        vacation_response = supabase.table('vacations') \
            .select('user_id') \
            .eq('id', vacation_id) \
            .execute()

        if not vacation_response.data:
            return jsonify({'error': 'Vacation not found'}), 404

        # Query collaborators
        response = supabase.table('vacation_collaborators') \
            .select('''
                id,
                user_id,
                role,
                status,
                invited_at,
                accepted_at,
                users(
                    id,
                    name,
                    email,
                    color
                )
            ''') \
            .eq('vacation_id', vacation_id) \
            .execute()

        collaborators = []
        for item in response.data:
            collaborators.append({
                'user': item.get('users'),
                'role': item.get('role'),
                'status': item.get('status'),
                'invited_at': item.get('invited_at'),
                'accepted_at': item.get('accepted_at')
            })

        return jsonify({
            'collaborators': collaborators,
            'count': len(collaborators)
        }), 200

    except Exception as e:
        print(f"Error in get_collaborators: {str(e)}")
        return jsonify({'error': 'Failed to fetch collaborators'}), 500


@sharing_bp.route('/vacations/<vacation_id>/collaborators', methods=['POST'])
# @require_auth  # Uncomment when auth is enabled
def add_collaborator(vacation_id):
    """
    Add a collaborator to a vacation.

    Path Parameters:
        vacation_id (str): UUID of the vacation

    Request Body:
        {
            "user_id": "uuid",
            "role": "editor" | "viewer"  // default: "viewer"
        }

    Returns:
        {
            "message": "Collaborator added successfully",
            "collaborator": {...}
        }
    """
    try:
        # Get current user
        current_user_id = get_current_user_id() or '00000000-0000-0000-0000-000000000001'

        # Parse request
        data = request.get_json()
        if not data:
            return jsonify({'error': 'Request body required'}), 400

        user_id = data.get('user_id')
        role = data.get('role', 'viewer')

        if not user_id:
            return jsonify({'error': 'user_id required'}), 400

        if role not in ['editor', 'viewer']:
            return jsonify({'error': 'role must be "editor" or "viewer"'}), 400

        # Verify ownership
        vacation_response = supabase.table('vacations') \
            .select('user_id') \
            .eq('id', vacation_id) \
            .execute()

        if not vacation_response.data:
            return jsonify({'error': 'Vacation not found'}), 404

        if vacation_response.data[0]['user_id'] != current_user_id:
            return jsonify({'error': 'Unauthorized'}), 403

        # Create collaborator record
        collaborator_data = {
            'vacation_id': vacation_id,
            'user_id': user_id,
            'role': role,
            'invited_by': current_user_id,
            'status': 'pending'
        }

        response = supabase.table('vacation_collaborators') \
            .insert(collaborator_data) \
            .execute()

        if not response.data:
            return jsonify({'error': 'Failed to add collaborator'}), 500

        return jsonify({
            'message': 'Collaborator added successfully',
            'collaborator': response.data[0]
        }), 200

    except Exception as e:
        print(f"Error in add_collaborator: {str(e)}")
        return jsonify({'error': 'Failed to add collaborator'}), 500


@sharing_bp.route('/vacations/<vacation_id>/collaborators/<user_id>', methods=['DELETE'])
# @require_auth  # Uncomment when auth is enabled
def remove_collaborator(vacation_id, user_id):
    """
    Remove a collaborator from a vacation.

    Path Parameters:
        vacation_id (str): UUID of the vacation
        user_id (str): UUID of the user to remove

    Returns:
        {"message": "Collaborator removed successfully"}
    """
    try:
        # Get current user
        current_user_id = get_current_user_id() or '00000000-0000-0000-0000-000000000001'

        # Verify ownership
        vacation_response = supabase.table('vacations') \
            .select('user_id') \
            .eq('id', vacation_id) \
            .execute()

        if not vacation_response.data:
            return jsonify({'error': 'Vacation not found'}), 404

        if vacation_response.data[0]['user_id'] != current_user_id:
            return jsonify({'error': 'Unauthorized'}), 403

        # Delete collaborator
        delete_response = supabase.table('vacation_collaborators') \
            .delete() \
            .eq('vacation_id', vacation_id) \
            .eq('user_id', user_id) \
            .execute()

        return jsonify({'message': 'Collaborator removed successfully'}), 200

    except Exception as e:
        print(f"Error in remove_collaborator: {str(e)}")
        return jsonify({'error': 'Failed to remove collaborator'}), 500


# Health check
@sharing_bp.route('/health', methods=['GET'])
def sharing_health():
    """Health check for sharing service"""
    return jsonify({
        'service': 'sharing',
        'status': 'healthy',
        'endpoints': {
            'share_vacation': 'POST /api/sharing/vacations/<id>/share',
            'revoke_share': 'DELETE /api/sharing/vacations/<id>/share/<user_id>',
            'shared_with_me': 'GET /api/sharing/vacations/shared-with-me',
            'generate_link': 'POST /api/sharing/vacations/<id>/generate-link',
            'public_vacation': 'GET /api/sharing/vacations/public/<share_code>',
            'collaborators': 'GET/POST /api/sharing/vacations/<id>/collaborators'
        }
    }), 200
