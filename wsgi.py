from app import create_app
from config import config
import os

# Get environment from environment variable or default to development
env = os.environ.get('FLASK_ENV', 'development')
app = create_app(config[env])

if __name__ == '__main__':
    app.run()