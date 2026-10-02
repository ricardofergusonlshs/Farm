part of harvest_place_app;

// ============================================================================
// HPJ SMART ANDROID UPDATE CONTROL
// Google Play In-App Update + Supabase minimum/latest build control.
// ============================================================================

class HpjAppUpdateService {
  static const String _packageName = 'com.harvestplaceja.myapp';
  static const String _dismissedVersionKey = 'hpj_android_update_dismissed_version';
  static const String _dismissedAtKey = 'hpj_android_update_dismissed_at_ms';

  static bool _checkedThisSession = false;
  static bool _dialogOpen = false;

  static Future<void> checkForUpdate({bool force = false}) async {
    final isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    if (!isAndroid) return;
    if (_checkedThisSession && !force) return;
    _checkedThisSession = true;

    if (!force) {
      await Future<void>.delayed(const Duration(milliseconds: 1200));
    }

    final package = await HpjRuntimePackageInfo.load();
    final control = await fetchHpjPublicAppReleaseControl();

    final belowMinimum = package.build > 0 && package.build < control.minAndroidBuild;
    final behindLatest = package.build > 0 && package.build < control.latestAndroidBuild;
    final forcedLatest = behindLatest && control.forceLatestUpdate;
    final required = belowMinimum || forcedLatest;

    AppUpdateInfo? playInfo;
    try {
      playInfo = await InAppUpdate.checkForUpdate().timeout(const Duration(seconds: 10));
    } catch (error, stackTrace) {
      unawaited(HpjReliability.recordNonFatal(
        error,
        stackTrace: stackTrace,
        area: 'app_update',
        eventKey: 'play_update_check_unavailable',
      ));
    }

    if (playInfo?.updateAvailability == UpdateAvailability.developerTriggeredUpdateInProgress) {
      if (playInfo?.immediateUpdateAllowed == true) {
        await _performImmediateUpdate();
      }
      return;
    }

    final playSaysAvailable = playInfo?.updateAvailability == UpdateAvailability.updateAvailable;
    if (!required && !behindLatest && !playSaysAvailable) return;

    if (!required && !force && await _wasDismissedRecently(control.latestAndroidBuild, control.snoozeHours)) {
      return;
    }

    final context = hpjRootNavigatorKey.currentContext;
    if (context == null || !context.mounted || _dialogOpen) return;

    unawaited(HpjAudienceAnalytics.track(
      required ? 'app_update_required' : 'app_update_prompt',
      screenName: 'app_update',
      metadata: <String, dynamic>{
        'current_build': package.build,
        'minimum_build': control.minAndroidBuild,
        'latest_build': control.latestAndroidBuild,
        'play_available': playSaysAvailable,
      },
    ));

    _dialogOpen = true;
    bool? updateNow;
    try {
      updateNow = await showDialog<bool>(
        context: context,
        barrierDismissible: !required,
        builder: (dialogContext) {
          return PopScope(
            canPop: !required,
            child: AlertDialog(
              icon: Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: required ? FarmColors.warningSoft : FarmColors.lightGreen,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  required ? Icons.system_security_update_warning_rounded : Icons.system_update_alt_rounded,
                  color: required ? FarmColors.warning : FarmColors.green,
                  size: 30,
                ),
              ),
              title: Text(
                required ? 'HPJ update required' : (control.updateTitle.isEmpty ? 'HPJ update available' : control.updateTitle),
                textAlign: TextAlign.center,
              ),
              content: Text(
                required
                    ? 'This version of The Harvest Place Ja is no longer supported. Update now to continue safely.'
                    : (control.updateMessage.isEmpty
                        ? 'A newer version of The Harvest Place Ja is ready with improvements and fixes.'
                        : control.updateMessage),
                textAlign: TextAlign.center,
              ),
              actionsAlignment: required ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
              actions: [
                if (!required)
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: const Text('Later'),
                  ),
                FilledButton.icon(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Update now'),
                ),
              ],
            ),
          );
        },
      );
    } finally {
      _dialogOpen = false;
    }

    if (updateNow != true) {
      if (!required) {
        await _rememberDismissal(control.latestAndroidBuild);
        unawaited(HpjAudienceAnalytics.track('app_update_later', screenName: 'app_update'));
      }
      return;
    }

    await _clearDismissal();
    unawaited(HpjAudienceAnalytics.track('app_update_started', screenName: 'app_update'));

    try {
      if (playInfo?.immediateUpdateAllowed == true) {
        await _performImmediateUpdate();
        return;
      }
      if (!required && playInfo?.flexibleUpdateAllowed == true) {
        await _performFlexibleUpdate();
        return;
      }
      await openPlayStore(control.playStoreUrl);
    } catch (error, stackTrace) {
      unawaited(HpjReliability.recordNonFatal(
        error,
        stackTrace: stackTrace,
        area: 'app_update',
        eventKey: 'update_flow_failed',
      ));
      await openPlayStore(control.playStoreUrl);
    }
  }

  static Future<void> _performImmediateUpdate() async {
    await InAppUpdate.performImmediateUpdate();
  }

  static Future<void> _performFlexibleUpdate() async {
    await InAppUpdate.startFlexibleUpdate();
    final context = hpjRootNavigatorKey.currentContext;
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('HPJ update downloaded. Finishing installation...')),
      );
    }
    await InAppUpdate.completeFlexibleUpdate();
  }

  static Future<void> openPlayStore([String configuredUrl = '']) async {
    final marketUri = Uri.parse('market://details?id=$_packageName');
    final webUri = Uri.parse(
      configuredUrl.trim().isEmpty
          ? 'https://play.google.com/store/apps/details?id=$_packageName'
          : configuredUrl.trim(),
    );

    try {
      if (await launchUrl(marketUri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {}

    try {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    } catch (error, stackTrace) {
      unawaited(HpjReliability.recordNonFatal(
        error,
        stackTrace: stackTrace,
        area: 'app_update',
        eventKey: 'play_store_open_failed',
      ));
    }
  }

  static Future<bool> _wasDismissedRecently(int versionCode, int snoozeHours) async {
    if (versionCode <= 0) return false;
    try {
      final prefs = await SharedPreferences.getInstance();
      final dismissedVersion = prefs.getInt(_dismissedVersionKey) ?? -1;
      final dismissedAtMs = prefs.getInt(_dismissedAtKey) ?? 0;
      if (dismissedVersion != versionCode || dismissedAtMs <= 0) return false;
      final dismissedAt = DateTime.fromMillisecondsSinceEpoch(dismissedAtMs);
      return DateTime.now().difference(dismissedAt) < Duration(hours: snoozeHours.clamp(1, 168).toInt());
    } catch (_) {
      return false;
    }
  }

  static Future<void> _rememberDismissal(int versionCode) async {
    if (versionCode <= 0) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_dismissedVersionKey, versionCode);
      await prefs.setInt(_dismissedAtKey, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {}
  }

  static Future<void> _clearDismissal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_dismissedVersionKey);
      await prefs.remove(_dismissedAtKey);
    } catch (_) {}
  }
}
