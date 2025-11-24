from django.shortcuts import render, redirect
from django.contrib.auth.models import User
from django.contrib import auth
from django.contrib import messages
from django.http import HttpResponse, JsonResponse
from django.contrib.auth.decorators import login_required
from .models import Profile, Post, LikePost, FollowersCount
from itertools import chain
import random

@login_required(login_url='signin')
def index(request):
    # This is an API-only backend. Use /api/videos/ for video feed
    return JsonResponse({
        'message': 'This is an API-only backend. Please use the API endpoints.',
        'api_endpoints': {
            'videos': '/api/videos/',
            'profiles': '/api/profiles/',
            'signin': '/api/auth/signin/',
            'signup': '/api/auth/signup/'
        }
    }, status=200)

# The active codes here is used to display html in the server
# But the non active ones(comment) is used to give a HttpResponse
@login_required(login_url='signin')
def upload(request):
    # This is an API-only backend. Use /api/videos/ for video uploads
    return JsonResponse({
        'message': 'This is an API-only backend. Please use the API endpoints.',
        'api_endpoint': '/api/videos/',
        'method': 'POST'
    }, status=200)

@login_required(login_url='signin')
def search(request):
    # This is an API-only backend. Use /api/profiles/?search=query for searching
    return JsonResponse({
        'message': 'This is an API-only backend. Please use the API endpoints.',
        'api_endpoint': '/api/profiles/?search=query',
        'method': 'GET'
    }, status=200)


@login_required(login_url='signin')
def like_post(request):
    # This is an API-only backend. Use /api/videos/{id}/like/ for liking videos
    return JsonResponse({
        'message': 'This is an API-only backend. Please use the API endpoints.',
        'api_endpoint': '/api/videos/{id}/like/',
        'method': 'POST'
    }, status=200)


@login_required(login_url='signin')
def profile(request, pk):
    # This is an API-only backend. Use /api/profiles/{id}/ for profile data
    return JsonResponse({
        'message': 'This is an API-only backend. Please use the API endpoints.',
        'api_endpoint': f'/api/profiles/?username={pk}',
        'method': 'GET'
    }, status=200)


@login_required(login_url='signin')
def settings(request):
    # This is an API-only backend. Use /api/profiles/me/ for profile settings
    return JsonResponse({
        'message': 'This is an API-only backend. Please use the API endpoints.',
        'api_endpoint': '/api/profiles/me/',
        'method': 'PATCH'
    }, status=200)


def signup(request):
    # This is an API-only backend. Use /api/auth/signup/ for registration
    return JsonResponse({
        'message': 'This is an API-only backend. Please use the API endpoints.',
        'api_endpoint': '/api/auth/signup/',
        'method': 'POST',
        'required_fields': ['username', 'email', 'password', 'password2']
    }, status=200)
    

def signin(request):
    # This is an API-only backend. Use /api/auth/signin/ for authentication
    return JsonResponse({
        'message': 'This is an API-only backend. Please use the API endpoints.',
        'api_endpoint': '/api/auth/signin/',
        'method': 'POST',
        'required_fields': ['username', 'password']
    }, status=200)
    

@login_required(login_url='signin')
def follow(request):
    # This is an API-only backend. Use /api/profiles/{id}/follow/ for following users
    return JsonResponse({
        'message': 'This is an API-only backend. Please use the API endpoints.',
        'api_endpoint': '/api/profiles/{id}/follow/',
        'method': 'POST'
    }, status=200)


@login_required(login_url='signin')   
def logout(request):
    # This is an API-only backend. Token-based auth doesn't require explicit logout
    auth.logout(request)
    return JsonResponse({
        'message': 'Logged out successfully. For API authentication, simply stop sending the token.'
    }, status=200)

