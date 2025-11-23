import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/vyra_theme.dart';
import '../widgets/neon_appbar.dart';
import '../models/challenge.dart';
import '../services/api_service.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  final ApiService _apiService = ApiService();
  List<Challenge> _challenges = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChallenges();
  }

  Future<void> _loadChallenges() async {
    setState(() => _isLoading = true);
    try {
      final challenges = await _apiService.getChallenges();
      if (mounted) {
        setState(() {
          _challenges = challenges;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load challenges'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _claimChallenge(String challengeId) async {
    try {
      final result = await _apiService.claimChallenge(challengeId);
      if (mounted) {
        if (result['claimed'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Earned ${result['points']} VyRa Points!'),
              backgroundColor: VyRaTheme.primaryCyan,
            ),
          );
          _loadChallenges();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Cannot claim challenge'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VyRaTheme.primaryBlack,
      appBar: const NeonAppBar(title: 'Challenges & Missions'),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: VyRaTheme.primaryCyan),
            )
          : _challenges.isEmpty
              ? Center(
                  child: Text(
                    'No active challenges',
                    style: const TextStyle(color: VyRaTheme.textGrey, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _challenges.length,
                  itemBuilder: (context, index) {
                    return _buildChallengeCard(_challenges[index]);
                  },
                ),
    );
  }

  Widget _buildChallengeCard(Challenge challenge) {
    IconData icon;
    Color iconColor;
    switch (challenge.challengeType) {
      case 'upload':
        icon = Icons.video_library;
        iconColor = VyRaTheme.primaryCyan;
        break;
      case 'buzz':
        icon = Icons.local_fire_department;
        iconColor = const Color(0xFFFF6B35);
        break;
      case 'battle':
        icon = Icons.sports_mma;
        iconColor = Colors.purple;
        break;
      default:
        icon = Icons.stars;
        iconColor = const Color(0xFFFFD700);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: VyRaTheme.darkGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: VyRaTheme.primaryCyan.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge.title,
                      style: const TextStyle(
                        color: VyRaTheme.textWhite,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      challenge.description,
                      style: const TextStyle(
                        color: VyRaTheme.textGrey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.stars, color: const Color(0xFFFFD700), size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '${challenge.pointsReward} Points',
                    style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () => _claimChallenge(challenge.id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: VyRaTheme.primaryCyan,
                  foregroundColor: VyRaTheme.primaryBlack,
                ),
                child: const Text('Claim'),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0, duration: 300.ms);
  }
}

