from django.db import models
from django.contrib.auth import get_user_model
import uuid
from datetime import datetime

User = get_user_model()

# User Profile Model - matches Flutter UserProfile
class Profile(models.Model):
    PRIVACY_CHOICES = [
        ('Public', 'Public'),
        ('Friends', 'Friends'),
        ('Private', 'Private'),
    ]
    
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='profile')
    id_user = models.IntegerField(unique=True)
    display_name = models.CharField(max_length=100, blank=True)
    bio = models.TextField(blank=True)
    profile_image = models.ImageField(upload_to='profile_images/', default='default/Westt.gif', null=True, blank=True)
    # Legacy field for backward compatibility
    Profileimg = models.ImageField(upload_to='profile_images/', default='default/Westt.gif', null=True, blank=True)
    location = models.CharField(max_length=100, blank=True)
    total_likes = models.IntegerField(default=0)
    total_buzz = models.IntegerField(default=0)
    vyra_points = models.IntegerField(default=0)
    upload_count = models.IntegerField(default=0)
    is_verified = models.BooleanField(default=False)
    theme_accent = models.CharField(max_length=50, default='Black-Cyan', blank=True)
    created_at = models.DateTimeField(auto_now_add=True, null=True, blank=True)
    updated_at = models.DateTimeField(auto_now=True, null=True, blank=True)

    def __str__(self):
        return self.user.username

    @property
    def username(self):
        return self.user.username

# Badge Model
class Badge(models.Model):
    profile = models.ForeignKey(Profile, on_delete=models.CASCADE, related_name='badges')
    name = models.CharField(max_length=100)
    description = models.TextField(blank=True)
    icon = models.CharField(max_length=100, blank=True)
    earned_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.profile.user.username} - {self.name}"

# Video Model - matches Flutter VideoItem
class Video(models.Model):
    PRIVACY_CHOICES = [
        ('Public', 'Public'),
        ('Friends', 'Friends'),
        ('Private', 'Private'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='videos')
    username = models.CharField(max_length=100)  # Denormalized for performance
    description = models.TextField()
    video_file = models.FileField(upload_to='videos/', null=True, blank=True)
    video_url = models.URLField(blank=True, null=True)
    thumbnail_url = models.URLField(blank=True, null=True)
    is_local = models.BooleanField(default=True)
    likes = models.IntegerField(default=0)
    comments_count = models.IntegerField(default=0)
    shares = models.IntegerField(default=0)
    buzz_count = models.IntegerField(default=0)
    privacy = models.CharField(max_length=20, choices=PRIVACY_CHOICES, default='Public')
    location = models.CharField(max_length=100, blank=True, null=True)
    latitude = models.FloatField(null=True, blank=True)  # For Universe Map
    longitude = models.FloatField(null=True, blank=True)  # For Universe Map
    allow_comments = models.BooleanField(default=True)
    allow_duet = models.BooleanField(default=True)
    allow_stitch = models.BooleanField(default=True)
    boost_score = models.IntegerField(default=0)  # For Creator Boost Mode
    collab_type = models.CharField(max_length=20, choices=[
        ('none', 'None'),
        ('split', 'Split Screen'),
        ('reaction', 'Reaction'),
        ('voiceover', 'Voice Over'),
    ], default='none')  # For VyRa Collabs
    sensitive_flag = models.BooleanField(default=False)  # For Safe Mode
    sound = models.ForeignKey('Sound', on_delete=models.SET_NULL, null=True, blank=True, related_name='videos')  # For Sounds Library
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.username} - {self.description[:50]}"

# Hashtag Model
class Hashtag(models.Model):
    name = models.CharField(max_length=100, unique=True)
    videos = models.ManyToManyField(Video, related_name='hashtags', blank=True)
    usage_count = models.IntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"#{self.name}"

# Like Model
class Like(models.Model):
    video = models.ForeignKey(Video, on_delete=models.CASCADE, related_name='likes_rel')
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='likes')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('video', 'user')

    def __str__(self):
        return f"{self.user.username} liked {self.video.id}"

# Comment Model
class Comment(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    video = models.ForeignKey(Video, on_delete=models.CASCADE, related_name='comments_rel')
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='comments')
    username = models.CharField(max_length=100)  # Denormalized
    text = models.TextField()
    likes = models.IntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.username}: {self.text[:50]}"

# Share Model
class Share(models.Model):
    video = models.ForeignKey(Video, on_delete=models.CASCADE, related_name='shares_rel')
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='shares')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('video', 'user')

    def __str__(self):
        return f"{self.user.username} shared {self.video.id}"

# Buzz Model (VyRaChallenge engagement)
class Buzz(models.Model):
    video = models.ForeignKey(Video, on_delete=models.CASCADE, related_name='buzzes')
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='buzzes')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('video', 'user')

    def __str__(self):
        return f"{self.user.username} buzzed {self.video.id}"

# Follow Model
class Follow(models.Model):
    follower = models.ForeignKey(User, on_delete=models.CASCADE, related_name='following')
    following = models.ForeignKey(User, on_delete=models.CASCADE, related_name='followers')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('follower', 'following')

    def __str__(self):
        return f"{self.follower.username} follows {self.following.username}"

# Product Model - matches Flutter ProductItem (VyRaMart)
class Product(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    seller = models.ForeignKey(User, on_delete=models.CASCADE, related_name='products')
    seller_name = models.CharField(max_length=100)  # Denormalized
    name = models.CharField(max_length=200)
    description = models.TextField()
    price = models.DecimalField(max_digits=10, decimal_places=2)
    image_url = models.URLField(blank=True, null=True)
    video_url = models.URLField(blank=True, null=True)
    views = models.IntegerField(default=0)
    purchases = models.IntegerField(default=0)
    is_promoted = models.BooleanField(default=False)
    boost_score = models.IntegerField(default=0)  # For VyRa Mart Boost Tools
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.name

# VyRaBattle Model
class Battle(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    original_video = models.ForeignKey(Video, on_delete=models.CASCADE, related_name='battles_as_original')
    challenger_video = models.ForeignKey(Video, on_delete=models.CASCADE, related_name='battles_as_challenger')
    creator = models.ForeignKey(User, on_delete=models.CASCADE, related_name='created_battles')
    challenger = models.ForeignKey(User, on_delete=models.CASCADE, related_name='challenged_battles')
    original_votes = models.IntegerField(default=0)
    challenger_votes = models.IntegerField(default=0)
    status = models.CharField(max_length=20, choices=[
        ('active', 'Active'),
        ('completed', 'Completed'),
        ('cancelled', 'Cancelled'),
    ], default='active')
    winner = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='won_battles')
    created_at = models.DateTimeField(auto_now_add=True)
    ends_at = models.DateTimeField(null=True, blank=True)

    def __str__(self):
        return f"Battle: {self.creator.username} vs {self.challenger.username}"

# Battle Vote Model
class BattleVote(models.Model):
    battle = models.ForeignKey(Battle, on_delete=models.CASCADE, related_name='votes')
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='battle_votes')
    voted_for = models.ForeignKey(User, on_delete=models.CASCADE, related_name='received_votes')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('battle', 'user')

    def __str__(self):
        return f"{self.user.username} voted for {self.voted_for.username}"

# Notification Model
class Notification(models.Model):
    NOTIFICATION_TYPES = [
        ('like', 'Like'),
        ('comment', 'Comment'),
        ('follow', 'Follow'),
        ('buzz', 'Buzz'),
        ('battle', 'Battle'),
        ('mention', 'Mention'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='notifications')
    from_user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='sent_notifications', null=True, blank=True)
    notification_type = models.CharField(max_length=20, choices=NOTIFICATION_TYPES)
    message = models.TextField()
    video = models.ForeignKey(Video, on_delete=models.CASCADE, null=True, blank=True, related_name='notifications')
    battle = models.ForeignKey(Battle, on_delete=models.CASCADE, null=True, blank=True, related_name='notifications')
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user.username} - {self.notification_type}"

# VyRaPoints Transaction Model
class VyRaPointsTransaction(models.Model):
    TRANSACTION_TYPES = [
        ('earned', 'Earned'),
        ('spent', 'Spent'),
        ('reward', 'Reward'),
        ('penalty', 'Penalty'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='vyra_points_transactions')
    points = models.IntegerField()
    transaction_type = models.CharField(max_length=20, choices=TRANSACTION_TYPES)
    description = models.TextField(blank=True)
    video = models.ForeignKey(Video, on_delete=models.SET_NULL, null=True, blank=True)
    battle = models.ForeignKey(Battle, on_delete=models.SET_NULL, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user.username} - {self.transaction_type} - {self.points} points"

# Chat Model
class Chat(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    participants = models.ManyToManyField(User, related_name='chats')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Chat: {', '.join([p.username for p in self.participants.all()])}"

# Chat Message Model
class ChatMessage(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    chat = models.ForeignKey(Chat, on_delete=models.CASCADE, related_name='messages')
    sender = models.ForeignKey(User, on_delete=models.CASCADE, related_name='sent_messages')
    message = models.TextField()
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.sender.username}: {self.message[:50]}"

# Status Model (Stories) - Enhanced for Stories 2.0
class Status(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='statuses')
    image = models.ImageField(upload_to='statuses/', null=True, blank=True)
    video = models.FileField(upload_to='statuses/', null=True, blank=True)
    caption = models.TextField(blank=True)
    expires_at = models.DateTimeField()
    views_count = models.IntegerField(default=0)
    # Stories 2.0 enhancements
    stickers = models.JSONField(default=list, blank=True)  # Sticker data
    poll_question = models.TextField(blank=True, null=True)
    poll_options = models.JSONField(default=list, blank=True)  # [{'text': '...', 'votes': 0}]
    music_url = models.URLField(blank=True, null=True)
    countdown_timer = models.DateTimeField(null=True, blank=True)
    ask_me_anything = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user.username}'s status"

# Status View Model
class StatusView(models.Model):
    status = models.ForeignKey(Status, on_delete=models.CASCADE, related_name='views')
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='viewed_statuses')
    viewed_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('status', 'user')

    def __str__(self):
        return f"{self.user.username} viewed {self.status.id}"

# Referral Code Model
class ReferralCode(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='referral_code')
    code = models.CharField(max_length=20, unique=True)
    uses_count = models.IntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user.username}: {self.code}"

# Referral Model
class Referral(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    referrer = models.ForeignKey(User, on_delete=models.CASCADE, related_name='referrals_sent')
    referred = models.ForeignKey(User, on_delete=models.CASCADE, related_name='referrals_received')
    code = models.ForeignKey(ReferralCode, on_delete=models.CASCADE, related_name='referrals')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('referrer', 'referred')

    def __str__(self):
        return f"{self.referrer.username} referred {self.referred.username}"

# Legacy models for backward compatibility
class Post(models.Model):
    """Legacy model - kept for backward compatibility"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4)
    user = models.CharField(max_length=100)
    image = models.ImageField(upload_to='post_images')
    caption = models.TextField()
    created_at = models.DateTimeField(default=datetime.now)
    no_of_likes = models.IntegerField(default=0)

    def __str__(self):
        return self.user

class LikePost(models.Model):
    """Legacy model - kept for backward compatibility"""
    post_id = models.CharField(max_length=500)
    username = models.CharField(max_length=100)

    def __str__(self):
        return self.username

class FollowersCount(models.Model):
    """Legacy model - kept for backward compatibility"""
    follower = models.CharField(max_length=100)
    user = models.CharField(max_length=100)

    def __str__(self):
        return self.user

# VyRa Clubs Models
class Club(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=100)
    description = models.TextField()
    category = models.CharField(max_length=50)  # Music, Tech, Fashion, Dance, etc.
    creator = models.ForeignKey(User, on_delete=models.CASCADE, related_name='created_clubs')
    cover_image = models.ImageField(upload_to='club_covers/', null=True, blank=True)
    member_count = models.IntegerField(default=0)
    is_public = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.name

class ClubMember(models.Model):
    ROLE_CHOICES = [
        ('member', 'Member'),
        ('moderator', 'Moderator'),
        ('admin', 'Admin'),
    ]
    club = models.ForeignKey(Club, on_delete=models.CASCADE, related_name='members')
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='club_memberships')
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='member')
    joined_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('club', 'user')

    def __str__(self):
        return f"{self.user.username} - {self.club.name}"

class ClubPost(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    club = models.ForeignKey(Club, on_delete=models.CASCADE, related_name='posts')
    video = models.ForeignKey(Video, on_delete=models.CASCADE, related_name='club_posts')
    posted_by = models.ForeignKey(User, on_delete=models.CASCADE, related_name='club_posts')
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.club.name} - {self.video.id}"

# Challenges & Missions
class Challenge(models.Model):
    FREQUENCY_CHOICES = [
        ('daily', 'Daily'),
        ('weekly', 'Weekly'),
        ('monthly', 'Monthly'),
    ]
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    title = models.CharField(max_length=200)
    description = models.TextField()
    challenge_type = models.CharField(max_length=50)  # upload, buzz, battle, etc.
    points_reward = models.IntegerField()
    frequency = models.CharField(max_length=20, choices=FREQUENCY_CHOICES, default='daily')
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField(null=True, blank=True)

    def __str__(self):
        return self.title

class UserChallengeProgress(models.Model):
    challenge = models.ForeignKey(Challenge, on_delete=models.CASCADE, related_name='user_progress')
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='challenge_progress')
    progress = models.IntegerField(default=0)
    target = models.IntegerField(default=1)
    completed = models.BooleanField(default=False)
    claimed = models.BooleanField(default=False)
    started_at = models.DateTimeField(auto_now_add=True)
    completed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        unique_together = ('challenge', 'user')

    def __str__(self):
        return f"{self.user.username} - {self.challenge.title}"

# Live Rooms
class LiveRoom(models.Model):
    STATUS_CHOICES = [
        ('scheduled', 'Scheduled'),
        ('live', 'Live'),
        ('ended', 'Ended'),
    ]
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    host = models.ForeignKey(User, on_delete=models.CASCADE, related_name='live_rooms')
    title = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='scheduled')
    viewer_count = models.IntegerField(default=0)
    started_at = models.DateTimeField(null=True, blank=True)
    ended_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.host.username} - {self.title}"

class LiveBattle(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    live_room = models.ForeignKey(LiveRoom, on_delete=models.CASCADE, related_name='battles')
    participant1 = models.ForeignKey(User, on_delete=models.CASCADE, related_name='live_battles_p1')
    participant2 = models.ForeignKey(User, on_delete=models.CASCADE, related_name='live_battles_p2')
    participant1_votes = models.IntegerField(default=0)
    participant2_votes = models.IntegerField(default=0)
    winner = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='won_live_battles')
    started_at = models.DateTimeField(auto_now_add=True)
    ended_at = models.DateTimeField(null=True, blank=True)

    def __str__(self):
        return f"Live Battle: {self.participant1.username} vs {self.participant2.username}"

# Sound Library
class Sound(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    title = models.CharField(max_length=200)
    artist = models.CharField(max_length=200, blank=True)
    audio_file = models.FileField(upload_to='sounds/', null=True, blank=True)
    audio_url = models.URLField(blank=True, null=True)
    duration = models.IntegerField(default=0)  # in seconds
    cover_image = models.ImageField(upload_to='sound_covers/', null=True, blank=True)
    uploader = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='uploaded_sounds')
    usage_count = models.IntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.title

# Profile Skins
class ProfileSkin(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=100)
    description = models.TextField(blank=True)
    primary_color = models.CharField(max_length=7)  # Hex color
    secondary_color = models.CharField(max_length=7)
    glow_intensity = models.FloatField(default=1.0)
    border_style = models.CharField(max_length=50, default='solid')
    cost_points = models.IntegerField(default=0)
    is_premium = models.BooleanField(default=False)
    preview_image = models.ImageField(upload_to='skin_previews/', null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.name

class UserSkin(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='owned_skins')
    skin = models.ForeignKey(ProfileSkin, on_delete=models.CASCADE, related_name='owners')
    purchased_at = models.DateTimeField(auto_now_add=True)
    is_active = models.BooleanField(default=False)

    class Meta:
        unique_together = ('user', 'skin')

    def __str__(self):
        return f"{self.user.username} - {self.skin.name}"

# Blocking & Restriction
class Block(models.Model):
    blocker = models.ForeignKey(User, on_delete=models.CASCADE, related_name='blocked_users')
    blocked = models.ForeignKey(User, on_delete=models.CASCADE, related_name='blocked_by')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('blocker', 'blocked')

    def __str__(self):
        return f"{self.blocker.username} blocked {self.blocked.username}"

# Video Analytics
class VideoAnalytics(models.Model):
    video = models.OneToOneField(Video, on_delete=models.CASCADE, related_name='analytics')
    total_views = models.IntegerField(default=0)
    views_per_day = models.JSONField(default=dict)  # {'2024-01-01': 100, ...}
    engagement_rate = models.FloatField(default=0.0)
    peak_view_time = models.TimeField(null=True, blank=True)
    top_hashtags = models.JSONField(default=list)
    demographics = models.JSONField(default=dict)  # Age, location breakdown
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Analytics for {self.video.id}"
