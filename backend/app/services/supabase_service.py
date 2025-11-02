from supabase import create_client, Client
from flask import current_app
from functools import lru_cache

@lru_cache()
def get_supabase_client() -> Client:
    """Get or create Supabase client singleton"""
    url = current_app.config['SUPABASE_URL']
    key = current_app.config['SUPABASE_KEY']

    # Create client with options to avoid proxy parameter issue
    options = {
        'schema': 'public',
        'auto_refresh_token': True,
        'persist_session': True
    }

    return create_client(url, key)

def verify_token(token: str):
    """Verify JWT token and return user"""
    try:
        supabase = get_supabase_client()
        # Get user from token
        user = supabase.auth.get_user(token)
        return user
    except Exception as e:
        return None

def get_user_by_id(user_id: str):
    """Get user profile from database"""
    try:
        supabase = get_supabase_client()
        result = supabase.table('users').select('*').eq('id', user_id).execute()
        if result.data and len(result.data) > 0:
            return result.data[0]
        return None
    except Exception as e:
        print(f"Error fetching user: {str(e)}")
        return None

def upload_file_to_storage(bucket: str, file_path: str, file_data: bytes, content_type: str):
    """Upload file to Supabase Storage"""
    try:
        supabase = get_supabase_client()
        result = supabase.storage.from_(bucket).upload(
            file_path,
            file_data,
            {'content-type': content_type}
        )
        return result
    except Exception as e:
        print(f"Error uploading file: {str(e)}")
        raise e

def get_public_url(bucket: str, file_path: str):
    """Get public URL for a file in storage"""
    try:
        supabase = get_supabase_client()
        result = supabase.storage.from_(bucket).get_public_url(file_path)
        return result
    except Exception as e:
        print(f"Error getting public URL: {str(e)}")
        return None
