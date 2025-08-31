import pytest
from app import create_app
from config import config

@pytest.fixture
def client():
    app = create_app(config['testing'])
    with app.test_client() as client:
        yield client

def test_index_route(client):
    response = client.get('/')
    assert response.status_code == 200
    assert b'Flask CI/CD Demo' in response.data

def test_status_route(client):
    response = client.get('/api/status')
    assert response.status_code == 200
    assert response.is_json
    json_data = response.get_json()
    assert 'status' in json_data
    assert json_data['status'] == 'OK'
    assert 'version' in json_data

def test_hello_route(client):
    response = client.get('/api/hello/TestUser')
    assert response.status_code == 200
    assert response.is_json
    json_data = response.get_json()
    assert 'message' in json_data
    assert 'TestUser' in json_data['message']