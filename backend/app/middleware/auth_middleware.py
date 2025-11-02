from functools import wraps
from flask import request, jsonify
from app.services.supabase_service import verify_token

def require_auth(f):
    """Middleware decorator to require authentication"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        # Get token from Authorization header
        auth_header = request.headers.get('Authorization')

        if not auth_header:
            return jsonify({'error': 'No authorization header'}), 401

        # Extract token (format: "Bearer <token>")
        parts = auth_header.split()
        if len(parts) != 2 or parts[0].lower() != 'bearer':
            return jsonify({'error': 'Invalid authorization header format'}), 401

        token = parts[1]

        # Verify token
        user = verify_token(token)

        if not user:
            return jsonify({'error': 'Invalid or expired token'}), 401

        # Add user to request context
        request.user = user

        return f(*args, **kwargs)

    return decorated_function

def get_current_user():
    """Get current authenticated user from request context"""
    return getattr(request, 'user', None)
