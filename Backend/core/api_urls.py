from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import api_views

router = DefaultRouter()
router.register(r'profiles', api_views.ProfileViewSet, basename='profile')
router.register(r'videos', api_views.VideoViewSet, basename='video')
router.register(r'products', api_views.ProductViewSet, basename='product')
router.register(r'battles', api_views.BattleViewSet, basename='battle')
router.register(r'notifications', api_views.NotificationViewSet, basename='notification')
router.register(r'vyra-points', api_views.VyRaPointsViewSet, basename='vyra-points')
# New feature ViewSets
router.register(r'clubs', api_views.ClubViewSet, basename='club')
router.register(r'challenges', api_views.ChallengeViewSet, basename='challenge')
router.register(r'live-rooms', api_views.LiveRoomViewSet, basename='live-room')
router.register(r'live-battles', api_views.LiveBattleViewSet, basename='live-battle')
router.register(r'sounds', api_views.SoundViewSet, basename='sound')
router.register(r'profile-skins', api_views.ProfileSkinViewSet, basename='profile-skin')
router.register(r'blocks', api_views.BlockViewSet, basename='block')
router.register(r'video-analytics', api_views.VideoAnalyticsViewSet, basename='video-analytics')
router.register(r'statuses', api_views.StatusViewSet, basename='status')
router.register(r'chats', api_views.ChatViewSet, basename='chat')
router.register(r'chat-messages', api_views.ChatMessageViewSet, basename='chat-message')

urlpatterns = [
    path('auth/signup/', api_views.signup, name='api-signup'),
    path('auth/signin/', api_views.signin, name='api-signin'),
    path('', include(router.urls)),
]

