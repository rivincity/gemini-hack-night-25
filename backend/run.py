from app import create_app
import os
import sys

# Validate configuration before starting
def validate_config():
    """Validate required environment variables"""
    required_vars = {
        'SUPABASE_URL': 'Supabase project URL',
        'SUPABASE_KEY': 'Supabase anon key',
        'GEMINI_API_KEY': 'Google Gemini API key'
    }

    missing = []
    for var, description in required_vars.items():
        value = os.getenv(var)
        if not value or value.strip() == '':
            missing.append(f"  - {var}: {description}")

    if missing:
        print("❌ ERROR: Missing required environment variables:")
        print("\n".join(missing))
        print("\n💡 Please create a .env file with these variables.")
        print("   See .env.example for reference.")
        sys.exit(1)

    print("✅ Configuration validated successfully")
    print(f"   SUPABASE_URL: {os.getenv('SUPABASE_URL')[:30]}...")
    print(f"   GEMINI_API_KEY: {os.getenv('GEMINI_API_KEY')[:20]}...")

if __name__ == '__main__':
    # Validate config first
    validate_config()

    # Create app
    app = create_app()

    # Get configuration
    host = "0.0.0.0"  # Flask listens on all interfaces
    port = 5000
    debug = os.getenv('FLASK_DEBUG', 'True') == 'True'

    print(f"\n🚀 Starting Roam API server on {host}:{port}")
    print(f"   Debug mode: {debug}")
    print(f"   Local: http://localhost:{port}/api/health")
    print(f"   ngrok: https://850a286ace35.ngrok-free.app/api/health\n")

    app.run(host=host, port=port, debug=debug)
