import 'package:citizenwallet/services/preferences/preferences.dart';
import 'package:citizenwallet/theme/provider.dart' as theme_provider;
import 'package:citizenwallet/utils/platform.dart';
import 'package:citizenwallet/widgets/button.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class MigrationModal extends StatefulWidget {
  const MigrationModal({super.key});

  @override
  MigrationModalState createState() => MigrationModalState();
}

class MigrationModalState extends State<MigrationModal> {
  late PreferencesService _preferences;

  @override
  void initState() {
    super.initState();
    _preferences = PreferencesService();
  }

  void handleDismiss() {
    _preferences.setMigrationModalShown(true);
    GoRouter.of(context).pop();
  }

  void handleDownload() async {
    _preferences.setMigrationModalShown(true);
    
    String url;
    if (isPlatformApple()) {
      url = '';
    } else if (isPlatformAndroid()) {
      url = '';
    } else {
      url = '';
    }

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Could not launch URL: $url');
    }

    if (mounted) {
      GoRouter.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = theme_provider.Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon or Logo
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme.colors.surfacePrimary.resolveFrom(context).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                CupertinoIcons.arrow_up_circle_fill,
                size: 40,
                color: theme.colors.surfacePrimary.resolveFrom(context),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Title
            Text(
              'We\'ve Moved!',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            // Message
            Text(
              'We\'ve migrated to a new and improved application. Download the new app to continue enjoying all the features with enhanced security and performance.',
              style: TextStyle(
                fontSize: 16,
                color: CupertinoColors.label.resolveFrom(context).withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            // Download Button
            SizedBox(
              width: double.infinity,
              child: Button(
                onPressed: handleDownload,
                text: isPlatformApple() 
                  ? 'Download on App Store'
                  : 'Download on Play Store',
                color: theme.colors.surfacePrimary.resolveFrom(context),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Dismiss Button
            SizedBox(
              width: double.infinity,
              child: Button(
                onPressed: handleDismiss,
                text: 'Not Now',
                color: CupertinoColors.systemGrey4,
                labelColor: CupertinoColors.label,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 