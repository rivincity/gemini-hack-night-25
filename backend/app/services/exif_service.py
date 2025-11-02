from PIL import Image
from PIL.ExifTags import TAGS, GPSTAGS
from datetime import datetime
from typing import Dict, Optional, Tuple
import io

def extract_exif_data(image_data: bytes) -> Dict:
    """Extract EXIF data from image bytes"""
    try:
        image = Image.open(io.BytesIO(image_data))
        exif_data = {}

        # Get EXIF data
        exif = image._getexif()

        if not exif:
            return {
                'has_exif': False,
                'coordinates': None,
                'capture_date': None
            }

        # Parse EXIF tags
        for tag_id, value in exif.items():
            tag = TAGS.get(tag_id, tag_id)
            exif_data[tag] = value

        # Extract GPS coordinates
        coordinates = extract_gps_coordinates(exif_data)

        # Extract capture date
        capture_date = extract_capture_date(exif_data)

        return {
            'has_exif': True,
            'coordinates': coordinates,
            'capture_date': capture_date,
            'camera_make': exif_data.get('Make'),
            'camera_model': exif_data.get('Model')
        }

    except Exception as e:
        print(f"Error extracting EXIF: {str(e)}")
        return {
            'has_exif': False,
            'coordinates': None,
            'capture_date': None,
            'error': str(e)
        }


def extract_gps_coordinates(exif_data: Dict) -> Optional[Dict[str, float]]:
    """Extract GPS coordinates from EXIF data"""
    try:
        gps_info = exif_data.get('GPSInfo')

        if not gps_info:
            return None

        gps_data = {}
        for key in gps_info.keys():
            decode = GPSTAGS.get(key, key)
            gps_data[decode] = gps_info[key]

        # Get latitude
        lat = gps_data.get('GPSLatitude')
        lat_ref = gps_data.get('GPSLatitudeRef')

        # Get longitude
        lon = gps_data.get('GPSLongitude')
        lon_ref = gps_data.get('GPSLongitudeRef')

        if lat and lon and lat_ref and lon_ref:
            latitude = convert_to_degrees(lat)
            if lat_ref != 'N':
                latitude = -latitude

            longitude = convert_to_degrees(lon)
            if lon_ref != 'E':
                longitude = -longitude

            return {
                'latitude': latitude,
                'longitude': longitude
            }

        return None

    except Exception as e:
        print(f"Error extracting GPS: {str(e)}")
        return None


def convert_to_degrees(value) -> float:
    """Convert GPS coordinates to degrees"""
    d, m, s = value
    return float(d) + (float(m) / 60.0) + (float(s) / 3600.0)


def extract_capture_date(exif_data: Dict) -> Optional[str]:
    """Extract capture date from EXIF data"""
    try:
        # Try different date fields
        date_fields = ['DateTimeOriginal', 'DateTime', 'DateTimeDigitized']

        for field in date_fields:
            date_str = exif_data.get(field)
            if date_str:
                # Parse format: "2024:10:01 14:30:45"
                dt = datetime.strptime(date_str, '%Y:%m:%d %H:%M:%S')
                # Return ISO 8601 format
                return dt.isoformat() + 'Z'

        return None

    except Exception as e:
        print(f"Error extracting date: {str(e)}")
        return None


def create_thumbnail(image_data: bytes, size: Tuple[int, int] = (300, 300)) -> bytes:
    """Create thumbnail from image data"""
    try:
        image = Image.open(io.BytesIO(image_data))

        # Convert to RGB if necessary
        if image.mode in ('RGBA', 'LA', 'P'):
            image = image.convert('RGB')

        # Create thumbnail
        image.thumbnail(size, Image.Resampling.LANCZOS)

        # Save to bytes
        output = io.BytesIO()
        image.save(output, format='JPEG', quality=85)
        output.seek(0)

        return output.read()

    except Exception as e:
        print(f"Error creating thumbnail: {str(e)}")
        raise e
