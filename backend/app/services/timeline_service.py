"""
Timeline Service
Handles date-based vacation queries, statistics, and timeline data generation.
"""

from datetime import datetime, timedelta
from typing import Dict, List, Optional, Tuple
from collections import defaultdict
import calendar
from app.services.supabase_service import get_supabase_client


class TimelineService:
    """Service for managing travel timeline and statistics"""

    def __init__(self):
        self.supabase = get_supabase_client()

    def get_timeline_data(self, user_id: str, include_friends: bool = True) -> Dict:
        """
        Get structured timeline data grouped by year and month.

        Args:
            user_id: UUID of the user
            include_friends: Whether to include visible friends' vacations

        Returns:
            Dictionary with timeline structure:
            {
                "years": {
                    "2024": {
                        "count": 5,
                        "vacations": [...],
                        "countries": ["Italy", "France"],
                        "cities": ["Rome", "Paris"],
                        "total_photos": 250,
                        "months": {
                            "6": {"count": 2, "vacations": [...]},
                            ...
                        }
                    }
                },
                "summary": {
                    "total_trips": 15,
                    "years_count": 5,
                    "earliest_trip": "2020-01-15",
                    "latest_trip": "2024-10-30"
                }
            }
        """
        try:
            # Fetch user's vacations with related data
            query = self.supabase.table('vacations') \
                .select('''
                    id,
                    title,
                    start_date,
                    end_date,
                    trip_name_ai,
                    summary,
                    created_at,
                    locations(
                        id,
                        name,
                        latitude,
                        longitude,
                        visit_date,
                        photos(id, image_url, thumbnail_url, capture_date)
                    ),
                    user_id,
                    users(name, color)
                ''') \
                .eq('user_id', user_id)

            response = query.execute()
            vacations = response.data if response.data else []

            # Include friends' vacations if requested
            if include_friends:
                friends_vacations = self._get_visible_friends_vacations(user_id)
                vacations.extend(friends_vacations)

            # Build timeline structure
            timeline = self._build_timeline_structure(vacations)

            return timeline

        except Exception as e:
            print(f"Error getting timeline data: {str(e)}")
            return {"years": {}, "summary": {}}

    def _get_visible_friends_vacations(self, user_id: str) -> List[Dict]:
        """Get vacations from visible friends"""
        try:
            # Get friends with is_visible=True
            friends_response = self.supabase.table('friends') \
                .select('friend_id') \
                .eq('user_id', user_id) \
                .eq('status', 'accepted') \
                .eq('is_visible', True) \
                .execute()

            if not friends_response.data:
                return []

            friend_ids = [f['friend_id'] for f in friends_response.data]

            # Get their vacations
            vacations_response = self.supabase.table('vacations') \
                .select('''
                    id,
                    title,
                    start_date,
                    end_date,
                    trip_name_ai,
                    summary,
                    created_at,
                    locations(
                        id,
                        name,
                        latitude,
                        longitude,
                        visit_date,
                        photos(id, image_url, thumbnail_url, capture_date)
                    ),
                    user_id,
                    users(name, color)
                ''') \
                .in_('user_id', friend_ids) \
                .execute()

            return vacations_response.data if vacations_response.data else []

        except Exception as e:
            print(f"Error getting friends vacations: {str(e)}")
            return []

    def _build_timeline_structure(self, vacations: List[Dict]) -> Dict:
        """Build timeline structure from vacation data"""
        years_data = defaultdict(lambda: {
            'count': 0,
            'vacations': [],
            'countries': set(),
            'cities': set(),
            'total_photos': 0,
            'months': defaultdict(lambda: {'count': 0, 'vacations': []})
        })

        earliest_date = None
        latest_date = None

        for vacation in vacations:
            start_date = vacation.get('start_date')
            if not start_date:
                continue

            # Parse date
            if isinstance(start_date, str):
                start_date = datetime.fromisoformat(start_date.replace('Z', '+00:00'))

            year = start_date.year
            month = start_date.month

            # Add to year data
            year_key = str(year)
            years_data[year_key]['count'] += 1
            years_data[year_key]['vacations'].append(vacation)

            # Add to month data
            month_key = str(month)
            years_data[year_key]['months'][month_key]['count'] += 1
            years_data[year_key]['months'][month_key]['vacations'].append(vacation)

            # Extract locations data
            locations = vacation.get('locations', [])
            for loc in locations:
                loc_name = loc.get('name', '')
                # Try to extract country from location name (format: "City, Country")
                if ', ' in loc_name:
                    parts = loc_name.split(', ')
                    if len(parts) >= 2:
                        years_data[year_key]['cities'].add(parts[0])
                        years_data[year_key]['countries'].add(parts[-1])

                # Count photos
                photos = loc.get('photos', [])
                years_data[year_key]['total_photos'] += len(photos)

            # Track earliest and latest dates
            if earliest_date is None or start_date < earliest_date:
                earliest_date = start_date

            end_date = vacation.get('end_date')
            if end_date:
                if isinstance(end_date, str):
                    end_date = datetime.fromisoformat(end_date.replace('Z', '+00:00'))
                if latest_date is None or end_date > latest_date:
                    latest_date = end_date
            elif latest_date is None or start_date > latest_date:
                latest_date = start_date

        # Convert sets to lists for JSON serialization
        final_years = {}
        for year_key, data in years_data.items():
            final_years[year_key] = {
                'count': data['count'],
                'vacations': sorted(data['vacations'], key=lambda v: v.get('start_date', ''), reverse=True),
                'countries': sorted(list(data['countries'])),
                'cities': sorted(list(data['cities'])),
                'total_photos': data['total_photos'],
                'months': {
                    month_key: {
                        'count': month_data['count'],
                        'vacations': sorted(month_data['vacations'], key=lambda v: v.get('start_date', ''), reverse=True),
                        'month_name': calendar.month_name[int(month_key)]
                    }
                    for month_key, month_data in data['months'].items()
                }
            }

        # Build summary
        summary = {
            'total_trips': len(vacations),
            'years_count': len(years_data),
            'earliest_trip': earliest_date.isoformat() if earliest_date else None,
            'latest_trip': latest_date.isoformat() if latest_date else None
        }

        return {
            'years': final_years,
            'summary': summary
        }

    def filter_vacations_by_date_range(
        self,
        user_id: str,
        start_date: datetime,
        end_date: datetime,
        include_friends: bool = True
    ) -> List[Dict]:
        """
        Filter vacations by date range.

        Args:
            user_id: UUID of the user
            start_date: Start of date range
            end_date: End of date range
            include_friends: Whether to include visible friends' vacations

        Returns:
            List of vacations within the date range
        """
        try:
            # Query vacations within date range
            query = self.supabase.table('vacations') \
                .select('''
                    id,
                    title,
                    start_date,
                    end_date,
                    trip_name_ai,
                    summary,
                    created_at,
                    locations(
                        id,
                        name,
                        latitude,
                        longitude,
                        visit_date,
                        photos(id, image_url, thumbnail_url, capture_date),
                        activities(id, title, description, time, ai_generated)
                    ),
                    user_id,
                    users(name, email, color)
                ''') \
                .eq('user_id', user_id) \
                .gte('start_date', start_date.isoformat()) \
                .lte('start_date', end_date.isoformat())

            response = query.execute()
            vacations = response.data if response.data else []

            # Include friends' vacations if requested
            if include_friends:
                friends_vacations = self._filter_friends_vacations_by_date(
                    user_id, start_date, end_date
                )
                vacations.extend(friends_vacations)

            return vacations

        except Exception as e:
            print(f"Error filtering vacations by date range: {str(e)}")
            return []

    def _filter_friends_vacations_by_date(
        self,
        user_id: str,
        start_date: datetime,
        end_date: datetime
    ) -> List[Dict]:
        """Filter friends' vacations by date range"""
        try:
            # Get visible friends
            friends_response = self.supabase.table('friends') \
                .select('friend_id') \
                .eq('user_id', user_id) \
                .eq('status', 'accepted') \
                .eq('is_visible', True) \
                .execute()

            if not friends_response.data:
                return []

            friend_ids = [f['friend_id'] for f in friends_response.data]

            # Query their vacations
            vacations_response = self.supabase.table('vacations') \
                .select('''
                    id,
                    title,
                    start_date,
                    end_date,
                    trip_name_ai,
                    summary,
                    created_at,
                    locations(
                        id,
                        name,
                        latitude,
                        longitude,
                        visit_date,
                        photos(id, image_url, thumbnail_url, capture_date),
                        activities(id, title, description, time, ai_generated)
                    ),
                    user_id,
                    users(name, email, color)
                ''') \
                .in_('user_id', friend_ids) \
                .gte('start_date', start_date.isoformat()) \
                .lte('start_date', end_date.isoformat()) \
                .execute()

            return vacations_response.data if vacations_response.data else []

        except Exception as e:
            print(f"Error filtering friends vacations: {str(e)}")
            return []

    def get_years_with_trips(self, user_id: str) -> List[int]:
        """
        Get list of years where user has trips.

        Args:
            user_id: UUID of the user

        Returns:
            Sorted list of years (e.g., [2020, 2021, 2023, 2024])
        """
        try:
            # Query distinct years
            response = self.supabase.table('vacations') \
                .select('start_date') \
                .eq('user_id', user_id) \
                .not_.is_('start_date', 'null') \
                .execute()

            if not response.data:
                return []

            # Extract unique years
            years = set()
            for vacation in response.data:
                start_date = vacation.get('start_date')
                if start_date:
                    if isinstance(start_date, str):
                        start_date = datetime.fromisoformat(start_date.replace('Z', '+00:00'))
                    years.add(start_date.year)

            return sorted(list(years))

        except Exception as e:
            print(f"Error getting years with trips: {str(e)}")
            return []

    def get_travel_statistics(self, user_id: str) -> Dict:
        """
        Get comprehensive travel statistics for user.

        Args:
            user_id: UUID of the user

        Returns:
            Dictionary with statistics:
            {
                "total_trips": 15,
                "countries_visited": 12,
                "cities_visited": 45,
                "years_traveling": [2020, 2021, 2022, 2023, 2024],
                "total_photos": 1250,
                "total_locations": 60,
                "favorite_destinations": ["Paris", "Tokyo", "NYC"],
                "busiest_year": {"year": 2023, "trips": 8},
                "average_trip_length_days": 5.2,
                "total_days_traveled": 78
            }
        """
        try:
            # Query all user's vacations with locations and photos
            response = self.supabase.table('vacations') \
                .select('''
                    id,
                    start_date,
                    end_date,
                    locations(
                        id,
                        name,
                        photos(id)
                    )
                ''') \
                .eq('user_id', user_id) \
                .execute()

            if not response.data:
                return self._empty_statistics()

            vacations = response.data

            # Calculate statistics
            stats = {
                'total_trips': len(vacations),
                'total_locations': 0,
                'total_photos': 0,
                'countries_visited': set(),
                'cities_visited': set(),
                'years_traveling': set(),
                'location_visit_counts': defaultdict(int),
                'year_trip_counts': defaultdict(int),
                'total_days': 0,
                'trips_with_dates': 0
            }

            for vacation in vacations:
                # Count locations and photos
                locations = vacation.get('locations', [])
                stats['total_locations'] += len(locations)

                for loc in locations:
                    loc_name = loc.get('name', '')

                    # Extract country and city
                    if ', ' in loc_name:
                        parts = loc_name.split(', ')
                        if len(parts) >= 2:
                            city = parts[0]
                            country = parts[-1]
                            stats['cities_visited'].add(city)
                            stats['countries_visited'].add(country)
                            stats['location_visit_counts'][city] += 1

                    # Count photos
                    photos = loc.get('photos', [])
                    stats['total_photos'] += len(photos)

                # Track years and calculate trip duration
                start_date = vacation.get('start_date')
                end_date = vacation.get('end_date')

                if start_date:
                    if isinstance(start_date, str):
                        start_date = datetime.fromisoformat(start_date.replace('Z', '+00:00'))

                    year = start_date.year
                    stats['years_traveling'].add(year)
                    stats['year_trip_counts'][year] += 1

                    # Calculate duration
                    if end_date:
                        if isinstance(end_date, str):
                            end_date = datetime.fromisoformat(end_date.replace('Z', '+00:00'))

                        duration = (end_date - start_date).days
                        stats['total_days'] += duration
                        stats['trips_with_dates'] += 1

            # Find favorite destinations (most visited cities)
            favorite_destinations = sorted(
                stats['location_visit_counts'].items(),
                key=lambda x: x[1],
                reverse=True
            )[:5]  # Top 5

            # Find busiest year
            busiest_year_data = max(
                stats['year_trip_counts'].items(),
                key=lambda x: x[1],
                default=(None, 0)
            )

            # Calculate average trip length
            avg_trip_length = (
                stats['total_days'] / stats['trips_with_dates']
                if stats['trips_with_dates'] > 0 else 0
            )

            # Build final statistics
            return {
                'total_trips': stats['total_trips'],
                'countries_visited': len(stats['countries_visited']),
                'cities_visited': len(stats['cities_visited']),
                'years_traveling': sorted(list(stats['years_traveling'])),
                'total_photos': stats['total_photos'],
                'total_locations': stats['total_locations'],
                'favorite_destinations': [dest[0] for dest in favorite_destinations],
                'busiest_year': {
                    'year': busiest_year_data[0],
                    'trips': busiest_year_data[1]
                } if busiest_year_data[0] else None,
                'average_trip_length_days': round(avg_trip_length, 1),
                'total_days_traveled': stats['total_days']
            }

        except Exception as e:
            print(f"Error getting travel statistics: {str(e)}")
            return self._empty_statistics()

    def _empty_statistics(self) -> Dict:
        """Return empty statistics structure"""
        return {
            'total_trips': 0,
            'countries_visited': 0,
            'cities_visited': 0,
            'years_traveling': [],
            'total_photos': 0,
            'total_locations': 0,
            'favorite_destinations': [],
            'busiest_year': None,
            'average_trip_length_days': 0,
            'total_days_traveled': 0
        }

    def get_vacations_by_year(self, user_id: str, year: int) -> List[Dict]:
        """
        Get all vacations for a specific year.

        Args:
            user_id: UUID of the user
            year: Year to filter (e.g., 2024)

        Returns:
            List of vacations for that year
        """
        start_date = datetime(year, 1, 1)
        end_date = datetime(year, 12, 31, 23, 59, 59)

        return self.filter_vacations_by_date_range(
            user_id,
            start_date,
            end_date,
            include_friends=False
        )


# Singleton instance
_timeline_service = None

def get_timeline_service() -> TimelineService:
    """Get or create timeline service singleton"""
    global _timeline_service
    if _timeline_service is None:
        _timeline_service = TimelineService()
    return _timeline_service
