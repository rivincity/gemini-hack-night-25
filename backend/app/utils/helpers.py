from datetime import datetime
from typing import Optional
import re

def validate_email(email: str) -> bool:
    """Validate email format"""
    pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    return re.match(pattern, email) is not None


def parse_iso_date(date_str: Optional[str]) -> Optional[datetime]:
    """Parse ISO 8601 date string to datetime object"""
    if not date_str:
        return None

    try:
        # Handle both with and without timezone
        if date_str.endswith('Z'):
            return datetime.fromisoformat(date_str.replace('Z', '+00:00'))
        return datetime.fromisoformat(date_str)
    except ValueError:
        return None


def format_date_iso(dt: Optional[datetime]) -> Optional[str]:
    """Format datetime object to ISO 8601 string"""
    if not dt:
        return None

    return dt.isoformat() + 'Z' if dt.tzinfo is None else dt.isoformat()


def generate_unique_filename(original_filename: str, prefix: str = '') -> str:
    """Generate unique filename while preserving extension"""
    import uuid

    extension = original_filename.split('.')[-1] if '.' in original_filename else 'jpg'
    unique_id = str(uuid.uuid4())

    if prefix:
        return f"{prefix}_{unique_id}.{extension}"

    return f"{unique_id}.{extension}"


def calculate_distance_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """
    Calculate distance between two coordinates using Haversine formula
    Returns distance in kilometers
    """
    from math import radians, cos, sin, asin, sqrt

    # Convert to radians
    lat1, lon1, lat2, lon2 = map(radians, [lat1, lon1, lat2, lon2])

    # Haversine formula
    dlat = lat2 - lat1
    dlon = lon2 - lon1
    a = sin(dlat/2)**2 + cos(lat1) * cos(lat2) * sin(dlon/2)**2
    c = 2 * asin(sqrt(a))

    # Earth radius in kilometers
    r = 6371

    return c * r


def sanitize_string(text: str, max_length: int = 255) -> str:
    """Sanitize and truncate string"""
    if not text:
        return ''

    # Remove control characters
    text = ''.join(char for char in text if ord(char) >= 32 or char == '\n')

    # Truncate
    if len(text) > max_length:
        text = text[:max_length]

    return text.strip()


def build_error_response(message: str, status_code: int = 400) -> tuple:
    """Build standardized error response"""
    return {'error': message}, status_code


def build_success_response(data: dict, message: str = None, status_code: int = 200) -> tuple:
    """Build standardized success response"""
    response = data.copy() if data else {}

    if message:
        response['message'] = message

    return response, status_code
