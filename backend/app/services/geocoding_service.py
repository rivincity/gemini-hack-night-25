from geopy.geocoders import Nominatim
from geopy.exc import GeocoderTimedOut, GeocoderServiceError
from functools import lru_cache
import time

# Initialize geocoder
geolocator = Nominatim(user_agent="roam-app")

@lru_cache(maxsize=1000)
def get_location_name(latitude: float, longitude: float) -> str:
    """Convert coordinates to location name using reverse geocoding"""
    try:
        # Add small delay to respect rate limits
        time.sleep(0.5)

        location = geolocator.reverse(f"{latitude}, {longitude}", language='en', timeout=10)

        if location and location.raw:
            address = location.raw.get('address', {})

            # Try to get city, state, country
            city = (
                address.get('city') or
                address.get('town') or
                address.get('village') or
                address.get('municipality')
            )

            state = address.get('state')
            country = address.get('country')

            # Build location string
            parts = []
            if city:
                parts.append(city)
            if state and state != city:
                parts.append(state)
            if country:
                parts.append(country)

            if parts:
                return ', '.join(parts)

        # Fallback to coordinates
        return f"{latitude:.4f}, {longitude:.4f}"

    except (GeocoderTimedOut, GeocoderServiceError) as e:
        print(f"Geocoding error: {str(e)}")
        return f"{latitude:.4f}, {longitude:.4f}"


def cluster_locations_by_proximity(coordinates_list, threshold_km=5.0):
    """Cluster coordinates that are close to each other"""
    from math import radians, cos, sin, asin, sqrt

    def haversine(lat1, lon1, lat2, lon2):
        """Calculate distance between two points on Earth"""
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

    clusters = []

    for coord in coordinates_list:
        lat = coord['latitude']
        lon = coord['longitude']

        # Find if this coordinate belongs to existing cluster
        found_cluster = False

        for cluster in clusters:
            cluster_lat = cluster['center']['latitude']
            cluster_lon = cluster['center']['longitude']

            distance = haversine(lat, lon, cluster_lat, cluster_lon)

            if distance <= threshold_km:
                cluster['coordinates'].append(coord)
                found_cluster = True
                break

        if not found_cluster:
            # Create new cluster
            clusters.append({
                'center': {'latitude': lat, 'longitude': lon},
                'coordinates': [coord]
            })

    return clusters
