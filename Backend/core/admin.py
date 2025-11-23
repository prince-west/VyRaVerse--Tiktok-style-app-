from django.contrib import admin
from .models import (
    Profile, Badge, Video, Hashtag, Like, Comment, Share, Buzz,
    Follow, Product, Battle, BattleVote, Notification, VyRaPointsTransaction,
    Post, LikePost, FollowersCount  # Legacy models
)

# Register your models here.
@admin.register(Profile)
class ProfileAdmin(admin.ModelAdmin):
    list_display = ['user', 'display_name', 'vyra_points', 'is_verified', 'created_at']
    search_fields = ['user__username', 'display_name']
    list_filter = ['is_verified', 'created_at']

@admin.register(Video)
class VideoAdmin(admin.ModelAdmin):
    list_display = ['username', 'description', 'likes', 'buzz_count', 'privacy', 'created_at']
    search_fields = ['username', 'description']
    list_filter = ['privacy', 'created_at']

@admin.register(Product)
class ProductAdmin(admin.ModelAdmin):
    list_display = ['name', 'seller_name', 'price', 'is_promoted', 'created_at']
    search_fields = ['name', 'seller_name']
    list_filter = ['is_promoted', 'created_at']

@admin.register(Battle)
class BattleAdmin(admin.ModelAdmin):
    list_display = ['creator', 'challenger', 'status', 'original_votes', 'challenger_votes', 'created_at']
    search_fields = ['creator__username', 'challenger__username']
    list_filter = ['status', 'created_at']

@admin.register(Comment)
class CommentAdmin(admin.ModelAdmin):
    list_display = ['username', 'text', 'likes', 'created_at']
    search_fields = ['username', 'text']

@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ['user', 'notification_type', 'is_read', 'created_at']
    list_filter = ['notification_type', 'is_read', 'created_at']

admin.site.register(Badge)
admin.site.register(Hashtag)
admin.site.register(Like)
admin.site.register(Share)
admin.site.register(Buzz)
admin.site.register(Follow)
admin.site.register(BattleVote)
admin.site.register(VyRaPointsTransaction)

# Legacy models
admin.site.register(Post)
admin.site.register(LikePost)
admin.site.register(FollowersCount)


# This is to see the profile and the rest in the admin panel