VyRaVerse - Social Media Platform

VyRaVerse is a comprehensive social media platform that combines video-sharing, social networking, e-commerce, and gamification features into a unified mobile and web application. The platform is built with modern technologies and follows industry best practices for scalability, security, and user experience.

OVERVIEW

VyRaVerse serves as a creative social universe where users can create, share, and discover video content while engaging with a community through various interactive features. The platform integrates video-first content creation similar to TikTok, social networking capabilities like Instagram, and ephemeral content features inspired by Snapchat.

Tagline: Your Creative Social Universe

TECHNOLOGY STACK

Backend
- Framework: Django 5.2.1 with Django REST Framework 3.15.1
- Language: Python 3.x
- Database: SQLite (development), PostgreSQL-ready (production)
- Authentication: Token-based authentication using Django REST Framework tokens
- API Architecture: RESTful API with ViewSets and Serializers
- CORS: django-cors-headers for cross-origin resource sharing
- Image Processing: Pillow for image handling
- Configuration: python-decouple for environment variable management

Frontend
- Framework: Flutter 3.0+ (Dart)
- Platform Support: iOS, Android, Web
- State Management: Provider pattern with setState
- Video Playback: video_player and chewie packages
- Image Handling: image_picker, cached_network_image
- Networking: http package with custom ApiService
- Local Storage: shared_preferences, Hive
- UI Components: Custom widgets with Material Design
- Animations: flutter_animate package
- Charts: fl_chart for analytics
- Location: geolocator for location-based features
- Camera: camera package for video recording
- Deep Linking: url_launcher for external app integration

CORE FEATURES

Authentication and User Management
- User registration with username, email, and password
- Secure token-based authentication
- User profiles with customizable display names, bios, and profile images
- Profile verification system
- Follow/unfollow functionality
- Follower and following lists
- User search and discovery
- Suggested users feature

Video Content System
- Video upload from gallery or camera
- Advanced camera interface with:
  - Front and rear camera switching
  - Video recording with timer
  - Photo capture capability
  - Flash controls (auto/on/off)
  - Zoom functionality
  - Multiple filter categories (Beauty, Vintage, Artistic, Fun)
  - AR effects and stickers
  - Beauty mode with intensity control
  - Background and time effects
- Vertical video feed with auto-play
- Custom video player with play/pause, volume control, and progress tracking
- Video metadata including descriptions, hashtags, location tagging
- Privacy settings (Public, Friends, Private)
- Content controls (allow/disable comments, duet, stitch)
- Video interactions: Like, Buzz (premium engagement), Comment, Share, Save
- Content reporting system
- Duet and Stitch video creation features

Social Features
- Real-time chat messaging system
- Direct messaging with read receipts
- Status updates (story-like ephemeral content)
- Notifications for likes, comments, follows, buzz, battles, and mentions
- Hashtag system with trending tracking
- User search by username or display name
- Video search by description or hashtags
- Trending videos and hashtags display

Gamification System
- VyRa Points reward system
- Points earned through:
  - Video uploads (10 points)
  - Liking videos (1 point)
  - Commenting (2 points)
  - Buzzing videos (3 points)
  - Sharing videos (1 point)
  - Voting in battles (1 point)
  - New user bonus (100 points)
- Points transaction history
- Weekly leaderboard showing top point earners
- Achievement badges system
- Boost feature to increase video visibility using points

E-commerce Integration (VyRa Mart)
- Product listings with images, descriptions, and pricing
- Business profiles for sellers
- Product view tracking
- Purchase tracking system
- Promoted products feature
- Product search functionality
- Business analytics and advertising tools

Community Features
- VyRa Battles: Side-by-side video competitions with voting
- Challenges: User-created challenges
- Clubs: Community groups for users
- Leaderboard: Rankings based on VyRa Points
- Universe Map: Location-based video discovery on an interactive map

ARCHITECTURE

Backend Architecture

The backend is built using Django REST Framework following a modular structure:

Models (Backend/core/models.py)
- Profile: User profiles with stats, bio, images, verification status
- Video: Video content with metadata, privacy settings, engagement metrics
- Like, Comment, Share, Buzz: Engagement tracking models
- Follow: User relationship tracking
- Hashtag: Hashtag system with usage counts
- Product: E-commerce product listings
- Business: Seller business profiles
- Battle and BattleVote: Video battle competition system
- Notification: User notification system
- VyRaPointsTransaction: Points transaction history
- Chat and ChatMessage: Messaging system
- Status and StatusView: Ephemeral content system
- ReferralCode and Referral: Referral program
- Badge: Achievement system
- Challenge: User challenges
- Club: Community groups
- Sound: Audio library for videos

API Views (Backend/core/api_views.py)
- ProfileViewSet: User profile management, follow/unfollow, search
- VideoViewSet: Video CRUD operations, engagement actions (like, buzz, comment, share)
- ProductViewSet: Product management and e-commerce operations
- BattleViewSet: Battle creation and voting
- ChatViewSet: Chat conversation management
- ChatMessageViewSet: Message sending and retrieval
- NotificationViewSet: Notification management
- And more specialized viewsets for other features

API Endpoints
- Authentication: /api/auth/signup/, /api/auth/signin/
- Profiles: /api/profiles/, /api/profiles/{id}/follow/, /api/profiles/{id}/unfollow/
- Videos: /api/videos/, /api/videos/{id}/like/, /api/videos/{id}/buzz/, /api/videos/{id}/comments/
- Products: /api/products/, /api/products/{id}/view/, /api/products/{id}/purchase/
- Battles: /api/battles/, /api/battles/{id}/vote/
- Chats: /api/chats/, /api/chats/{id}/messages/
- Notifications: /api/notifications/
- And many more endpoints for comprehensive functionality

Frontend Architecture

The frontend follows Flutter best practices with a clean architecture:

Screens (Frontend/lib/screens/)
- home_feed_screen.dart: Main video feed with vertical scrolling
- profile_screen.dart: User profile display and editing
- search_screen.dart: Search for videos, users, and hashtags
- upload_screen.dart: Video upload interface with camera/gallery options
- chat_screen.dart: Messaging and status updates
- business_page_screen.dart: Business profile and product management
- vyra_mart_screen.dart: E-commerce marketplace
- battles_screen.dart: Video battle interface
- leaderboard_screen.dart: Points leaderboard
- universe_map_screen.dart: Location-based video discovery
- clubs_screen.dart: Community groups
- challenges_screen.dart: User challenges
- notifications_screen.dart: Notification center
- settings_screen.dart: App settings
- And more specialized screens

Services (Frontend/lib/services/)
- api_service.dart: Centralized API communication with error handling, retry logic, and timeout management
- Handles both JSON and multipart/form-data requests
- Supports file uploads for images and videos
- Implements token-based authentication
- Provides methods for all backend endpoints

Models (Frontend/lib/models/)
- user_profile.dart: User profile data structure
- video_item.dart: Video content data structure
- product_item.dart: Product data structure
- And other domain models matching backend serializers

Widgets (Frontend/lib/widgets/)
- Custom reusable UI components
- Neon-themed design system
- Video player widgets
- Profile widgets
- And more specialized widgets

Controllers (Frontend/lib/controllers/)
- video_feed_controller.dart: Video feed state management
- video_player_controller_manager.dart: Video playback management
- video_upload_controller.dart: Upload process management

API Service Features

The ApiService class provides:
- Automatic token management
- Request timeout handling (configurable)
- Retry logic for failed requests
- Comprehensive error handling with custom exceptions
- Support for both web and mobile platforms
- File upload support for images and videos
- Pagination handling
- Response parsing for both paginated and direct responses

SECURITY FEATURES

- Token-based authentication for API access
- Secure password storage (Django's built-in hashing)
- CORS configuration for cross-origin requests
- Input validation on both frontend and backend
- Content reporting system for moderation
- Privacy settings for videos and profiles
- Secure file upload handling

USER EXPERIENCE FEATURES

- Smooth animations and transitions
- Loading states for async operations
- Error handling with user-friendly messages
- Empty states with helpful guidance
- Responsive design for various screen sizes
- Dark theme with neon accent colors
- Intuitive navigation with bottom tab bar
- Real-time updates for notifications and messages
- Offline capability considerations (local storage)

DEPLOYMENT READINESS

The application is structured for production deployment:

Backend
- Environment variable configuration support
- Debug mode toggle via environment variables
- Allowed hosts configuration
- Static files and media handling
- Database migration system
- API documentation ready

Frontend
- Web platform support
- iOS and Android build configurations
- Asset management
- Environment configuration
- Error tracking ready (debug logging in place)
- Performance optimizations (caching, lazy loading)

DEVELOPMENT STATUS

The application has been developed with a focus on:
- Core functionality implementation
- API integration and error handling
- User interface polish and responsiveness
- Cross-platform compatibility
- Production-ready code structure

All major features are implemented and functional, with the codebase structured for easy maintenance and future enhancements.

PROJECT STRUCTURE

VyRaVerse/
├── Backend/
│   ├── core/                 # Main Django app
│   │   ├── models.py         # Database models
│   │   ├── api_views.py      # API viewset implementations
│   │   ├── serializers.py    # API serializers
│   │   ├── api_urls.py       # API URL routing
│   │   └── migrations/       # Database migrations
│   ├── VyRa/                 # Django project settings
│   │   ├── settings.py       # Django configuration
│   │   ├── urls.py           # Main URL configuration
│   │   └── wsgi.py           # WSGI configuration
│   ├── media/                # User-uploaded media files
│   ├── static/               # Static files
│   ├── requirements.txt      # Python dependencies
│   └── manage.py             # Django management script
│
└── Frontend/
    ├── lib/
    │   ├── main.dart         # App entry point
    │   ├── screens/          # Screen widgets
    │   ├── services/         # Business logic services
    │   ├── models/           # Data models
    │   ├── widgets/          # Reusable UI components
    │   ├── controllers/      # State management
    │   ├── config/           # Configuration files
    │   └── theme/            # Theme definitions
    ├── assets/               # Images, sounds, animations
    ├── android/              # Android-specific files
    ├── ios/                  # iOS-specific files
    ├── web/                  # Web-specific files
    ├── pubspec.yaml          # Flutter dependencies
    └── README.md             # Frontend documentation

KEY ACHIEVEMENTS

- Full-stack social media platform from scratch
- RESTful API design with comprehensive endpoints
- Cross-platform mobile and web application
- Real-time features (chat, notifications)
- E-commerce integration
- Gamification system
- Location-based features
- Advanced video handling and playback
- Professional UI/UX design
- Scalable architecture

This project demonstrates proficiency in:
- Full-stack development (Django + Flutter)
- RESTful API design and implementation
- Mobile app development (iOS, Android, Web)
- Database design and modeling
- Authentication and authorization
- File upload and media handling
- Real-time features
- State management
- UI/UX design and implementation
- Error handling and edge cases
- Production-ready code practices

