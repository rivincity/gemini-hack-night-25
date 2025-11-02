from flask import Flask
from flask_cors import CORS
import os
from dotenv import load_dotenv

load_dotenv()

def create_app():
    app = Flask(__name__)

    # Configure CORS for iOS app
    CORS(app, resources={
        r"/api/*": {
            "origins": "*",
            "methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
            "allow_headers": ["Content-Type", "Authorization"]
        }
    })

    # Configuration
    app.config['MAX_CONTENT_LENGTH'] = 100 * 1024 * 1024  # 100MB max for batch uploads
    app.config['SUPABASE_URL'] = os.getenv('SUPABASE_URL')
    app.config['SUPABASE_KEY'] = os.getenv('SUPABASE_KEY')
    app.config['GEMINI_API_KEY'] = os.getenv('GEMINI_API_KEY')

    # Register blueprints
    from app.routes import auth, vacations, photos, ai, friends

    app.register_blueprint(auth.bp)
    app.register_blueprint(vacations.bp)
    app.register_blueprint(photos.bp)
    app.register_blueprint(ai.bp)
    app.register_blueprint(friends.bp)

    # Health check endpoint
    @app.route('/api/health')
    def health():
        return {'status': 'ok', 'message': 'Roam API is running'}

    return app
