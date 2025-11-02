from flask import Blueprint, request, jsonify
from app.services.supabase_service import get_supabase_client
from app.middleware.auth_middleware import require_auth, get_current_user
import random

bp = Blueprint('auth', __name__, url_prefix='/api/auth')

# Hex colors for user assignment (matching iOS app)
USER_COLORS = ['#FF6B6B', '#4ECDC4', '#95E1D3', '#FFA07A', '#98D8C8', '#6C5CE7', '#A29BFE']

@bp.route('/signup', methods=['POST'])
def signup():
    """Register a new user with Supabase Auth"""
    try:
        data = request.get_json()
        email = data.get('email')
        password = data.get('password')
        name = data.get('name')

        if not email or not password or not name:
            return jsonify({'error': 'Email, password, and name are required'}), 400

        supabase = get_supabase_client()

        # Sign up user with auto-confirm for development
        auth_response = supabase.auth.sign_up({
            'email': email,
            'password': password,
            'options': {
                'data': {
                    'name': name
                }
            }
        })

        if not auth_response.user:
            return jsonify({'error': 'Failed to create user'}), 400

        user_id = auth_response.user.id

        # Check if user profile already exists
        try:
            existing_profile = supabase.table('users').select('*').eq('id', user_id).execute()
            
            if existing_profile.data and len(existing_profile.data) > 0:
                # User profile already exists, use it
                profile = existing_profile.data[0]
                user_color = profile['color']
                name = profile['name']  # Use existing name
            else:
                # Assign random color
                user_color = random.choice(USER_COLORS)

                # Create user profile in database
                user_profile = {
                    'id': user_id,
                    'email': email,
                    'name': name,
                    'color': user_color,
                    'profile_image': None
                }

                supabase.table('users').insert(user_profile).execute()
        except Exception as db_error:
            # If database operation fails, still try to return session if available
            print(f"Database error (non-critical): {str(db_error)}")
            user_color = random.choice(USER_COLORS)

        # Check if session exists (it may be None if email confirmation is required)
        if auth_response.session:
            # Session exists, return tokens
            return jsonify({
                'user': {
                    'id': user_id,
                    'email': email,
                    'name': name,
                    'color': user_color
                },
                'session': {
                    'access_token': auth_response.session.access_token,
                    'refresh_token': auth_response.session.refresh_token
                }
            }), 201
        else:
            # No session (email confirmation required), sign in directly
            try:
                login_response = supabase.auth.sign_in_with_password({
                    'email': email,
                    'password': password
                })
                
                if login_response.session:
                    return jsonify({
                        'user': {
                            'id': user_id,
                            'email': email,
                            'name': name,
                            'color': user_color
                        },
                        'session': {
                            'access_token': login_response.session.access_token,
                            'refresh_token': login_response.session.refresh_token
                        }
                    }), 201
                else:
                    return jsonify({'error': 'Email confirmation required. Please check your email.'}), 400
            except Exception as login_error:
                print(f"Login after signup failed: {str(login_error)}")
                return jsonify({'error': 'User created but login failed. Please try logging in.'}), 201

    except Exception as e:
        error_msg = str(e)
        print(f"Signup error: {error_msg}")
        
        # Check if this is a duplicate user error from auth
        if 'already registered' in error_msg.lower() or 'already exists' in error_msg.lower():
            return jsonify({'error': 'User already exists. Please try logging in.'}), 400
        
        return jsonify({'error': 'Signup failed. Please try again.'}), 500


@bp.route('/login', methods=['POST'])
def login():
    """Login user with Supabase Auth"""
    try:
        data = request.get_json()
        email = data.get('email')
        password = data.get('password')

        if not email or not password:
            return jsonify({'error': 'Email and password are required'}), 400

        supabase = get_supabase_client()

        # Sign in user
        auth_response = supabase.auth.sign_in_with_password({
            'email': email,
            'password': password
        })

        if not auth_response.user:
            return jsonify({'error': 'Invalid credentials'}), 401

        if not auth_response.session:
            return jsonify({'error': 'Email confirmation required or session expired'}), 401

        user_id = auth_response.user.id

        # Get user profile
        user_profile = supabase.table('users').select('*').eq('id', user_id).execute()

        if not user_profile.data:
            return jsonify({'error': 'User profile not found'}), 404

        profile = user_profile.data[0]

        return jsonify({
            'user': {
                'id': profile['id'],
                'email': profile['email'],
                'name': profile['name'],
                'color': profile['color'],
                'profileImage': profile.get('profile_image')
            },
            'session': {
                'access_token': auth_response.session.access_token,
                'refresh_token': auth_response.session.refresh_token
            }
        }), 200

    except Exception as e:
        print(f"Login error: {str(e)}")
        return jsonify({'error': 'Invalid credentials'}), 401


@bp.route('/me', methods=['GET'])
@require_auth
def get_me():
    """Get current user profile"""
    try:
        user = get_current_user()
        user_id = user.user.id

        supabase = get_supabase_client()
        user_profile = supabase.table('users').select('*').eq('id', user_id).execute()

        if not user_profile.data:
            return jsonify({'error': 'User not found'}), 404

        profile = user_profile.data[0]

        return jsonify({
            'id': profile['id'],
            'email': profile['email'],
            'name': profile['name'],
            'color': profile['color'],
            'profileImage': profile.get('profile_image')
        }), 200

    except Exception as e:
        print(f"Get me error: {str(e)}")
        return jsonify({'error': str(e)}), 500


@bp.route('/logout', methods=['POST'])
@require_auth
def logout():
    """Logout user"""
    try:
        supabase = get_supabase_client()
        supabase.auth.sign_out()
        return jsonify({'message': 'Logged out successfully'}), 200
    except Exception as e:
        print(f"Logout error: {str(e)}")
        return jsonify({'error': str(e)}), 500
