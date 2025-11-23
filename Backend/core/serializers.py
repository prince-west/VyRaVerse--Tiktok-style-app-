from rest_framework import serializers
from django.contrib.auth.models import User
from .models import (
    Profile, Badge, Video, Hashtag, Like, Comment, Share, Buzz,
    Follow, Product, Battle, BattleVote, Notification, VyRaPointsTransaction,
    Club, ClubMember, ClubPost, Challenge, UserChallengeProgress,
    LiveRoom, LiveBattle, Sound, ProfileSkin, UserSkin, Block, VideoAnalytics, Status,
    Chat, ChatMessage
)

# User Serializer
class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'first_name', 'last_name', 'date_joined']
        read_only_fields = ['id', 'date_joined']

# Badge Serializer
class BadgeSerializer(serializers.ModelSerializer):
    class Meta:
        model = Badge
        fields = ['id', 'name', 'description', 'icon', 'earned_at']

# Profile Serializer - ENHANCED with follower counts
class ProfileSerializer(serializers.ModelSerializer):
    username = serializers.CharField(source='user.username', read_only=True)
    badges = BadgeSerializer(many=True, read_only=True)
    profile_image_url = serializers.SerializerMethodField()
    followers_count = serializers.SerializerMethodField()
    following_count = serializers.SerializerMethodField()
    is_following = serializers.SerializerMethodField()
    is_followed_by = serializers.SerializerMethodField()

    class Meta:
        model = Profile
        fields = [
            'id', 'username', 'display_name', 'bio', 'profile_image_url',
            'total_likes', 'total_buzz', 'vyra_points', 'upload_count',
            'badges', 'is_verified', 'theme_accent', 'created_at', 'location',
            'followers_count', 'following_count', 'is_following', 'is_followed_by'
        ]
        read_only_fields = ['id', 'created_at', 'total_likes', 'total_buzz', 'vyra_points', 'upload_count']

    def get_profile_image_url(self, obj):
        # Check both profile_image and Profileimg (legacy field)
        image_field = obj.profile_image if hasattr(obj, 'profile_image') and obj.profile_image else None
        if not image_field and hasattr(obj, 'Profileimg') and obj.Profileimg:
            image_field = obj.Profileimg
        
        if image_field:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(image_field.url)
            return image_field.url
        return None

    def get_followers_count(self, obj):
        """Calculate followers count"""
        from .models import Follow
        return Follow.objects.filter(following=obj.user).count()

    def get_following_count(self, obj):
        """Calculate following count"""
        from .models import Follow
        return Follow.objects.filter(follower=obj.user).count()

    def get_is_following(self, obj):
        """Check if current user is following this profile"""
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            from .models import Follow
            return Follow.objects.filter(
                follower=request.user,
                following=obj.user
            ).exists()
        return False

    def get_is_followed_by(self, obj):
        """Check if this profile is following current user"""
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            from .models import Follow
            return Follow.objects.filter(
                follower=obj.user,
                following=request.user
            ).exists()
        return False

    def to_representation(self, instance):
        data = super().to_representation(instance)
        # Match Flutter UserProfile structure
        data['id'] = str(instance.id_user)
        data['profileImageUrl'] = data.pop('profile_image_url')
        data['displayName'] = data.pop('display_name')
        data['totalLikes'] = data.pop('total_likes')
        data['totalBuzz'] = data.pop('total_buzz')
        data['vyraPoints'] = data.pop('vyra_points')
        data['uploadCount'] = data.pop('upload_count')
        data['isVerified'] = data.pop('is_verified')
        data['themeAccent'] = data.pop('theme_accent')
        data['createdAt'] = instance.created_at.isoformat() if instance.created_at else None
        data['followersCount'] = data.pop('followers_count')
        data['followingCount'] = data.pop('following_count')
        data['isFollowing'] = data.pop('is_following')
        data['isFollowedBy'] = data.pop('is_followed_by')
        return data

# Video Serializer - matches Flutter VideoItem
class VideoSerializer(serializers.ModelSerializer):
    username = serializers.CharField(read_only=True)
    userId = serializers.CharField(source='user.id', read_only=True)
    videoUrl = serializers.SerializerMethodField()
    videoPath = serializers.SerializerMethodField()
    isLocal = serializers.BooleanField(read_only=True)
    comments = serializers.IntegerField(source='comments_count', read_only=True)
    buzzCount = serializers.IntegerField(source='buzz_count', read_only=True)
    allowComments = serializers.BooleanField(source='allow_comments', read_only=True)
    allowDuet = serializers.BooleanField(source='allow_duet', read_only=True)
    allowStitch = serializers.BooleanField(source='allow_stitch', read_only=True)
    createdAt = serializers.DateTimeField(source='created_at', read_only=True)
    thumbnailUrl = serializers.CharField(source='thumbnail_url', read_only=True, allow_null=True)
    hashtags = serializers.SerializerMethodField()

    class Meta:
        model = Video
        fields = [
            'id', 'username', 'userId', 'description', 'videoUrl', 'videoPath',
            'video_file', 'video_url', 'isLocal', 'likes', 'comments', 'shares', 'buzzCount', 'privacy',
            'location', 'hashtags', 'allowComments', 'allowDuet', 'allowStitch',
            'createdAt', 'thumbnailUrl'
        ]
        read_only_fields = ['id', 'likes', 'comments', 'shares', 'buzzCount', 'created_at', 'videoUrl', 'videoPath']
        extra_kwargs = {
            'video_file': {'write_only': False},  # Allow writing to video_file
        }

    def get_videoUrl(self, obj):
        """CRITICAL: Always return absolute URL"""
        import logging
        logger = logging.getLogger(__name__)
        
        # Check video_url field first
        if obj.video_url:
            url = str(obj.video_url).strip()
            if url and url != 'null' and url.lower() != 'none':
                # If already absolute, return it
                if url.startswith('http://') or url.startswith('https://'):
                    return url
                # Make relative URL absolute
                request = self.context.get('request')
                if request:
                    return request.build_absolute_uri(url)
                # Fallback to localhost
                return f"http://127.0.0.1:8000{url if url.startswith('/') else '/' + url}"
        
        # Check video_file field
        if obj.video_file:
            try:
                # Get the file URL - this should work for FileField
                file_url = obj.video_file.url
                if file_url:
                    request = self.context.get('request')
                    if request:
                        # Build absolute URI using request
                        absolute_url = request.build_absolute_uri(file_url)
                        logger.info(f"Built video URL from file with request: {absolute_url}")
                        return absolute_url
                    else:
                        # No request - build manually
                        if file_url.startswith('http://') or file_url.startswith('https://'):
                            logger.info(f"Video URL already absolute: {file_url}")
                            return file_url
                        # Make relative path absolute
                        # FileField.url typically returns something like '/media/videos/filename.mp4'
                        absolute_url = f"http://127.0.0.1:8000{file_url if file_url.startswith('/') else '/' + file_url}"
                        logger.info(f"Built video URL from file without request: {absolute_url}")
                        return absolute_url
                else:
                    logger.warning(f"Video {obj.id} has video_file but file_url is empty")
            except Exception as e:
                logger.error(f"Error building video URL from file for video {obj.id}: {e}")
                # Try to construct URL from file name if possible
                try:
                    if obj.video_file.name:
                        file_path = obj.video_file.name
                        request = self.context.get('request')
                        if request:
                            return request.build_absolute_uri(f'/media/{file_path}')
                        return f"http://127.0.0.1:8000/media/{file_path}"
                except:
                    pass
        
        logger.warning(f"Video {obj.id} has no videoUrl - video_url={obj.video_url}, video_file={obj.video_file}")
        return None

    def get_videoPath(self, obj):
        if obj.video_file:
            return obj.video_file.path
        return None

    def get_hashtags(self, obj):
        return [hashtag.name for hashtag in obj.hashtags.all()]

    def to_representation(self, instance):
        data = super().to_representation(instance)
        data['id'] = str(instance.id)
        data['boostScore'] = instance.boost_score
        data['collabType'] = instance.collab_type
        data['sensitiveFlag'] = instance.sensitive_flag
        
        # Ensure videoUrl is never null if video exists
        # Try multiple times to get the URL
        if not data.get('videoUrl'):
            # First try the method again with fresh context
            video_url = self.get_videoUrl(instance)
            if video_url:
                data['videoUrl'] = video_url
            elif instance.video_file:
                # If video_file exists but URL is None, try constructing it manually
                try:
                    file_name = instance.video_file.name
                    if file_name:
                        request = self.context.get('request')
                        if request:
                            data['videoUrl'] = request.build_absolute_uri(f'/media/{file_name}')
                        else:
                            data['videoUrl'] = f'http://127.0.0.1:8000/media/{file_name}'
                except:
                    pass
        
        return data

# Comment Serializer
class CommentSerializer(serializers.ModelSerializer):
    username = serializers.CharField(read_only=True)
    userId = serializers.CharField(source='user.id', read_only=True)
    timestamp = serializers.DateTimeField(source='created_at', read_only=True)

    class Meta:
        model = Comment
        fields = ['id', 'userId', 'username', 'text', 'timestamp', 'likes']
        read_only_fields = ['id', 'likes', 'created_at']

    def to_representation(self, instance):
        data = super().to_representation(instance)
        data['id'] = str(instance.id)
        return data

# Product Serializer - matches Flutter ProductItem
class ProductSerializer(serializers.ModelSerializer):
    sellerId = serializers.CharField(source='seller.id', read_only=True)
    sellerName = serializers.CharField(source='seller_name', read_only=True)
    imageUrl = serializers.CharField(source='image_url', allow_null=True, read_only=True)
    videoUrl = serializers.CharField(source='video_url', allow_null=True, read_only=True)
    isPromoted = serializers.BooleanField(source='is_promoted', read_only=True)
    createdAt = serializers.DateTimeField(source='created_at', read_only=True)

    class Meta:
        model = Product
        fields = [
            'id', 'name', 'description', 'price', 'imageUrl', 'videoUrl',
            'sellerId', 'sellerName', 'views', 'purchases', 'isPromoted', 'createdAt'
        ]
        read_only_fields = ['id', 'views', 'purchases', 'created_at']

    def to_representation(self, instance):
        data = super().to_representation(instance)
        data['id'] = str(instance.id)
        data['price'] = float(instance.price)
        data['boostScore'] = instance.boost_score
        return data

# Battle Serializer
class BattleSerializer(serializers.ModelSerializer):
    originalVideo = serializers.PrimaryKeyRelatedField(source='original_video', queryset=Video.objects.all())
    challengerVideo = serializers.PrimaryKeyRelatedField(source='challenger_video', queryset=Video.objects.all())
    originalVotes = serializers.IntegerField(source='original_votes', read_only=True)
    challengerVotes = serializers.IntegerField(source='challenger_votes', read_only=True)
    createdAt = serializers.DateTimeField(source='created_at', read_only=True)
    endsAt = serializers.DateTimeField(source='ends_at', allow_null=True)

    class Meta:
        model = Battle
        fields = [
            'id', 'originalVideo', 'challengerVideo', 'creator', 'challenger',
            'originalVotes', 'challengerVotes', 'status', 'winner', 'createdAt', 'endsAt'
        ]
        read_only_fields = ['id', 'original_votes', 'challenger_votes', 'created_at']

    def to_representation(self, instance):
        data = super().to_representation(instance)
        data['id'] = str(instance.id)
        if instance.original_video:
            data['originalVideo'] = str(instance.original_video.id)
        if instance.challenger_video:
            data['challengerVideo'] = str(instance.challenger_video.id)
        return data

# Notification Serializer
class NotificationSerializer(serializers.ModelSerializer):
    userId = serializers.CharField(source='user.id', read_only=True)
    fromUserId = serializers.CharField(source='from_user.id', read_only=True, allow_null=True)
    notificationType = serializers.CharField(source='notification_type', read_only=True)
    isRead = serializers.BooleanField(source='is_read', read_only=True)
    createdAt = serializers.DateTimeField(source='created_at', read_only=True)

    class Meta:
        model = Notification
        fields = [
            'id', 'userId', 'fromUserId', 'notificationType', 'message',
            'video', 'battle', 'isRead', 'createdAt'
        ]
        read_only_fields = ['id', 'created_at']

    def to_representation(self, instance):
        data = super().to_representation(instance)
        data['id'] = str(instance.id)
        if instance.video:
            data['video'] = str(instance.video.id)
        if instance.battle:
            data['battle'] = str(instance.battle.id)
        return data

# VyRaPoints Transaction Serializer
class VyRaPointsTransactionSerializer(serializers.ModelSerializer):
    userId = serializers.CharField(source='user.id', read_only=True)
    transactionType = serializers.CharField(source='transaction_type', read_only=True)
    createdAt = serializers.DateTimeField(source='created_at', read_only=True)

    class Meta:
        model = VyRaPointsTransaction
        fields = ['id', 'userId', 'points', 'transactionType', 'description', 'video', 'battle', 'createdAt']
        read_only_fields = ['id', 'created_at']

    def to_representation(self, instance):
        data = super().to_representation(instance)
        data['id'] = str(instance.id)
        return data

# Club Serializers
class ClubSerializer(serializers.ModelSerializer):
    creatorName = serializers.CharField(source='creator.username', read_only=True)
    memberCount = serializers.IntegerField(source='member_count', read_only=True)
    isPublic = serializers.BooleanField(source='is_public', read_only=True)
    createdAt = serializers.DateTimeField(source='created_at', read_only=True)

    class Meta:
        model = Club
        fields = ['id', 'name', 'description', 'category', 'creator', 'creatorName', 
                  'cover_image', 'memberCount', 'isPublic', 'createdAt']
        read_only_fields = ['id', 'creator', 'member_count', 'created_at']

    def to_representation(self, instance):
        data = super().to_representation(instance)
        data['id'] = str(instance.id)
        return data

class ClubMemberSerializer(serializers.ModelSerializer):
    userName = serializers.CharField(source='user.username', read_only=True)
    joinedAt = serializers.DateTimeField(source='joined_at', read_only=True)

    class Meta:
        model = ClubMember
        fields = ['id', 'club', 'user', 'userName', 'role', 'joinedAt']
        read_only_fields = ['id', 'joined_at']

class ClubPostSerializer(serializers.ModelSerializer):
    video = VideoSerializer(read_only=True)
    postedByName = serializers.CharField(source='posted_by.username', read_only=True)
    createdAt = serializers.DateTimeField(source='created_at', read_only=True)

    class Meta:
        model = ClubPost
        fields = ['id', 'club', 'video', 'posted_by', 'postedByName', 'createdAt']
        read_only_fields = ['id', 'created_at']

    def to_representation(self, instance):
        data = super().to_representation(instance)
        data['id'] = str(instance.id)
        return data

# Challenge Serializers
class ChallengeSerializer(serializers.ModelSerializer):
    challengeType = serializers.CharField(source='challenge_type', read_only=True)
    pointsReward = serializers.IntegerField(source='points_reward', read_only=True)
    isActive = serializers.BooleanField(source='is_active', read_only=True)
    expiresAt = serializers.DateTimeField(source='expires_at', allow_null=True)

    class Meta:
        model = Challenge
        fields = ['id', 'title', 'description', 'challengeType', 'pointsReward', 
                  'frequency', 'isActive', 'expiresAt', 'created_at']
        read_only_fields = ['id', 'created_at']

    def to_representation(self, instance):
        data = super().to_representation(instance)
        data['id'] = str(instance.id)
        return data

class UserChallengeProgressSerializer(serializers.ModelSerializer):
    challenge = ChallengeSerializer(read_only=True)
    completed = serializers.BooleanField(read_only=True)
    claimed = serializers.BooleanField(read_only=True)
    startedAt = serializers.DateTimeField(source='started_at', read_only=True)
    completedAt = serializers.DateTimeField(source='completed_at', allow_null=True)

    class Meta:
        model = UserChallengeProgress
        fields = ['id', 'challenge', 'user', 'progress', 'target', 'completed', 
                  'claimed', 'startedAt', 'completedAt']
        read_only_fields = ['id', 'started_at']

    def to_representation(self, instance):
        data = super().to_representation(instance)
        data['id'] = str(instance.id) if hasattr(instance, 'id') else None
        return data

# Live Room Serializers
class LiveRoomSerializer(serializers.ModelSerializer):
    hostName = serializers.CharField(source='host.username', read_only=True)
    viewerCount = serializers.IntegerField(source='viewer_count', read_only=True)
    startedAt = serializers.DateTimeField(source='started_at', allow_null=True)
    endedAt = serializers.DateTimeField(source='ended_at', allow_null=True)
    createdAt = serializers.DateTimeField(source='created_at', read_only=True)

    class Meta:
        model = LiveRoom
        fields = ['id', 'host', 'hostName', 'title', 'description', 'status', 
                  'viewerCount', 'startedAt', 'endedAt', 'createdAt']
        read_only_fields = ['id', 'viewer_count', 'created_at']

    def to_representation(self, instance):
        data = super().to_representation(instance)
        data['id'] = str(instance.id)
        return data

class LiveBattleSerializer(serializers.ModelSerializer):
    participant1Name = serializers.CharField(source='participant1.username', read_only=True)
    participant2Name = serializers.CharField(source='participant2.username', read_only=True)
    participant1Votes = serializers.IntegerField(source='participant1_votes', read_only=True)
    participant2Votes = serializers.IntegerField(source='participant2_votes', read_only=True)
    startedAt = serializers.DateTimeField(source='started_at', read_only=True)
    endedAt = serializers.DateTimeField(source='ended_at', allow_null=True)

    class Meta:
        model = LiveBattle
        fields = ['id', 'live_room', 'participant1', 'participant1Name', 
                  'participant2', 'participant2Name', 'participant1Votes', 
                  'participant2Votes', 'winner', 'startedAt', 'endedAt']
        read_only_fields = ['id', 'participant1_votes', 'participant2_votes', 'started_at']

    def to_representation(self, instance):
        data = super().to_representation(instance)
        data['id'] = str(instance.id)
        return data

# Sound Serializer
class SoundSerializer(serializers.ModelSerializer):
    audioUrl = serializers.SerializerMethodField()
    coverImage = serializers.SerializerMethodField()
    uploaderName = serializers.CharField(source='uploader.username', read_only=True, allow_null=True)
    usageCount = serializers.IntegerField(source='usage_count', read_only=True)
    createdAt = serializers.DateTimeField(source='created_at', read_only=True)

    class Meta:
        model = Sound
        fields = ['id', 'title', 'artist', 'audioUrl', 'duration', 'coverImage', 
                  'uploader', 'uploaderName', 'usageCount', 'createdAt']
        read_only_fields = ['id', 'usage_count', 'created_at']

    def get_audioUrl(self, obj):
        if obj.audio_url:
            return obj.audio_url
        if obj.audio_file:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.audio_file.url)
            return obj.audio_file.url
        return None

    def get_coverImage(self, obj):
        if obj.cover_image:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.cover_image.url)
            return obj.cover_image.url
        return None

    def to_representation(self, instance):
        data = super().to_representation(instance)
        data['id'] = str(instance.id)
        return data

# Profile Skin Serializers
class ProfileSkinSerializer(serializers.ModelSerializer):
    primaryColor = serializers.CharField(source='primary_color', read_only=True)
    secondaryColor = serializers.CharField(source='secondary_color', read_only=True)
    glowIntensity = serializers.FloatField(source='glow_intensity', read_only=True)
    borderStyle = serializers.CharField(source='border_style', read_only=True)
    costPoints = serializers.IntegerField(source='cost_points', read_only=True)
    isPremium = serializers.BooleanField(source='is_premium', read_only=True)
    previewImage = serializers.SerializerMethodField()
    createdAt = serializers.DateTimeField(source='created_at', read_only=True)

    class Meta:
        model = ProfileSkin
        fields = ['id', 'name', 'description', 'primaryColor', 'secondaryColor', 
                  'glowIntensity', 'borderStyle', 'costPoints', 'isPremium', 
                  'previewImage', 'createdAt']
        read_only_fields = ['id', 'created_at']

    def get_previewImage(self, obj):
        if obj.preview_image:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.preview_image.url)
            return obj.preview_image.url
        return None

    def to_representation(self, instance):
        data = super().to_representation(instance)
        data['id'] = str(instance.id)
        return data

class UserSkinSerializer(serializers.ModelSerializer):
    skin = ProfileSkinSerializer(read_only=True)
    purchasedAt = serializers.DateTimeField(source='purchased_at', read_only=True)
    isActive = serializers.BooleanField(read_only=True)

    class Meta:
        model = UserSkin
        fields = ['id', 'user', 'skin', 'purchasedAt', 'isActive']
        read_only_fields = ['id', 'purchased_at']

    def to_representation(self, instance):
        data = super().to_representation(instance)
        data['id'] = str(instance.id) if hasattr(instance, 'id') else None
        return data

# Block Serializer
class BlockSerializer(serializers.ModelSerializer):
    blockerName = serializers.CharField(source='blocker.username', read_only=True)
    blockedName = serializers.CharField(source='blocked.username', read_only=True)
    createdAt = serializers.DateTimeField(source='created_at', read_only=True)

    class Meta:
        model = Block
        fields = ['id', 'blocker', 'blockerName', 'blocked', 'blockedName', 'createdAt']
        read_only_fields = ['id', 'created_at']

    def to_representation(self, instance):
        data = super().to_representation(instance)
        data['id'] = str(instance.id) if hasattr(instance, 'id') else None
        return data

# Video Analytics Serializer
class VideoAnalyticsSerializer(serializers.ModelSerializer):
    totalViews = serializers.IntegerField(source='total_views', read_only=True)
    viewsPerDay = serializers.JSONField(source='views_per_day', read_only=True)
    engagementRate = serializers.FloatField(source='engagement_rate', read_only=True)
    peakViewTime = serializers.TimeField(source='peak_view_time', allow_null=True)
    topHashtags = serializers.JSONField(source='top_hashtags', read_only=True)
    createdAt = serializers.DateTimeField(source='created_at', read_only=True)
    updatedAt = serializers.DateTimeField(source='updated_at', read_only=True)

    class Meta:
        model = VideoAnalytics
        fields = ['id', 'video', 'totalViews', 'viewsPerDay', 'engagementRate', 
                  'peakViewTime', 'topHashtags', 'demographics', 'createdAt', 'updatedAt']
        read_only_fields = ['id', 'created_at', 'updated_at']

    def to_representation(self, instance):
        data = super().to_representation(instance)
        data['id'] = str(instance.id) if hasattr(instance, 'id') else None
        return data

# Chat Serializers
class ChatMessageSerializer(serializers.ModelSerializer):
    sender_username = serializers.CharField(source='sender.username', read_only=True)
    sender_id = serializers.CharField(source='sender.id', read_only=True)
    createdAt = serializers.DateTimeField(source='created_at', read_only=True)
    isRead = serializers.BooleanField(source='is_read', read_only=True)

    class Meta:
        model = ChatMessage
        fields = ['id', 'sender_id', 'sender_username', 'message', 'isRead', 'createdAt']
        read_only_fields = ['id', 'created_at']

    def to_representation(self, instance):
        data = super().to_representation(instance)
        data['id'] = str(instance.id)
        data['senderId'] = data.pop('sender_id')
        data['senderName'] = data.pop('sender_username')
        return data

class ChatSerializer(serializers.ModelSerializer):
    participants_data = serializers.SerializerMethodField()
    last_message = serializers.SerializerMethodField()
    unread_count = serializers.SerializerMethodField()
    createdAt = serializers.DateTimeField(source='created_at', read_only=True)
    updatedAt = serializers.DateTimeField(source='updated_at', read_only=True)

    class Meta:
        model = Chat
        fields = ['id', 'participants_data', 'last_message', 'unread_count', 'createdAt', 'updatedAt']
        read_only_fields = ['id', 'created_at', 'updated_at']

    def get_participants_data(self, obj):
        """Get participant info excluding current user"""
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            participants = obj.participants.exclude(id=request.user.id)
            return [{
                'id': str(p.id),
                'username': p.username,
                'displayName': p.profile.display_name if hasattr(p, 'profile') else p.username,
            } for p in participants]
        return []

    def get_last_message(self, obj):
        """Get the last message in the chat"""
        last_msg = obj.messages.order_by('-created_at').first()
        if last_msg:
            return {
                'id': str(last_msg.id),
                'message': last_msg.message,
                'senderId': str(last_msg.sender.id),
                'senderName': last_msg.sender.username,
                'createdAt': last_msg.created_at.isoformat(),
            }
        return None

    def get_unread_count(self, obj):
        """Get unread message count for current user"""
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return obj.messages.exclude(sender=request.user).filter(is_read=False).count()
        return 0

    def to_representation(self, instance):
        data = super().to_representation(instance)
        data['id'] = str(instance.id)
        return data

# Enhanced Status Serializer (Stories 2.0)
class StatusSerializer(serializers.ModelSerializer):
    expiresAt = serializers.DateTimeField(source='expires_at', read_only=True)
    viewsCount = serializers.IntegerField(source='views_count', read_only=True)
    pollQuestion = serializers.CharField(source='poll_question', allow_null=True)
    pollOptions = serializers.JSONField(source='poll_options', read_only=True)
    musicUrl = serializers.URLField(allow_null=True)
    countdownTimer = serializers.DateTimeField(source='countdown_timer', allow_null=True)
    askMeAnything = serializers.BooleanField(source='ask_me_anything', read_only=True)
    createdAt = serializers.DateTimeField(source='created_at', read_only=True)

    class Meta:
        model = Status
        fields = ['id', 'user', 'image', 'video', 'caption', 'expiresAt', 
                  'viewsCount', 'stickers', 'pollQuestion', 'pollOptions', 
                  'musicUrl', 'countdownTimer', 'askMeAnything', 'createdAt']
        read_only_fields = ['id', 'views_count', 'created_at']

    def to_representation(self, instance):
        data = super().to_representation(instance)
        data['id'] = str(instance.id)
        return data

