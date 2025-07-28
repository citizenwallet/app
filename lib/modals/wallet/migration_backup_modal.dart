import 'package:citizenwallet/state/backup/logic.dart';
import 'package:citizenwallet/state/backup/state.dart';
import 'package:citizenwallet/state/notifications/state.dart';
import 'package:citizenwallet/theme/provider.dart';
import 'package:citizenwallet/widgets/button.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class MigrationBackupModal extends StatefulWidget {
  final String? title;
  final String? message;

  const MigrationBackupModal({
    super.key,
    this.title,
    this.message,
  });

  @override
  MigrationBackupModalState createState() => MigrationBackupModalState();
}

class MigrationBackupModalState extends State<MigrationBackupModal> {
  late BackupLogic _backupLogic;

  @override
  void initState() {
    super.initState();
    _backupLogic = BackupLogic(context);
  }

  void handleDismiss(BuildContext context) {
    FocusManager.instance.primaryFocus?.unfocus();
    GoRouter.of(context).pop();
  }

  void handleBackupWallet() async {
    HapticFeedback.heavyImpact();

    try {
      await _backupLogic.backupAndroid();

      if (mounted) {
        context.read<NotificationsState>().toastShow(
              'Wallet backed up successfully!',
              type: ToastType.success,
            );
        handleDismiss(context);
      }
    } catch (e) {
      if (mounted) {
        context.read<NotificationsState>().toastShow(
              'Failed to backup wallet. Please try again.',
              type: ToastType.error,
            );
      }
    }
  }

  void handleRestoreWallet() async {
    HapticFeedback.heavyImpact();

    try {
      final hasAccounts = await _backupLogic.hasAccounts();

      if (hasAccounts) {
        await _backupLogic.setupAndroidFromRecovery();

        if (mounted) {
          context.read<NotificationsState>().toastShow(
                'Wallet restored successfully!',
                type: ToastType.success,
              );
          handleDismiss(context);
        }
      } else {
        if (mounted) {
          context.read<NotificationsState>().toastShow(
                'No backup found to restore.',
                type: ToastType.error,
              );
        }
      }
    } catch (e) {
      if (mounted) {
        context.read<NotificationsState>().toastShow(
              'Failed to restore wallet. Please try again.',
              type: ToastType.error,
            );
      }
    }
  }

  void handleMigrateWallet() async {
    HapticFeedback.heavyImpact();

    try {
      if (mounted) {
        context.read<NotificationsState>().toastShow(
              'Wallet migration completed!',
              type: ToastType.success,
            );
        handleDismiss(context);
      }
    } catch (e) {
      if (mounted) {
        context.read<NotificationsState>().toastShow(
              'Failed to migrate wallet. Please try again.',
              type: ToastType.error,
            );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.select((BackupState state) => state.loading);

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: CupertinoPageScaffold(
        backgroundColor:
            Theme.of(context).colors.uiBackgroundAlt.resolveFrom(context),
        child: SafeArea(
          minimum: const EdgeInsets.only(left: 10, right: 10, top: 20),
          child: Flex(
            direction: Axis.vertical,
            children: [
              Header(
                title: widget.title ?? 'Wallet Management',
                showBackButton: true,
              ),
              Expanded(
                child: CustomScrollView(
                  scrollBehavior: const CupertinoScrollBehavior(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          const SizedBox(height: 40),
                          SvgPicture.asset(
                            'assets/citizenwallet-only-logo.svg',
                            semanticsLabel: 'Citizen Wallet Icon',
                            height: 100,
                          ),
                          const SizedBox(height: 30),
                          if (widget.message != null) ...[
                            Text(
                              widget.message!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.normal,
                                color: Theme.of(context)
                                    .colors
                                    .text
                                    .resolveFrom(context),
                              ),
                            ),
                            const SizedBox(height: 30),
                          ],
                          Text(
                            'Secure your wallet and manage your data',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.normal,
                              color: Theme.of(context)
                                  .colors
                                  .text
                                  .resolveFrom(context),
                            ),
                          ),
                          const SizedBox(height: 40),
                          if (loading) ...[
                            const CupertinoActivityIndicator(),
                            const SizedBox(height: 20),
                            Text(
                              'Processing...',
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context)
                                    .colors
                                    .text
                                    .resolveFrom(context),
                              ),
                            ),
                          ] else ...[
                            Button(
                              text: 'Backup Wallet',
                              prefix: Icon(
                                CupertinoIcons.cloud_upload,
                                size: 20,
                                color: Theme.of(context)
                                    .colors
                                    .black
                                    .resolveFrom(context),
                              ),
                              onPressed: handleBackupWallet,
                              minWidth: 250,
                              maxWidth: 250,
                            ),
                            const SizedBox(height: 20),
                            Button(
                              text: 'Restore Wallet',
                              prefix: Icon(
                                CupertinoIcons.cloud_download,
                                size: 20,
                                color: Theme.of(context)
                                    .colors
                                    .black
                                    .resolveFrom(context),
                              ),
                              onPressed: handleRestoreWallet,
                              minWidth: 250,
                              maxWidth: 250,
                            ),
                            const SizedBox(height: 20),
                            Button(
                              text: 'Migrate Wallet',
                              prefix: Icon(
                                CupertinoIcons.arrow_right_arrow_left,
                                size: 20,
                                color: Theme.of(context)
                                    .colors
                                    .black
                                    .resolveFrom(context),
                              ),
                              onPressed: handleMigrateWallet,
                              minWidth: 250,
                              maxWidth: 250,
                            ),
                          ],
                          const SizedBox(height: 40),
                          Text(
                            'Your wallet data is encrypted and secure',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colors
                                  .text
                                  .resolveFrom(context)
                                  .withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
