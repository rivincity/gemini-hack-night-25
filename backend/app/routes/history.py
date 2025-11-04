"""
History and Timeline Routes
Handles timeline views, date filtering, and travel statistics.
"""

from flask import Blueprint, jsonify, request
from datetime import datetime
from app.services.timeline_service import get_timeline_service
from app.middleware.auth import require_auth, get_current_user_id

history_bp = Blueprint('history', __name__)
timeline_service = get_timeline_service()


@history_bp.route('/timeline', methods=['GET'])
# @require_auth  # Uncomment when auth is enabled
def get_timeline():
    """
    Get user's travel timeline grouped by year and month.

    Query Parameters:
        include_friends (bool): Include visible friends' vacations (default: true)

    Returns:
        {
            "years": {
                "2024": {
                    "count": 5,
                    "vacations": [...],
                    "countries": ["Italy", "France"],
                    "cities": ["Rome", "Paris"],
                    "total_photos": 250,
                    "months": {
                        "6": {"count": 2, "month_name": "June", "vacations": [...]}
                    }
                }
            },
            "summary": {
                "total_trips": 15,
                "years_count": 5,
                "earliest_trip": "2020-01-15T00:00:00",
                "latest_trip": "2024-10-30T00:00:00"
            }
        }
    """
    try:
        # Get current user (demo mode: hardcoded)
        user_id = get_current_user_id() or '00000000-0000-0000-0000-000000000001'

        # Check if friends should be included
        include_friends = request.args.get('include_friends', 'true').lower() == 'true'

        # Get timeline data
        timeline_data = timeline_service.get_timeline_data(user_id, include_friends)

        return jsonify(timeline_data), 200

    except Exception as e:
        print(f"Error in get_timeline: {str(e)}")
        return jsonify({'error': 'Failed to fetch timeline data'}), 500


@history_bp.route('/filter', methods=['GET'])
# @require_auth  # Uncomment when auth is enabled
def filter_by_date_range():
    """
    Filter vacations by date range.

    Query Parameters:
        from (str): Start date in YYYY-MM-DD format (required)
        to (str): End date in YYYY-MM-DD format (required)
        include_friends (bool): Include visible friends' vacations (default: true)

    Returns:
        List of vacations within the date range
    """
    try:
        # Get current user
        user_id = get_current_user_id() or '00000000-0000-0000-0000-000000000001'

        # Parse date parameters
        from_date_str = request.args.get('from')
        to_date_str = request.args.get('to')

        if not from_date_str or not to_date_str:
            return jsonify({'error': 'Missing required parameters: from, to'}), 400

        try:
            from_date = datetime.fromisoformat(from_date_str)
            to_date = datetime.fromisoformat(to_date_str)
        except ValueError as e:
            return jsonify({'error': f'Invalid date format. Use YYYY-MM-DD: {str(e)}'}), 400

        # Validate date range
        if from_date > to_date:
            return jsonify({'error': 'Start date must be before end date'}), 400

        # Check if friends should be included
        include_friends = request.args.get('include_friends', 'true').lower() == 'true'

        # Filter vacations
        vacations = timeline_service.filter_vacations_by_date_range(
            user_id,
            from_date,
            to_date,
            include_friends
        )

        return jsonify({
            'vacations': vacations,
            'count': len(vacations),
            'from_date': from_date.isoformat(),
            'to_date': to_date.isoformat()
        }), 200

    except Exception as e:
        print(f"Error in filter_by_date_range: {str(e)}")
        return jsonify({'error': 'Failed to filter vacations'}), 500


@history_bp.route('/years', methods=['GET'])
# @require_auth  # Uncomment when auth is enabled
def get_years():
    """
    Get list of years where user has trips.

    Returns:
        {
            "years": [2020, 2021, 2023, 2024],
            "count": 4
        }
    """
    try:
        # Get current user
        user_id = get_current_user_id() or '00000000-0000-0000-0000-000000000001'

        # Get years
        years = timeline_service.get_years_with_trips(user_id)

        return jsonify({
            'years': years,
            'count': len(years)
        }), 200

    except Exception as e:
        print(f"Error in get_years: {str(e)}")
        return jsonify({'error': 'Failed to fetch years'}), 500


@history_bp.route('/stats', methods=['GET'])
# @require_auth  # Uncomment when auth is enabled
def get_statistics():
    """
    Get comprehensive travel statistics for user.

    Returns:
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
        # Get current user
        user_id = get_current_user_id() or '00000000-0000-0000-0000-000000000001'

        # Get statistics
        stats = timeline_service.get_travel_statistics(user_id)

        return jsonify(stats), 200

    except Exception as e:
        print(f"Error in get_statistics: {str(e)}")
        return jsonify({'error': 'Failed to fetch statistics'}), 500


@history_bp.route('/year/<int:year>', methods=['GET'])
# @require_auth  # Uncomment when auth is enabled
def get_vacations_by_year(year):
    """
    Get all vacations for a specific year.

    Path Parameters:
        year (int): Year to filter (e.g., 2024)

    Returns:
        {
            "year": 2024,
            "vacations": [...],
            "count": 5
        }
    """
    try:
        # Validate year
        current_year = datetime.now().year
        if year < 1900 or year > current_year + 10:
            return jsonify({'error': f'Invalid year. Must be between 1900 and {current_year + 10}'}), 400

        # Get current user
        user_id = get_current_user_id() or '00000000-0000-0000-0000-000000000001'

        # Get vacations for year
        vacations = timeline_service.get_vacations_by_year(user_id, year)

        return jsonify({
            'year': year,
            'vacations': vacations,
            'count': len(vacations)
        }), 200

    except Exception as e:
        print(f"Error in get_vacations_by_year: {str(e)}")
        return jsonify({'error': 'Failed to fetch vacations for year'}), 500


@history_bp.route('/month/<int:year>/<int:month>', methods=['GET'])
# @require_auth  # Uncomment when auth is enabled
def get_vacations_by_month(year, month):
    """
    Get all vacations for a specific month.

    Path Parameters:
        year (int): Year (e.g., 2024)
        month (int): Month (1-12)

    Returns:
        {
            "year": 2024,
            "month": 6,
            "month_name": "June",
            "vacations": [...],
            "count": 2
        }
    """
    try:
        # Validate year and month
        if month < 1 or month > 12:
            return jsonify({'error': 'Invalid month. Must be between 1 and 12'}), 400

        current_year = datetime.now().year
        if year < 1900 or year > current_year + 10:
            return jsonify({'error': f'Invalid year. Must be between 1900 and {current_year + 10}'}), 400

        # Get current user
        user_id = get_current_user_id() or '00000000-0000-0000-0000-000000000001'

        # Create date range for the month
        from_date = datetime(year, month, 1)

        # Get last day of month
        if month == 12:
            to_date = datetime(year + 1, 1, 1)
        else:
            to_date = datetime(year, month + 1, 1)

        # Filter vacations
        vacations = timeline_service.filter_vacations_by_date_range(
            user_id,
            from_date,
            to_date,
            include_friends=False
        )

        return jsonify({
            'year': year,
            'month': month,
            'month_name': from_date.strftime('%B'),
            'vacations': vacations,
            'count': len(vacations)
        }), 200

    except Exception as e:
        print(f"Error in get_vacations_by_month: {str(e)}")
        return jsonify({'error': 'Failed to fetch vacations for month'}), 500


# Health check for history service
@history_bp.route('/health', methods=['GET'])
def history_health():
    """Health check for history service"""
    return jsonify({
        'service': 'history',
        'status': 'healthy',
        'endpoints': {
            'timeline': '/api/history/timeline',
            'filter': '/api/history/filter',
            'years': '/api/history/years',
            'stats': '/api/history/stats',
            'by_year': '/api/history/year/<year>',
            'by_month': '/api/history/month/<year>/<month>'
        }
    }), 200
