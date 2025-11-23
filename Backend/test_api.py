"""
Quick test script to verify API endpoints are working
Run this after starting the server: python test_api.py
"""
import requests
import json

BASE_URL = "http://localhost:8000/api"

def test_api():
    print("Testing VyRaVerse API...")
    print("=" * 50)
    
    # Test 1: Check if server is running
    try:
        response = requests.get(f"{BASE_URL}/profiles/")
        print(f"✓ Server is running (Status: {response.status_code})")
    except requests.exceptions.ConnectionError:
        print("✗ Server is not running. Please start it with: python manage.py runserver")
        return
    
    # Test 2: Test signup endpoint
    print("\nTesting Signup endpoint...")
    signup_data = {
        "username": "testuser",
        "email": "test@example.com",
        "password": "testpass123",
        "password2": "testpass123"
    }
    try:
        response = requests.post(f"{BASE_URL}/auth/signup/", json=signup_data)
        if response.status_code == 201:
            print("✓ Signup endpoint working")
            data = response.json()
            print(f"  Token: {data.get('token', 'N/A')[:20]}...")
        else:
            print(f"⚠ Signup returned status {response.status_code}")
            print(f"  Response: {response.text[:100]}")
    except Exception as e:
        print(f"✗ Signup test failed: {e}")
    
    # Test 3: Test profiles endpoint
    print("\nTesting Profiles endpoint...")
    try:
        response = requests.get(f"{BASE_URL}/profiles/")
        if response.status_code in [200, 401]:  # 401 is OK if not authenticated
            print("✓ Profiles endpoint accessible")
        else:
            print(f"⚠ Profiles returned status {response.status_code}")
    except Exception as e:
        print(f"✗ Profiles test failed: {e}")
    
    # Test 4: Test videos endpoint
    print("\nTesting Videos endpoint...")
    try:
        response = requests.get(f"{BASE_URL}/videos/")
        if response.status_code in [200, 401]:
            print("✓ Videos endpoint accessible")
        else:
            print(f"⚠ Videos returned status {response.status_code}")
    except Exception as e:
        print(f"✗ Videos test failed: {e}")
    
    print("\n" + "=" * 50)
    print("API Test Complete!")
    print("\nAvailable endpoints:")
    print("  - POST /api/auth/signup/")
    print("  - POST /api/auth/signin/")
    print("  - GET  /api/profiles/")
    print("  - GET  /api/videos/")
    print("  - GET  /api/products/")
    print("  - GET  /api/battles/")
    print("  - GET  /api/notifications/")
    print("  - GET  /api/vyra-points/")
    print("\nSee README_API.md for full documentation")

if __name__ == "__main__":
    test_api()

