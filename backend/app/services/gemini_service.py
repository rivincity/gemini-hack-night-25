import google.generativeai as genai
from flask import current_app
from typing import List, Dict
import json
from datetime import datetime
from app.services.geocoding_service import get_location_name, cluster_locations_by_proximity
import requests
from PIL import Image
import io

def initialize_gemini():
    """Initialize Gemini API"""
    api_key = current_app.config['GEMINI_API_KEY']
    genai.configure(api_key=api_key)
    return genai.GenerativeModel('gemini-2.5-flash')


def download_image(url: str) -> Image.Image:
    """Download image from URL and return PIL Image"""
    try:
        response = requests.get(url, timeout=10)
        response.raise_for_status()
        return Image.open(io.BytesIO(response.content))
    except Exception as e:
        print(f"Error downloading image from {url}: {str(e)}")
        return None


def analyze_photos_for_location(photos: List[Dict], location_name: str) -> Dict:
    """
    Use Gemini Vision to analyze photos and extract activities
    
    Args:
        photos: List of photo dicts with imageURL
        location_name: Name of the location
        
    Returns:
        Dict with activities and summary
    """
    try:
        model = initialize_gemini()
        
        # Download up to 5 photos for analysis (to stay within API limits)
        images = []
        for photo in photos[:5]:
            image_url = photo.get('imageURL') or photo.get('image_url')
            if image_url:
                img = download_image(image_url)
                if img:
                    images.append(img)
        
        if not images:
            return {
                'activities': [],
                'summary': None
            }
        
        # Create a comprehensive prompt for Gemini
        prompt = f"""You are analyzing vacation photos taken at {location_name}. 

Based on these {len(images)} photos, identify specific activities and experiences the traveler had.

For each distinct activity you can identify, provide:
1. A specific activity title (e.g., "Sunset Beach Walk", "Local Market Shopping", "Mountain Hiking")
2. A detailed description of what they did (2-3 sentences)

Return your response in this exact JSON format:
{{
  "activities": [
    {{
      "title": "Activity name",
      "description": "Detailed description of what they did"
    }}
  ],
  "overall_summary": "A brief summary of their experience at this location (1-2 sentences)"
}}

Focus on being specific based on what you see in the images. Look for:
- Landmarks and attractions visited
- Activities (dining, hiking, shopping, sightseeing)
- Time of day (sunrise, sunset, night)
- Type of experience (cultural, adventure, relaxation)

Return ONLY valid JSON, no other text."""

        # Send prompt with images to Gemini
        content = [prompt] + images
        response = model.generate_content(content)
        
        # Parse JSON response
        try:
            # Extract JSON from response (sometimes Gemini adds markdown code blocks)
            response_text = response.text.strip()
            if response_text.startswith('```json'):
                response_text = response_text[7:]
            if response_text.startswith('```'):
                response_text = response_text[3:]
            if response_text.endswith('```'):
                response_text = response_text[:-3]
            response_text = response_text.strip()
            
            result = json.loads(response_text)
            print(f"✅ Gemini Vision analysis for {location_name}: {len(result.get('activities', []))} activities found")
            return result
        except json.JSONDecodeError as e:
            print(f"⚠️ Failed to parse JSON from Gemini response: {e}")
            print(f"Response was: {response.text[:200]}")
            # Fallback to basic activity
            return {
                'activities': [{
                    'title': f"Explored {location_name}",
                    'description': f"Visited and captured memories at {location_name}"
                }],
                'overall_summary': response.text[:200] if response.text else None
            }
            
    except Exception as e:
        print(f"Error analyzing photos with Gemini Vision: {str(e)}")
        return {
            'activities': [{
                'title': f"Explored {location_name}",
                'description': f"Visited and captured memories at {location_name}"
            }],
            'summary': None
        }


def generate_itinerary_from_photos(photos_data: List[Dict]) -> Dict:
    """
    Generate AI itinerary from photos with EXIF data and visual analysis

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

        # Build location summaries with visual analysis
        location_summaries = []

        for i, cluster in enumerate(clusters):
            center = cluster['center']
            location_name = get_location_name(center['latitude'], center['longitude'])

            dates = [c['capture_date'] for c in cluster['coordinates'] if c.get('capture_date')]
            photo_count = len(cluster['coordinates'])
            
            # Get photos for this cluster
            cluster_photos = [c['photo'] for c in cluster['coordinates']]
            
            # Analyze photos with Gemini Vision to extract activities
            print(f"🔍 Analyzing {len(cluster_photos)} photos at {location_name}...")
            visual_analysis = analyze_photos_for_location(cluster_photos, location_name)

            location_summaries.append({
                'name': location_name,
                'coordinates': center,
                'photo_count': photo_count,
                'dates': dates,
                'activities': visual_analysis.get('activities', []),
                'visual_summary': visual_analysis.get('overall_summary')
            })

        # Create enhanced prompt for Gemini with visual insights
        prompt = create_enhanced_itinerary_prompt(location_summaries, photos_with_location)

        # Generate itinerary
        response = model.generate_content(prompt)
        itinerary_text = response.text

        # Parse structured data with activities from visual analysis
        structured_locations = parse_locations_with_activities(location_summaries, itinerary_text)

        return {
            'itinerary': itinerary_text,
            'locations': structured_locations,
            'photo_count': len(photos_data)
        }

    except Exception as e:
        print(f"Error generating itinerary: {str(e)}")
        import traceback
        traceback.print_exc()
        return {
            'error': str(e),
            'itinerary': None,
            'locations': []
        }


def create_enhanced_itinerary_prompt(location_summaries: List[Dict], photos: List[Dict]) -> str:
    """Create enhanced prompt for Gemini with visual analysis data"""

    # Build detailed location descriptions with activities from visual analysis
    locations_text = []
    for loc in location_summaries:
        loc_text = f"\n📍 {loc['name']} ({loc['photo_count']} photos)"
        
        # Add activities found from visual analysis
        if loc.get('activities'):
            loc_text += "\n   Activities identified:"
            for activity in loc['activities']:
                loc_text += f"\n   - {activity['title']}: {activity['description']}"
        
        if loc.get('visual_summary'):
            loc_text += f"\n   Visual summary: {loc['visual_summary']}"
            
        locations_text.append(loc_text)

    locations_detail = "\n".join(locations_text)

    # Get date range
    dates = [p.get('capture_date') for p in photos if p.get('capture_date')]
    if dates:
        dates.sort()
        start_date = dates[0]
        end_date = dates[-1]
    else:
        start_date = "Unknown"
        end_date = "Unknown"

    prompt = f"""You are a travel expert creating a personalized vacation itinerary. Based on actual photo analysis and location data, write a detailed, engaging narrative of this vacation AS A DAY-BY-DAY ITINERARY.

Vacation Details:
- Start Date: {start_date}
- End Date: {end_date}
- Total Photos: {len(photos)}

Locations & Activities (from AI photo analysis):
{locations_detail}

Please write a STRUCTURED ITINERARY in this format:

Day 1 - [Date from {start_date}] - [Location Name]
Morning: [What they did in the morning]
Afternoon: [What they did in the afternoon]  
Evening: [What they did in the evening]

Day 2 - [Next Date] - [Next Location or same]
[Continue with specific activities and times]

IMPORTANT:
1. Structure it like a REAL travel itinerary with Day 1, Day 2, Day 3, etc.
2. Use the ACTUAL dates from the photo timestamps
3. Reference the SPECIFIC activities identified from photo analysis
4. Include approximate times of day (morning, afternoon, evening) based on the activities
5. Be enthusiastic and descriptive, painting a vivid picture
6. Use plain text formatting - NO markdown, just clear structure
7. If multiple locations on same day, mention the transition

Make it read like a professional travel itinerary that someone would get from a travel agent!"""

    return prompt


def create_itinerary_prompt(location_summaries: List[Dict], photos: List[Dict]) -> str:
    """Create prompt for Gemini to generate itinerary (fallback)"""
    return create_enhanced_itinerary_prompt(location_summaries, photos)


def parse_locations_with_activities(location_summaries: List[Dict], itinerary_text: str) -> List[Dict]:
    """Convert location summaries with visual analysis into structured data matching iOS model"""
    import uuid
    from datetime import datetime, timedelta

    locations = []

    for i, loc_summary in enumerate(location_summaries):
        dates = loc_summary.get('dates', [])
        visit_date = dates[0] if dates else None

        # Use activities from visual analysis if available
        activities = []
        if loc_summary.get('activities'):
            # Generate reasonable times for activities throughout the day
            for activity_index, activity_data in enumerate(loc_summary['activities']):
                # If we have photo dates, use them as base times
                if visit_date:
                    try:
                        # Parse visit date
                        base_date = datetime.fromisoformat(visit_date.replace('Z', '+00:00'))
                        # Spread activities throughout the day (9 AM, 12 PM, 3 PM, etc.)
                        hour_offset = 9 + (activity_index * 3)  # Start at 9 AM, then 12 PM, 3 PM, etc.
                        activity_time = base_date.replace(hour=hour_offset % 24, minute=0, second=0)
                        activity_time_str = activity_time.isoformat()
                    except:
                        activity_time_str = visit_date  # Fallback to visit date
                else:
                    activity_time_str = None
                
                activities.append({
                    'id': str(uuid.uuid4()),
                    'title': activity_data.get('title', 'Activity'),
                    'description': activity_data.get('description', ''),
                    'time': activity_time_str,
                    'aiGenerated': True
                })
        else:
            # Fallback to basic activity
            activities = generate_activities_for_location(loc_summary['name'], itinerary_text, visit_date)

        # Generate proper UUID for location
        location_uuid = str(uuid.uuid4())

        location = {
            'id': location_uuid,
            'name': loc_summary['name'],
            'coordinate': loc_summary['coordinates'],  # iOS expects 'coordinate' (singular)
            'visitDate': visit_date,
            'photos': [],
            'activities': activities,
            'articles': []
        }

        locations.append(location)

    return locations


def parse_locations_from_summary(location_summaries: List[Dict], itinerary_text: str) -> List[Dict]:
    """Convert location summaries into structured data matching iOS model (fallback)"""
    return parse_locations_with_activities(location_summaries, itinerary_text)


def generate_activities_for_location(location_name: str, itinerary_text: str, visit_date: str = None) -> List[Dict]:
    """Generate activities based on location and itinerary text"""
    import uuid

    # Simple activity extraction from location name
    activities = []

    # AI-generated activity based on location with proper UUID
    activities.append({
        'id': str(uuid.uuid4()),  # Changed to proper UUID
        'title': f"Explored {location_name}",
        'description': f"Visited and captured memories in {location_name}",
        'time': visit_date,  # Use visit date if available
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
