import 'package:flutter/material.dart';
import '../data/models/user_model.dart';

import 'subscribe_button.dart';

class UserSuggestionCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onProfileTap;

  const UserSuggestionCard({
    super.key,
    required this.user,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 150,
      margin:
      const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
        isDarkMode ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode
              ? Colors.white10
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        mainAxisAlignment:
        MainAxisAlignment.center,
        children: [
          /// PROFILE IMAGE
          GestureDetector(
            onTap: onProfileTap,
            child: CircleAvatar(
              radius: 35,
              backgroundColor: isDarkMode
                  ? Colors.grey[800]
                  : Colors.grey.shade300,
              backgroundImage:
              user.avatarUrl != null
                  ? NetworkImage(
                  user.avatarUrl!)
                  : null,
              child: user.avatarUrl == null
                  ? const Icon(Icons.person,
                  color: Colors.white,
                  size: 30)
                  : null,
            ),
          ),
          const SizedBox(height: 10),

          /// USER NAME
          Text(
            user.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),

          Text(
            "@${user.username}",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),

          const Spacer(),

          /// ✅ CLEAN BUTTON
          SubscriberButton(
            userId: user.id,
          ),
        ],
      ),
    );
  }
}


/*class UserSuggestionCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onProfileTap;

  const UserSuggestionCard({
    super.key,
    required this.user,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final subController = Get.find<SubscriberController>();

    // Ensure status loaded
    subController.checkStatus(user.id);

    return Container(
      width: 150,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          /// PROFILE IMAGE
          GestureDetector(
            onTap: onProfileTap,
            child: CircleAvatar(
              radius: 35,
              backgroundColor:
              isDarkMode ? Colors.grey[800] : Colors.grey.shade300,
              backgroundImage: user.avatarUrl != null
                  ? NetworkImage(user.avatarUrl!)
                  : null,
              child: user.avatarUrl == null
                  ? const Icon(Icons.person, color: Colors.white, size: 30)
                  : null,
            ),
          ),
          const SizedBox(height: 10),

          /// USER NAME
          Text(
            user.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),

          Text(
            "@${user.username}",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),

          const Spacer(),

          /// SUBSCRIBE BUTTON
          Obx(() {
            final isSubscribed =
            subController.isSubscribed(user.id);

            return SizedBox(
              width: double.infinity,
              height: 32,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  isSubscribed ? Colors.grey.shade300 : Colors.blue,
                  foregroundColor:
                  isSubscribed ? Colors.black : Colors.white,
                  padding:
                  const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () =>
                    subController.toggle(user.id),
                child: Text(
                  isSubscribed ? "Subscribed" : "Subscribe",
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}*/
