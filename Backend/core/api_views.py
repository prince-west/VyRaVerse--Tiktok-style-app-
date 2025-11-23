from rest_framework import viewsets, status, parsers
from rest_framework.decorators import action, api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.authtoken.models import Token
from django.contrib.auth.models import User
from django.contrib.auth import authenticate
from django.db.models import Q, Count, Sum, F
from django.db import models
from django.utils import timezone
from datetime import timedelta
import json

from .models import (
    Profile, Badge, Video, Hashtag, Like, Comment, Share, Buzz,
    Follow, Product, Battle, BattleVote, Notification, VyRaPointsTransaction,
    Club, ClubMember, ClubPost, Challenge, UserChallengeProgress,
    LiveRoom, LiveBattle, Sound, ProfileSkin, UserSkin, Block, VideoAnalytics, Status, StatusView,
    Chat, ChatMessage
)
from .serializers import (
    ProfileSerializer, VideoSerializer, CommentSerializer, ProductSerializer,
    BattleSerializer, NotificationSerializer, VyRaPointsTransactionSerializer, UserSerializer,
    ClubSerializer, ClubMemberSerializer, ClubPostSerializer,
    ChallengeSerializer, UserChallengeProgressSerializer,
    LiveRoomSerializer, LiveBattleSerializer, SoundSerializer,
    ProfileSkinSerializer, UserSkinSerializer, BlockSerializer,
    VideoAnalyticsSerializer, StatusSerializer,
    ChatSerializer, ChatMessageSerializer
)

# Authentication Views
@api_view(['POST'])
@permission_classes([AllowAny])
def signup(request):
    """User registration"""
    username = request.data.get('username', '').strip()
    email = request.data.get('email', '').strip().lower()
    password = request.data.get('password')
    password2 = request.data.get('password2')

    if not username:
        return Response({'error': 'Username is required'}, status=status.HTTP_400_BAD_REQUEST)
    
    if not email:
        return Response({'error': 'Email is required'}, status=status.HTTP_400_BAD_REQUEST)

    if password != password2:
        return Response({'error': 'Passwords do not match'}, status=status.HTTP_400_BAD_REQUEST)

    # Check username (case-insensitive)
    if User.objects.filter(username__iexact=username).exists():
        return Response({'error': f'Username "{username}" is already taken. Please choose a different username.'}, status=status.HTTP_400_BAD_REQUEST)

    # Check email (case-insensitive, normalized to lowercase)
    if User.objects.filter(email__iexact=email).exists():
        return Response({'error': f'Email "{email}" is already registered. Please use a different email address.'}, status=status.HTTP_400_BAD_REQUEST)

    user = User.objects.create_user(username=username, email=email, password=password)
    profile = Profile.objects.create(user=user, id_user=user.id, display_name=username)
    token, created = Token.objects.get_or_create(user=user)

    return Response({
        'token': token.key,
        'user': UserSerializer(user).data,
        'profile': ProfileSerializer(profile, context={'request': request}).data
    }, status=status.HTTP_201_CREATED)

@api_view(['POST'])
@permission_classes([AllowAny])
def signin(request):
    """User login"""
    username = request.data.get('username')
    password = request.data.get('password')

    user = authenticate(username=username, password=password)
    if user:
        token, created = Token.objects.get_or_create(user=user)
        profile, created = Profile.objects.get_or_create(user=user, defaults={'id_user': user.id, 'display_name': user.username})
        return Response({
            'token': token.key,
            'user': UserSerializer(user).data,
            'profile': ProfileSerializer(profile, context={'request': request}).data
        })
    return Response({'error': 'Invalid credentials'}, status=status.HTTP_401_UNAUTHORIZED)

# Profile ViewSet - FIXED
class ProfileViewSet(viewsets.ModelViewSet):
    queryset = Profile.objects.all()
    serializer_class = ProfileSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        """Enhanced queryset with proper search functionality"""
        queryset = Profile.objects.select_related('user').all().order_by('-created_at')
        
        # Exact username lookup (for profile page navigation)
        username = self.request.query_params.get('username', None)
        if username:
            # Case-insensitive username lookup for exact match
            return queryset.filter(user__username__iexact=username).order_by('-created_at')
        
        # Search functionality (for search screen)
        search = self.request.query_params.get('search', None)
        if search:
            # Search by username or display name (case-insensitive)
            queryset = queryset.filter(
                Q(user__username__icontains=search) |
                Q(display_name__icontains=search)
            ).distinct().order_by('-created_at')
        
        return queryset

    def get_serializer_context(self):
        """Add request user info to context"""
        context = super().get_serializer_context()
        context['request'] = self.request
        context['current_user'] = self.request.user
        return context

    @action(detail=False, methods=['get'])
    def me(self, request):
        """Get current user's profile with counts"""
        profile = Profile.objects.get(user=request.user)
        
        # Calculate followers and following counts
        followers_count = Follow.objects.filter(following=request.user).count()
        following_count = Follow.objects.filter(follower=request.user).count()
        
        serializer = self.get_serializer(profile)
        data = serializer.data
        data['followersCount'] = followers_count
        data['followingCount'] = following_count
        data['isFollowing'] = False  # Can't follow yourself
        data['isFollowedBy'] = False
        
        return Response(data)

    def retrieve(self, request, *args, **kwargs):
        """Get a specific user's profile with relationship data"""
        instance = self.get_object()
        
        # Calculate followers and following counts
        followers_count = Follow.objects.filter(following=instance.user).count()
        following_count = Follow.objects.filter(follower=instance.user).count()
        
        # Check relationship with current user
        is_following = Follow.objects.filter(
            follower=request.user,
            following=instance.user
        ).exists()
        
        is_followed_by = Follow.objects.filter(
            follower=instance.user,
            following=request.user
        ).exists()
        
        serializer = self.get_serializer(instance)
        data = serializer.data
        data['followersCount'] = followers_count
        data['followingCount'] = following_count
        data['isFollowing'] = is_following
        data['isFollowedBy'] = is_followed_by
        
        return Response(data)

    def list(self, request, *args, **kwargs):
        """List profiles with relationship data for search results"""
        # If username is provided, return single profile without pagination
        username = request.query_params.get('username', None)
        if username:
            queryset = self.filter_queryset(self.get_queryset())
            if queryset.exists():
                profile = queryset.first()
                serializer = self.get_serializer(profile)
                data = serializer.data
                
                # Add relationship data
                followers_count = Follow.objects.filter(following=profile.user).count()
                following_count = Follow.objects.filter(follower=profile.user).count()
                is_following = Follow.objects.filter(
                    follower=request.user,
                    following=profile.user
                ).exists()
                is_followed_by = Follow.objects.filter(
                    follower=profile.user,
                    following=request.user
                ).exists()
                
                data['followersCount'] = followers_count
                data['followingCount'] = following_count
                data['isFollowing'] = is_following
                data['isFollowedBy'] = is_followed_by
                
                # Return as list for consistency with frontend expectations
                return Response([data])
            else:
                return Response([])
        
        # For search and other list operations, use pagination
        queryset = self.filter_queryset(self.get_queryset())
        page = self.paginate_queryset(queryset)
        
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            profiles_data = self._add_relationship_data(serializer.data, request.user)
            return self.get_paginated_response(profiles_data)
        serializer = self.get_serializer(queryset, many=True)
        profiles_data = self._add_relationship_data(serializer.data, request.user)
        return Response(profiles_data)

    def _add_relationship_data(self, profiles_data, current_user):
        """Helper to add follower counts and relationship status"""
        for profile in profiles_data:
            try:
                profile_obj = Profile.objects.get(id_user=profile['id'])
                
                # Get counts
                followers_count = Follow.objects.filter(following=profile_obj.user).count()
                following_count = Follow.objects.filter(follower=profile_obj.user).count()
                
                # Check relationships
                is_following = Follow.objects.filter(
                    follower=current_user,
                    following=profile_obj.user
                ).exists()
                
                is_followed_by = Follow.objects.filter(
                    follower=profile_obj.user,
                    following=current_user
                ).exists()
                
                profile['followersCount'] = followers_count
                profile['followingCount'] = following_count
                profile['isFollowing'] = is_following
                profile['isFollowedBy'] = is_followed_by
            except Profile.DoesNotExist:
                profile['followersCount'] = 0
                profile['followingCount'] = 0
                profile['isFollowing'] = False
                profile['isFollowedBy'] = False
        
        return profiles_data

    @action(detail=True, methods=['post'])
    def follow(self, request, pk=None):
        """Follow/unfollow a user"""
        profile = self.get_object()
        
        # Can't follow yourself
        if profile.user == request.user:
            return Response(
                {'error': 'You cannot follow yourself'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        follow, created = Follow.objects.get_or_create(
            follower=request.user,
            following=profile.user
        )
        
        if not created:
            follow.delete()
            return Response({'message': 'Unfollowed', 'following': False})
        
        # Create notification
        Notification.objects.create(
            user=profile.user,
            from_user=request.user,
            notification_type='follow',
            message=f'{request.user.username} started following you'
        )
        
        return Response({'message': 'Following', 'following': True})

    @action(detail=True, methods=['delete'])
    def unfollow(self, request, pk=None):
        """Unfollow a user"""
        profile = self.get_object()
        
        try:
            follow = Follow.objects.get(
                follower=request.user,
                following=profile.user
            )
            follow.delete()
            return Response({'message': 'Unfollowed successfully'})
        except Follow.DoesNotExist:
            return Response(
                {'error': 'You are not following this user'}, 
                status=status.HTTP_400_BAD_REQUEST
            )

    @action(detail=True, methods=['get'])
    def followers(self, request, pk=None):
        """Get user's followers list"""
        profile = self.get_object()
        followers = Follow.objects.filter(following=profile.user).select_related('follower__profile')
        
        followers_data = []
        for follow in followers:
            try:
                follower_profile = follow.follower.profile
                serializer = ProfileSerializer(follower_profile, context={'request': request})
                data = serializer.data
                
                # Add relationship info
                data['isFollowing'] = Follow.objects.filter(
                    follower=request.user,
                    following=follow.follower
                ).exists()
                
                followers_data.append(data)
            except Profile.DoesNotExist:
                continue
        
        return Response(followers_data)

    @action(detail=True, methods=['get'])
    def following(self, request, pk=None):
        """Get users that this user follows"""
        profile = self.get_object()
        following = Follow.objects.filter(follower=profile.user).select_related('following__profile')
        
        following_data = []
        for follow in following:
            try:
                following_profile = follow.following.profile
                serializer = ProfileSerializer(following_profile, context={'request': request})
                data = serializer.data
                
                # Add relationship info
                data['isFollowing'] = Follow.objects.filter(
                    follower=request.user,
                    following=follow.following
                ).exists()
                
                following_data.append(data)
            except Profile.DoesNotExist:
                continue
        
        return Response(following_data)

    @action(detail=False, methods=['get'])
    def suggested(self, request):
        """Get suggested users to follow"""
        # Get users that current user is not following
        following_ids = Follow.objects.filter(
            follower=request.user
        ).values_list('following_id', flat=True)
        
        # Exclude current user and already following
        suggested = Profile.objects.exclude(
            user__id__in=list(following_ids) + [request.user.id]
        )[:10]
        
        serializer = self.get_serializer(suggested, many=True)
        profiles_data = self._add_relationship_data(serializer.data, request.user)
        
        return Response(profiles_data)

# Video ViewSet
class VideoViewSet(viewsets.ModelViewSet):
    queryset = Video.objects.all().order_by('-created_at')
    serializer_class = VideoSerializer
    permission_classes = [IsAuthenticated]
    parser_classes = [parsers.MultiPartParser, parsers.FormParser, parsers.JSONParser]
    
    def get_serializer_context(self):
        """Ensure request context is passed to serializer for URL building"""
        context = super().get_serializer_context()
        context['request'] = self.request
        return context

    def get_queryset(self):
        queryset = Video.objects.all()
        username = self.request.query_params.get('username', None)
        if username:
            queryset = queryset.filter(username=username)
        privacy = self.request.query_params.get('privacy', None)
        if privacy:
            queryset = queryset.filter(privacy=privacy)
        
        # For main feed (no username filter), show only:
        # 1. Videos from users the current user follows
        # 2. Public videos from all users
        if not username and not privacy and not self.request.query_params.get('search', None):
            if self.request.user.is_authenticated:
                # Get list of followed users
                followed_users = Follow.objects.filter(follower=self.request.user).values_list('following__username', flat=True)
                # Include current user's own videos
                followed_users = list(followed_users) + [self.request.user.username]
                # Filter: videos from followed users OR public videos
                queryset = queryset.filter(
                    Q(username__in=followed_users) | Q(privacy='Public')
                ).distinct()
            else:
                # For unauthenticated users, only show public videos
                queryset = queryset.filter(privacy='Public')
        
        # Search functionality
        search = self.request.query_params.get('search', None)
        if search:
            queryset = queryset.filter(
                Q(description__icontains=search) |
                Q(username__icontains=search) |
                Q(hashtags__name__icontains=search)
            ).distinct()
        return queryset.order_by('-created_at')

    def perform_create(self, serializer):
        import logging
        logger = logging.getLogger(__name__)
        
        # Log what we're receiving
        logger.info(f"Video upload - Files: {list(self.request.FILES.keys())}")
        logger.info(f"Video upload - Data: {self.request.data}")
        
        # Save video with request context for URL building
        video = serializer.save(user=self.request.user, username=self.request.user.username)
        
        logger.info(f"Video saved - ID: {video.id}, video_file: {video.video_file}, video_file.name: {video.video_file.name if video.video_file else None}")
        
        # Ensure video_file is saved and accessible
        if video.video_file:
            logger.info(f"Video file exists: {video.video_file.name}, URL: {video.video_file.url}")
            # Force save to ensure file URL is generated
            video.save()
            logger.info(f"After save - URL: {video.video_file.url}")
        else:
            logger.error(f"Video {video.id} created but video_file is empty!")
        
        # Handle hashtags
        hashtag_names = self.request.data.get('hashtags', [])
        if isinstance(hashtag_names, str):
            hashtag_names = [h.strip() for h in hashtag_names.split(',')]
        for tag_name in hashtag_names:
            if tag_name:
                hashtag, created = Hashtag.objects.get_or_create(name=tag_name.strip().lstrip('#'))
                hashtag.videos.add(video)
                hashtag.usage_count += 1
                hashtag.save()
        
        # Award VyRa Points for upload
        self._award_points(self.request.user, 10, 'earned', f'Uploaded video: {video.id}')
        
        # Update profile upload count
        profile = Profile.objects.get(user=self.request.user)
        profile.upload_count += 1
        profile.save()

    @action(detail=True, methods=['post'])
    def like(self, request, pk=None):
        """Like/unlike a video"""
        video = self.get_object()
        like, created = Like.objects.get_or_create(video=video, user=request.user)
        if not created:
            like.delete()
            video.likes = max(0, video.likes - 1)
            video.save()
            return Response({'liked': False, 'likes': video.likes})
        video.likes += 1
        video.save()
        # Award VyRa Points
        self._award_points(request.user, 1, 'earned', f'Liked video: {video.id}')
        # Create notification
        if video.user != request.user:
            Notification.objects.create(
                user=video.user,
                from_user=request.user,
                notification_type='like',
                message=f'{request.user.username} liked your video',
                video=video
            )
        return Response({'liked': True, 'likes': video.likes})

    @action(detail=True, methods=['post'])
    def buzz(self, request, pk=None):
        """Buzz a video (VyRaChallenge engagement)"""
        video = self.get_object()
        buzz, created = Buzz.objects.get_or_create(video=video, user=request.user)
        if created:
            video.buzz_count += 1
            video.save()
            # Update profile total buzz
            profile = Profile.objects.get(user=video.user)
            profile.total_buzz += 1
            profile.save()
            # Award VyRa Points
            self._award_points(request.user, 3, 'earned', f'Buzzed video: {video.id}')
            # Create notification
            if video.user != request.user:
                Notification.objects.create(
                    user=video.user,
                    from_user=request.user,
                    notification_type='buzz',
                    message=f'{request.user.username} buzzed your video',
                    video=video
                )
            return Response({'buzzed': True, 'buzzCount': video.buzz_count})
        return Response({'buzzed': False, 'buzzCount': video.buzz_count})

    @action(detail=True, methods=['post'])
    def share(self, request, pk=None):
        """Share a video"""
        video = self.get_object()
        share, created = Share.objects.get_or_create(video=video, user=request.user)
        if created:
            video.shares += 1
            video.save()
            # Award VyRa Points
            self._award_points(request.user, 1, 'earned', f'Shared video: {video.id}')
            return Response({'shared': True, 'shares': video.shares})
        return Response({'shared': False, 'shares': video.shares})

    @action(detail=True, methods=['get'])
    def comments(self, request, pk=None):
        """Get comments for a video"""
        video = self.get_object()
        comments = Comment.objects.filter(video=video).order_by('-created_at')
        serializer = CommentSerializer(comments, many=True, context={'request': request})
        return Response(serializer.data)

    @action(detail=True, methods=['post'])
    def add_comment(self, request, pk=None):
        """Add a comment to a video"""
        video = self.get_object()
        comment = Comment.objects.create(
            video=video,
            user=request.user,
            username=request.user.username,
            text=request.data.get('text', '')
        )
        video.comments_count += 1
        video.save()
        # Award VyRa Points
        self._award_points(request.user, 2, 'earned', f'Commented on video: {video.id}')
        # Create notification
        if video.user != request.user:
            Notification.objects.create(
                user=video.user,
                from_user=request.user,
                notification_type='comment',
                message=f'{request.user.username} commented on your video',
                video=video
            )
        serializer = CommentSerializer(comment, context={'request': request})
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    def _award_points(self, user, points, transaction_type, description):
        """Helper method to award VyRa Points"""
        VyRaPointsTransaction.objects.create(
            user=user,
            points=points,
            transaction_type=transaction_type,
            description=description
        )
        profile = Profile.objects.get(user=user)
        profile.vyra_points += points
        profile.save()

    @action(detail=True, methods=['post'])
    def boost(self, request, pk=None):
        """Boost a video using VyRa Points (Creator Boost Mode)"""
        video = self.get_object()
        boost_type = request.data.get('boost_type', 'glow')  # glow, campus, hashtag
        points_cost = {
            'glow': 50,
            'campus': 100,
            'hashtag': 75
        }.get(boost_type, 50)
        
        profile = Profile.objects.get(user=request.user)
        if profile.vyra_points < points_cost:
            return Response({'error': 'Insufficient VyRa Points'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Deduct points
        VyRaPointsTransaction.objects.create(
            user=request.user,
            points=-points_cost,
            transaction_type='spent',
            description=f'Boosted video: {video.id} ({boost_type})',
            video=video
        )
        profile.vyra_points -= points_cost
        profile.save()
        
        # Add boost score
        boost_multiplier = {
            'glow': 10,
            'campus': 15,
            'hashtag': 12
        }.get(boost_type, 10)
        video.boost_score += boost_multiplier
        video.save()
        
        return Response({
            'boosted': True,
            'boostScore': video.boost_score,
            'remainingPoints': profile.vyra_points
        })

    @action(detail=False, methods=['get'])
    def nearby(self, request):
        """Get videos near a location (Universe Map)"""
        lat = request.query_params.get('lat', None)
        lng = request.query_params.get('lng', None)
        radius = float(request.query_params.get('radius', 10))  # km
        
        if not lat or not lng:
            return Response({'error': 'Latitude and longitude required'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Simple distance calculation (for production, use PostGIS or geopy)
        from math import radians, cos, sin, asin, sqrt
        lat, lng = float(lat), float(lng)
        
        videos = Video.objects.filter(
            latitude__isnull=False,
            longitude__isnull=False,
            privacy='Public'
        )
        
        nearby_videos = []
        for video in videos:
            # Haversine formula for distance
            lat1, lon1 = radians(lat), radians(lng)
            lat2, lon2 = radians(video.latitude), radians(video.longitude)
            dlat = lat2 - lat1
            dlon = lon2 - lon1
            a = sin(dlat/2)**2 + cos(lat1) * cos(lat2) * sin(dlon/2)**2
            c = 2 * asin(sqrt(a))
            distance_km = 6371 * c  # Earth radius in km
            
            if distance_km <= radius:
                nearby_videos.append(video)
        
        serializer = VideoSerializer(nearby_videos, many=True, context={'request': request})
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def recommended(self, request):
        """Get smart recommended videos"""
        # Get user's interests from liked videos
        liked_videos = Like.objects.filter(user=request.user).values_list('video', flat=True)
        liked_hashtags = Hashtag.objects.filter(videos__in=liked_videos).distinct()
        
        # Calculate score: likes*2 + comments*3 + buzz*4 + boost_score*5
        videos = Video.objects.filter(privacy='Public').annotate(
            score=(Count('likes_rel') * 2) + 
                  (Count('comments_rel') * 3) + 
                  (Count('buzzes') * 4) +
                  (F('boost_score') * 5)
        )
        
        # Filter by user's interests
        if liked_hashtags:
            videos = videos.filter(hashtags__in=liked_hashtags).distinct()
        
        # Sort by score and return top 20
        videos = videos.order_by('-score', '-created_at')[:20]
        serializer = VideoSerializer(videos, many=True, context={'request': request})
        return Response(serializer.data)

# Product ViewSet (VyRaMart) - Enhanced with boost
class ProductViewSet(viewsets.ModelViewSet):
    queryset = Product.objects.all().order_by('-boost_score', '-created_at')
    serializer_class = ProductSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        queryset = Product.objects.all()
        seller = self.request.query_params.get('seller', None)
        if seller:
            queryset = queryset.filter(seller__username=seller)
        is_promoted = self.request.query_params.get('is_promoted', None)
        if is_promoted == 'true':
            queryset = queryset.filter(is_promoted=True)
        return queryset.order_by('-boost_score', '-created_at')

    def perform_create(self, serializer):
        serializer.save(seller=self.request.user, seller_name=self.request.user.username)

    @action(detail=True, methods=['post'])
    def view(self, request, pk=None):
        """Increment product views"""
        product = self.get_object()
        product.views += 1
        product.save()
        return Response({'views': product.views})

    @action(detail=True, methods=['post'])
    def purchase(self, request, pk=None):
        """Purchase a product"""
        product = self.get_object()
        product.purchases += 1
        product.save()
        return Response({'message': 'Purchase successful', 'purchases': product.purchases})

    @action(detail=True, methods=['post'])
    def boost(self, request, pk=None):
        """Boost product listing"""
        product = self.get_object()
        if product.seller != request.user:
            return Response({'error': 'Only seller can boost'}, status=status.HTTP_403_FORBIDDEN)
        
        points_cost = 100
        profile = Profile.objects.get(user=request.user)
        if profile.vyra_points < points_cost:
            return Response({'error': 'Insufficient VyRa Points'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Deduct points
        profile.vyra_points -= points_cost
        profile.save()
        VyRaPointsTransaction.objects.create(
            user=request.user,
            points=-points_cost,
            transaction_type='spent',
            description=f'Boosted product: {product.id}'
        )
        
        # Add boost score
        product.boost_score += 20
        product.save()
        
        return Response({
            'boosted': True,
            'boostScore': product.boost_score,
            'remainingPoints': profile.vyra_points
        })

# Battle ViewSet (VyRaBattles)
class BattleViewSet(viewsets.ModelViewSet):
    queryset = Battle.objects.all().order_by('-created_at')
    serializer_class = BattleSerializer
    permission_classes = [IsAuthenticated]

    def perform_create(self, serializer):
        serializer.save(creator=self.request.user)

    @action(detail=True, methods=['post'])
    def vote(self, request, pk=None):
        """Vote in a battle"""
        battle = self.get_object()
        voted_for = request.data.get('voted_for')  # 'original' or 'challenger'
        
        # Check if user already voted
        existing_vote = BattleVote.objects.filter(battle=battle, user=request.user).first()
        if existing_vote:
            return Response({'error': 'Already voted'}, status=status.HTTP_400_BAD_REQUEST)

        if voted_for == 'original':
            battle.original_votes += 1
            voted_user = battle.creator
        else:
            battle.challenger_votes += 1
            voted_user = battle.challenger

        BattleVote.objects.create(
            battle=battle,
            user=request.user,
            voted_for=voted_user
        )
        battle.save()

        # Award VyRa Points
        VyRaPointsTransaction.objects.create(
            user=request.user,
            points=1,
            transaction_type='earned',
            description=f'Voted in battle: {battle.id}',
            battle=battle
        )

        return Response({
            'originalVotes': battle.original_votes,
            'challengerVotes': battle.challenger_votes
        })

# Notification ViewSet
class NotificationViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Notification.objects.all()
    serializer_class = NotificationSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Notification.objects.filter(user=self.request.user).order_by('-created_at')

    @action(detail=True, methods=['post'])
    def mark_read(self, request, pk=None):
        """Mark notification as read"""
        notification = self.get_object()
        notification.is_read = True
        notification.save()
        return Response({'message': 'Marked as read'})

    @action(detail=False, methods=['post'])
    def mark_all_read(self, request):
        """Mark all notifications as read"""
        Notification.objects.filter(user=request.user, is_read=False).update(is_read=True)
        return Response({'message': 'All notifications marked as read'})

# VyRaPoints ViewSet
class VyRaPointsViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = VyRaPointsTransaction.objects.all()
    serializer_class = VyRaPointsTransactionSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return VyRaPointsTransaction.objects.filter(user=self.request.user).order_by('-created_at')

    @action(detail=False, methods=['get'])
    def total(self, request):
        """Get total VyRa Points for current user"""
        profile = Profile.objects.get(user=request.user)
        return Response({'totalPoints': profile.vyra_points})

    @action(detail=False, methods=['get'])
    def leaderboard(self, request):
        """Get weekly leaderboard"""
        week_ago = timezone.now() - timedelta(days=7)
        transactions = VyRaPointsTransaction.objects.filter(
            created_at__gte=week_ago,
            transaction_type='earned'
        ).values('user__username').annotate(
            total_points=Sum('points')
        ).order_by('-total_points')[:10]
        
        return Response(list(transactions))

# Club ViewSet
class ClubViewSet(viewsets.ModelViewSet):
    queryset = Club.objects.all().order_by('-created_at')
    serializer_class = ClubSerializer
    permission_classes = [IsAuthenticated]
    parser_classes = [parsers.JSONParser, parsers.MultiPartParser, parsers.FormParser]

    def perform_create(self, serializer):
        club = serializer.save(creator=self.request.user)
        ClubMember.objects.create(club=club, user=self.request.user, role='admin')
        club.member_count = 1
        club.save()

    @action(detail=True, methods=['post'])
    def join(self, request, pk=None):
        club = self.get_object()
        member, created = ClubMember.objects.get_or_create(
            club=club, user=request.user, defaults={'role': 'member'}
        )
        if created:
            club.member_count += 1
            club.save()
            return Response({'joined': True, 'memberCount': club.member_count})
        return Response({'joined': False, 'message': 'Already a member'})

    @action(detail=True, methods=['post'])
    def leave(self, request, pk=None):
        club = self.get_object()
        try:
            member = ClubMember.objects.get(club=club, user=request.user)
            if member.role == 'admin':
                return Response({'error': 'Admin cannot leave'}, status=status.HTTP_400_BAD_REQUEST)
            member.delete()
            club.member_count = max(0, club.member_count - 1)
            club.save()
            return Response({'left': True, 'memberCount': club.member_count})
        except ClubMember.DoesNotExist:
            return Response({'error': 'Not a member'}, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=True, methods=['get'])
    def feed(self, request, pk=None):
        club = self.get_object()
        posts = ClubPost.objects.filter(club=club).order_by('-created_at')
        videos = [post.video for post in posts]
        serializer = VideoSerializer(videos, many=True, context={'request': request})
        return Response(serializer.data)

# Challenge ViewSet
class ChallengeViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Challenge.objects.filter(is_active=True).order_by('-created_at')
    serializer_class = ChallengeSerializer
    permission_classes = [IsAuthenticated]

    @action(detail=True, methods=['post'])
    def claim(self, request, pk=None):
        challenge = self.get_object()
        progress, created = UserChallengeProgress.objects.get_or_create(
            challenge=challenge, user=request.user
        )
        if progress.completed and not progress.claimed:
            progress.claimed = True
            progress.save()
            profile = Profile.objects.get(user=request.user)
            profile.vyra_points += challenge.points_reward
            profile.save()
            VyRaPointsTransaction.objects.create(
                user=request.user, points=challenge.points_reward,
                transaction_type='reward', description=f'Completed challenge: {challenge.title}'
            )
            return Response({'claimed': True, 'points': challenge.points_reward})
        return Response({'claimed': False, 'message': 'Challenge not completed or already claimed'})

# Live Room ViewSet
class LiveRoomViewSet(viewsets.ModelViewSet):
    queryset = LiveRoom.objects.all().order_by('-created_at')
    serializer_class = LiveRoomSerializer
    permission_classes = [IsAuthenticated]

    def perform_create(self, serializer):
        serializer.save(host=self.request.user)

    @action(detail=True, methods=['post'])
    def start(self, request, pk=None):
        room = self.get_object()
        if room.host != request.user:
            return Response({'error': 'Only host can start'}, status=status.HTTP_403_FORBIDDEN)
        room.status = 'live'
        room.started_at = timezone.now()
        room.save()
        return Response({'started': True})

    @action(detail=True, methods=['post'])
    def end(self, request, pk=None):
        room = self.get_object()
        if room.host != request.user:
            return Response({'error': 'Only host can end'}, status=status.HTTP_403_FORBIDDEN)
        room.status = 'ended'
        room.ended_at = timezone.now()
        room.save()
        return Response({'ended': True})

    @action(detail=True, methods=['post'])
    def join_viewer(self, request, pk=None):
        room = self.get_object()
        if room.status == 'live':
            room.viewer_count += 1
            room.save()
        return Response({'viewerCount': room.viewer_count})

# Live Battle ViewSet
class LiveBattleViewSet(viewsets.ModelViewSet):
    queryset = LiveBattle.objects.all().order_by('-started_at')
    serializer_class = LiveBattleSerializer
    permission_classes = [IsAuthenticated]

    @action(detail=True, methods=['post'])
    def vote(self, request, pk=None):
        battle = self.get_object()
        participant = request.data.get('participant')
        points_cost = 5
        profile = Profile.objects.get(user=request.user)
        if profile.vyra_points < points_cost:
            return Response({'error': 'Insufficient VyRa Points'}, status=status.HTTP_400_BAD_REQUEST)
        profile.vyra_points -= points_cost
        profile.save()
        VyRaPointsTransaction.objects.create(
            user=request.user, points=-points_cost,
            transaction_type='spent', description=f'Voted in live battle: {battle.id}'
        )
        if participant == '1':
            battle.participant1_votes += 1
        else:
            battle.participant2_votes += 1
        battle.save()
        return Response({
            'voted': True,
            'participant1Votes': battle.participant1_votes,
            'participant2Votes': battle.participant2_votes
        })

# Sound ViewSet
class SoundViewSet(viewsets.ModelViewSet):
    queryset = Sound.objects.all().order_by('-usage_count', '-created_at')
    serializer_class = SoundSerializer
    permission_classes = [IsAuthenticated]

    def perform_create(self, serializer):
        serializer.save(uploader=self.request.user)

    @action(detail=True, methods=['post'])
    def use(self, request, pk=None):
        sound = self.get_object()
        sound.usage_count += 1
        sound.save()
        return Response({'usageCount': sound.usage_count})

# Profile Skin ViewSet
class ProfileSkinViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = ProfileSkin.objects.all().order_by('cost_points')
    serializer_class = ProfileSkinSerializer
    permission_classes = [IsAuthenticated]

    @action(detail=True, methods=['post'])
    def purchase(self, request, pk=None):
        skin = self.get_object()
        profile = Profile.objects.get(user=request.user)
        if profile.vyra_points < skin.cost_points:
            return Response({'error': 'Insufficient VyRa Points'}, status=status.HTTP_400_BAD_REQUEST)
        if UserSkin.objects.filter(user=request.user, skin=skin).exists():
            return Response({'error': 'Already owned'}, status=status.HTTP_400_BAD_REQUEST)
        profile.vyra_points -= skin.cost_points
        profile.save()
        VyRaPointsTransaction.objects.create(
            user=request.user, points=-skin.cost_points,
            transaction_type='spent', description=f'Purchased skin: {skin.name}'
        )
        UserSkin.objects.create(user=request.user, skin=skin)
        return Response({'purchased': True, 'remainingPoints': profile.vyra_points})

    @action(detail=False, methods=['get'])
    def my_skins(self, request):
        skins = UserSkin.objects.filter(user=request.user)
        serializer = UserSkinSerializer(skins, many=True, context={'request': request})
        return Response(serializer.data)

    @action(detail=True, methods=['post'])
    def activate(self, request, pk=None):
        try:
            user_skin = UserSkin.objects.get(user=request.user, skin_id=pk)
            UserSkin.objects.filter(user=request.user).update(is_active=False)
            user_skin.is_active = True
            user_skin.save()
            return Response({'activated': True})
        except UserSkin.DoesNotExist:
            return Response({'error': 'Skin not owned'}, status=status.HTTP_400_BAD_REQUEST)

# Block ViewSet
class BlockViewSet(viewsets.ModelViewSet):
    queryset = Block.objects.all()
    serializer_class = BlockSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Block.objects.filter(blocker=self.request.user)

    def perform_create(self, serializer):
        serializer.save(blocker=self.request.user)

    @action(detail=False, methods=['post'])
    def unblock(self, request):
        blocked_id = request.data.get('blocked_id')
        try:
            block = Block.objects.get(blocker=request.user, blocked_id=blocked_id)
            block.delete()
            return Response({'unblocked': True})
        except Block.DoesNotExist:
            return Response({'error': 'User not blocked'}, status=status.HTTP_400_BAD_REQUEST)

# Video Analytics ViewSet
class VideoAnalyticsViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = VideoAnalytics.objects.all()
    serializer_class = VideoAnalyticsSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return VideoAnalytics.objects.filter(video__user=self.request.user)

    @action(detail=False, methods=['get'])
    def my_analytics(self, request):
        analytics = VideoAnalytics.objects.filter(video__user=request.user)
        serializer = VideoAnalyticsSerializer(analytics, many=True, context={'request': request})
        return Response(serializer.data)

# Chat ViewSet
class ChatViewSet(viewsets.ModelViewSet):
    queryset = Chat.objects.all().order_by('-updated_at')
    serializer_class = ChatSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        """Get all chats where current user is a participant"""
        return Chat.objects.filter(participants=self.request.user).order_by('-updated_at')

    def get_serializer_context(self):
        """Add request context"""
        context = super().get_serializer_context()
        context['request'] = self.request
        return context

    @action(detail=False, methods=['post'])
    def get_or_create(self, request):
        """Get or create a chat with a specific user"""
        other_user_id = request.data.get('user_id')
        if not other_user_id:
            return Response({'error': 'user_id is required'}, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            other_user = User.objects.get(id=other_user_id)
        except User.DoesNotExist:
            return Response({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)
        
        if other_user == request.user:
            return Response({'error': 'Cannot create chat with yourself'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Check if chat already exists
        existing_chat = Chat.objects.filter(
            participants=request.user
        ).filter(
            participants=other_user
        ).distinct().first()
        
        if existing_chat:
            serializer = self.get_serializer(existing_chat)
            return Response(serializer.data)
        
        # Create new chat
        chat = Chat.objects.create()
        chat.participants.add(request.user, other_user)
        serializer = self.get_serializer(chat)
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['get'])
    def messages(self, request, pk=None):
        """Get all messages for a chat"""
        chat = self.get_object()
        messages = chat.messages.order_by('created_at')
        serializer = ChatMessageSerializer(messages, many=True, context={'request': request})
        return Response(serializer.data)

    @action(detail=True, methods=['post'])
    def send_message(self, request, pk=None):
        """Send a message in a chat"""
        chat = self.get_object()
        message_text = request.data.get('message', '').strip()
        
        if not message_text:
            return Response({'error': 'Message cannot be empty'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Check if user is a participant
        if request.user not in chat.participants.all():
            return Response({'error': 'You are not a participant in this chat'}, status=status.HTTP_403_FORBIDDEN)
        
        message = ChatMessage.objects.create(
            chat=chat,
            sender=request.user,
            message=message_text
        )
        
        # Update chat's updated_at
        chat.save()
        
        serializer = ChatMessageSerializer(message, context={'request': request})
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['post'])
    def mark_read(self, request, pk=None):
        """Mark all messages in chat as read"""
        chat = self.get_object()
        chat.messages.exclude(sender=request.user).update(is_read=True)
        return Response({'message': 'Messages marked as read'})

# Chat Message ViewSet
class ChatMessageViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = ChatMessage.objects.all().order_by('-created_at')
    serializer_class = ChatMessageSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        """Get messages for chats where user is a participant"""
        return ChatMessage.objects.filter(
            chat__participants=self.request.user
        ).order_by('-created_at')

# Status ViewSet (Stories 2.0)
class StatusViewSet(viewsets.ModelViewSet):
    queryset = Status.objects.all().order_by('-created_at')
    serializer_class = StatusSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Status.objects.filter(expires_at__gt=timezone.now())

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

    @action(detail=True, methods=['post'])
    def view(self, request, pk=None):
        status_obj = self.get_object()
        StatusView.objects.get_or_create(status=status_obj, user=request.user)
        status_obj.views_count += 1
        status_obj.save()
        return Response({'viewsCount': status_obj.views_count})

    @action(detail=True, methods=['post'])
    def vote_poll(self, request, pk=None):
        status_obj = self.get_object()
        option_index = request.data.get('option_index')
        if not status_obj.poll_options:
            return Response({'error': 'No poll'}, status=status.HTTP_400_BAD_REQUEST)
        if option_index >= len(status_obj.poll_options):
            return Response({'error': 'Invalid option'}, status=status.HTTP_400_BAD_REQUEST)
        status_obj.poll_options[option_index]['votes'] += 1
        status_obj.save()
        return Response({'pollOptions': status_obj.poll_options})

