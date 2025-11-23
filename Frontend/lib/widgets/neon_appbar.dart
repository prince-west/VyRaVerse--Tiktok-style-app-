import 'package:flutter/material.dart';
import '../theme/vyra_theme.dart';

class NeonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showNotifications;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onAddFriendTap;
  final VoidCallback? onMenuTap;
  final bool showMenu;

  const NeonAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.showNotifications = true,
    this.onNotificationTap,
    this.onAddFriendTap,
    this.onMenuTap,
    this.showMenu = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            VyRaTheme.primaryBlack,
            VyRaTheme.primaryBlack,
            VyRaTheme.darkGrey,
            Colors.transparent,
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (leading != null) leading!,
          if (showMenu && onMenuTap != null)
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: VyRaTheme.darkGrey,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.menu,
                  color: VyRaTheme.textWhite,
                  size: 22,
                ),
              ),
              onPressed: onMenuTap,
            ),
          Expanded(
            child: Text(
              title,
              style: VyRaTheme.appTitle.copyWith(fontSize: 18),
              textAlign: leading != null || (showMenu && onMenuTap != null) ? TextAlign.center : TextAlign.left,
            ),
          ),
          if (showNotifications)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onAddFriendTap != null)
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: VyRaTheme.darkGrey,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_add_alt_1_outlined,
                        color: VyRaTheme.textWhite,
                        size: 20,
                      ),
                    ),
                    onPressed: onAddFriendTap,
                  ),
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: VyRaTheme.darkGrey,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_none,
                      color: VyRaTheme.textWhite,
                      size: 20,
                    ),
                  ),
                  onPressed: onNotificationTap ?? () {},
                ),
              ],
            ),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(80);
}

