from flask import Blueprint, render_template, jsonify
import datetime

bp = Blueprint('main', __name__)

@bp.route('/')
def index():
    return render_template('index.html')

@bp.route('/api/status')
def status():
    return jsonify({
        'status': 'OK1',
        'timestamp': datetime.datetime.utcnow().isoformat(),
        'version': '1.0.0'
    })

@bp.route('/api/hello/<name>')
def hello(name):
    return jsonify({
        'message': f'Hello, {name}!',
        'timestamp': datetime.datetime.utcnow().isoformat()
    })
