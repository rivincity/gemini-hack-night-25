import google.generativeai as genai
from flask import current_app
from typing import List, Dict
import json
from datetime import datetime
from app.services.geocoding_service import get_location_name, cluster_locations_by_proximity

def initialize_gemini():
    """Initialize Gemini API"""
    api_key = current_app.config['GEMINI_API_KEY']
    genai.configure(api_key=api_key)
    return genai.GenerativeModel('gemini-1.5-flash')


def generate_itinerary_from_photos(photos_data: List[Dict]) -> Dict:
    """
    Generate AI itinerary from photos with EXIF data

    Args:
        photos_data: List of dicts with keys: image_url, coordinates, capture_date

    Returns:
        Dict with itinerary text and structured location/activity data
    """
    try:
        model = initialize_gemini()

        # Filter photos with coordinates
        photos_with_location = [p for p in photos_data if p.get('coordinates')]

        if not photos_with_location:
            return {
                'error': 'No photos with location data found',
                'itinerary': None,
                'locations': []
            }

        # Sort photos by capture date
        photos_with_location.sort(key=lambda x: x.get('capture_date', ''))

        # Cluster photos by location proximity
        coordinates_list = [
            {
                **p['coordinates'],
                'photo': p,
                'capture_date': p.get('capture_date')
            }
            for p in photos_with_location
        ]

        clusters = cluster_locations_by_proximity(coordinates_list, threshold_km=10.0)

        # Build location summaries
        location_summaries = []

        for i, cluster in enumerate(clusters):
            center = cluster['center']
            location_name = get_location_name(center['latitude'], center['longitude'])

            dates = [c['capture_date'] for c in cluster['coordinates'] if c.get('capture_date')]
            photo_count = len(cluster['coordinates'])

            location_summaries.append({
                'name': location_name,
                'coordinates': center,
                'photo_count': photo_count,
                'dates': dates
            })

        # Create prompt for Gemini
        prompt = create_itinerary_prompt(location_summaries, photos_with_location)

        # Generate itinerary
        response = model.generate_content(prompt)
        itinerary_text = response.text

        # Parse structured data
        structured_locations = parse_locations_from_summary(location_summaries, itinerary_text)

        return {
            'itinerary': itinerary_text,
            'locations': structured_locations,
            'photo_count': len(photos_data)
        }

    except Exception as e:
        print(f"Error generating itinerary: {str(e)}")
        return {
            'error': str(e),
            'itinerary': None,
            'locations': []
        }


def create_itinerary_prompt(location_summaries: List[Dict], photos: List[Dict]) -> str:
    """Create prompt for Gemini to generate itinerary"""

    locations_text = "\n".join([
        f"- {loc['name']}: {loc['photo_count']} photos taken"
        for loc in location_summaries
    ])

    # Get date range
    dates = [p.get('capture_date') for p in photos if p.get('capture_date')]
    if dates:
        dates.sort()
        start_date = dates[0]
        end_date = dates[-1]
    else:
        start_date = "Unknown"
        end_date = "Unknown"

    prompt = f"""You are a travel expert analyzing vacation photos. Based on the following information, create a detailed, engaging itinerary summary of this vacation.

Vacation Details:
- Start Date: {start_date}
- End Date: {end_date}
- Total Photos: {len(photos)}

Locations Visited:
{locations_text}

Please write:
1. A natural, flowing narrative describing this vacation (2-3 paragraphs)
2. Highlight the main locations and what the traveler likely experienced
3. Mention the journey chronologically if possible
4. Be enthusiastic and descriptive, as if you're helping them remember their adventure
5. Do not use markdown formatting - just plain text paragraphs

Keep the tone warm, personal, and engaging."""

    return prompt


def parse_locations_from_summary(location_summaries: List[Dict], itinerary_text: str) -> List[Dict]:
    """Convert location summaries into structured data matching iOS model"""

    locations = []

    for i, loc_summary in enumerate(location_summaries):
        dates = loc_summary.get('dates', [])
        visit_date = dates[0] if dates else None

        # Create basic activities from location
        activities = generate_activities_for_location(loc_summary['name'], itinerary_text)

        location = {
            'id': f"loc_{i}",
            'name': loc_summary['name'],
            'coordinate': loc_summary['coordinates'],
            'visitDate': visit_date,
            'photos': [],
            'activities': activities,
            'articles': []
        }

        locations.append(location)

    return locations


def generate_activities_for_location(location_name: str, itinerary_text: str) -> List[Dict]:
    """Generate activities based on location and itinerary text"""

    # Simple activity extraction from location name
    activities = []

    # AI-generated activity based on location
    activities.append({
        'id': f"activity_ai_0",
        'title': f"Explored {location_name}",
        'description': f"Visited and captured memories in {location_name}",
        'time': None,
        'aiGenerated': True
    })

    return activities


def analyze_single_photo(image_data: bytes) -> Dict:
    """Analyze a single photo using Gemini vision"""
    try:
        model = initialize_gemini()

        # Convert bytes to PIL Image for Gemini
        from PIL import Image
        import io

        image = Image.open(io.BytesIO(image_data))

        prompt = """Describe what you see in this vacation photo. Include:
1. Main subjects (people, landmarks, scenery)
2. Activity or scene type
3. Mood or atmosphere
4. Any notable details

Keep it concise (2-3 sentences)."""

        response = model.generate_content([prompt, image])

        return {
            'description': response.text,
            'analyzed': True
        }

    except Exception as e:
        print(f"Error analyzing photo: {str(e)}")
        return {
            'description': None,
            'analyzed': False,
            'error': str(e)
        }
