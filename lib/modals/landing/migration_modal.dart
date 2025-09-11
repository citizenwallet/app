import 'package:citizenwallet/theme/provider.dart' as theme_provider;
import 'package:citizenwallet/utils/platform.dart';
import 'package:citizenwallet/widgets/button.dart';
import 'package:citizenwallet/services/preferences/preferences.dart';
import 'package:citizenwallet/services/migration/service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class MigrationModal extends StatefulWidget {
  final bool isWalletScreen;

  const MigrationModal({
    super.key,
    this.isWalletScreen = false,
  });

  @override
  MigrationModalState createState() => MigrationModalState();
}

class MigrationModalState extends State<MigrationModal> {
  final PreferencesService _preferences = PreferencesService();
  final MigrationService _migrationService = MigrationService();
  bool _isMigrating = false;

  void handleDismiss() async {
    await _preferences.incrementMigrationModalDismissalCount();

    if (mounted) {
      GoRouter.of(context).pop();
    }
  }

  void handleMigrate() async {
    if (widget.isWalletScreen) {
      // Wallet screen: perform actual migration
      await _performMigration();
    } else {
      // Landing screen: launch app store
      await _launchAppStore();
    }

    if (mounted) {
      GoRouter.of(context).pop();
    }
  }

  Future<void> _performMigration() async {
    setState(() {
      _isMigrating = true;
    });

    try {
      await _migrationService.performMigration();
    } catch (e) {
      if (mounted) {
        debugPrint('Migration failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isMigrating = false;
        });
      }
    }
  }

  Future<void> _launchAppStore() async {
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
      // URL launch failed
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
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon or Logo
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme.colors.surfacePrimary
                    .resolveFrom(context)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                CupertinoIcons.arrow_up_circle_fill,
                size: 40,
                color: theme.colors.surfacePrimary.resolveFrom(context),
              ),
            ),

            const SizedBox(height: 24),

            Text(
              widget.isWalletScreen ? 'Migrate Your Data' : 'We\'ve Moved!',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            Text(
              widget.isWalletScreen
                  ? 'Migrate your wallet data to the new app. Your accounts and settings will be securely transferred.'
                  : 'We\'ve migrated to a new and improved application. Download the new app to continue enjoying all the features.',
              style: TextStyle(
                fontSize: 16,
                color:
                    CupertinoColors.label.resolveFrom(context).withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: Button(
                onPressed: _isMigrating ? null : handleMigrate,
                text: _isMigrating
                    ? 'Migrating...'
                    : widget.isWalletScreen
                        ? 'Migrate'
                        : 'Download New App',
                color: theme.colors.surfacePrimary.resolveFrom(context),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: Button(
                onPressed: handleDismiss,
                text: 'Dismiss',
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
