// HPJ Share & Promote — the shared customer, marketing and Invite & Grow module.
// Add exactly once to lib/main.dart:
// part 'screens/marketing/share_and_promote.dart';
// This file is a PART of harvest_place_app; do not import main.dart here.
part of harvest_place_app;

// Primary public destination for campaign links and referrals.
const String hpjWebsiteUrl = 'https://harvestplaceja.com';

// Secondary, optional Android download destination, kept for existing users.
const String hpjSharePlayUrl =
    'https://play.google.com/store/apps/details?id=com.harvestplaceja.myapp';

/// Fall back to the website for absent/invalid links and migrate an old saved
/// default Play URL at read time. Do not rewrite other custom HTTPS campaign
/// destinations; Admin can link to a specific page on the website.
String hpjShareSafeDestination(String? destination) {
  final candidate = destination?.trim() ?? '';
  final uri = Uri.tryParse(candidate);
  if (uri == null ||
      uri.scheme.toLowerCase() != 'https' ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty) {
    return hpjWebsiteUrl;
  }
  final legacyPlayUrl = Uri.parse(hpjSharePlayUrl);
  if (uri.host.toLowerCase() == legacyPlayUrl.host &&
      uri.path == legacyPlayUrl.path &&
      uri.queryParameters['id'] == 'com.harvestplaceja.myapp') {
    return hpjWebsiteUrl;
  }
  return uri.toString();
}

/// File extension for uploaded/shareable image content.
String hpjShareExt(String contentType) {
  switch (contentType.trim().toLowerCase().split(';').first.trim()) {
    case 'image/png':
      return 'png';
    case 'image/webp':
      return 'webp';
    case 'image/jpeg':
    case 'image/jpg':
      return 'jpg';
    default:
      throw ArgumentError.value(contentType, 'contentType',
          'Share & Promote supports JPG, PNG and WebP images only.');
  }
}

/// iPad/Web share sheets require a physical origin rectangle.
Rect hpjShareOrigin(BuildContext context) {
  final renderObject = context.findRenderObject();
  if (renderObject is RenderBox && renderObject.hasSize) {
    return renderObject.localToGlobal(Offset.zero) & renderObject.size;
  }
  return const Rect.fromLTWH(0, 0, 1, 1);
}

class HpjShareCampaign {
  final String id;
  final String headline;
  final String caption;
  final String destinationUrl;
  final String imageUrl;
  final bool enabled;

  const HpjShareCampaign({
    required this.id,
    required this.headline,
    required this.caption,
    required this.destinationUrl,
    required this.imageUrl,
    required this.enabled,
  });

  static const HpjShareCampaign fallback = HpjShareCampaign(
    id: 'default',
    headline: 'The Harvest Place Ja',
    caption: 'Fresh • Local • Jamaican. Discover fresh produce and local farmers at The Harvest Place Ja.',
    destinationUrl: hpjWebsiteUrl,
    imageUrl: '',
    enabled: false,
  );

  factory HpjShareCampaign.fromSupabase(Map<String, dynamic> row) {
    return HpjShareCampaign(
      id: (row['id'] ?? 'default').toString(),
      headline: (row['headline'] ?? '').toString().trim(),
      caption: (row['caption'] ?? '').toString().trim(),
      destinationUrl:
          hpjShareSafeDestination(row['destination_url']?.toString()),
      imageUrl: cleanHostedImageUrl(row['image_url']?.toString()) ?? '',
      enabled: row['is_enabled'] == true,
    );
  }
}

/// Public callers receive only enabled campaigns. The Admin editor can load a
/// draft by passing includeDraft: true; existing Supabase RLS remains in force.
Future<HpjShareCampaign?> hpjFetchShareCampaign({
  bool includeDraft = false,
}) async {
  try {
    final response = await supabase
        .from('hpj_share_campaigns')
        .select('id,headline,caption,destination_url,image_url,is_enabled')
        .eq('id', 'default')
        .maybeSingle();
    if (response == null) return null;
    final campaign = HpjShareCampaign.fromSupabase(
      Map<String, dynamic>.from(response),
    );
    if (!includeDraft && !campaign.enabled) return null;
    return campaign;
  } catch (error) {
    // Customer sharing can fall back to the brand logo, but the Admin editor
    // must show the real database/RLS error instead of silently looking like
    // an empty campaign. Otherwise the owner cannot diagnose a missing table.
    farmDebugLog('Share & Promote campaign unavailable: $error');
    if (includeDraft) rethrow;
    return null;
  }
}

/// Create a real shareable XFile, preferring the published campaign artwork.
/// If an enabled campaign's photo cannot be downloaded, surface an error rather
/// than silently sending the brand logo in place of the selected advertisement.
/// The bundled logo is used only when no campaign artwork is configured.
Future<XFile> hpjPrepareSharePhoto(String imageUrl, String fileName) async {
  final safeBaseName = fileName.trim().replaceAll(
        RegExp(r'[^A-Za-z0-9_-]'),
        '_',
      );
  final baseName = safeBaseName.isEmpty ? 'hpj-share' : safeBaseName;
  final cleanImageUrl = cleanHostedImageUrl(imageUrl);

  if (cleanImageUrl != null) {
    try {
      final uri = Uri.parse(cleanImageUrl);
      final storageMarker = '/storage/v1/object/public/hpj-marketing/';
      final markerIndex = uri.path.indexOf(storageMarker);
      final bytes = markerIndex >= 0
          ? await supabase.storage.from('hpj-marketing').download(
                Uri.decodeComponent(uri.path.substring(
                  markerIndex + storageMarker.length,
                )),
              )
          : (await NetworkAssetBundle(uri).load(cleanImageUrl))
              .buffer
              .asUint8List();
      if (bytes.isEmpty || bytes.length > 8 * 1024 * 1024) {
        throw StateError('Marketing artwork is empty or exceeds 8 MB.');
      }
      final lowerPath = uri.path.toLowerCase();
      final extension = lowerPath.endsWith('.png')
          ? 'png'
          : lowerPath.endsWith('.webp')
              ? 'webp'
              : 'jpg';
      final mime = extension == 'png'
          ? 'image/png'
          : extension == 'webp'
              ? 'image/webp'
              : 'image/jpeg';
      return XFile.fromData(
        bytes,
        mimeType: mime,
        name: '$baseName.$extension',
      );
    } catch (error) {
      farmDebugLog('Marketing artwork download failed: $error');
      throw StateError(
        'Could not load the saved advertisement photo. '
        'Check its public Storage URL or upload it again. $error',
      );
    }
  }

  final logoBytes = await rootBundle.load('lib/assets/images/logo.png');
  return XFile.fromData(
    logoBytes.buffer.asUint8List(
      logoBytes.offsetInBytes,
      logoBytes.lengthInBytes,
    ),
    mimeType: 'image/png',
    name: '$baseName.png',
  );
}

/// Functional customer preview and share screen; no placeholder widgets.
class HpjSharePromoteScreen extends StatefulWidget {
  /// Admin-only in-memory preview. Neither draft text nor local image bytes
  /// are written to the database or exposed to ordinary customer sessions.
  final HpjShareCampaign? previewCampaign;
  final Uint8List? previewImageBytes;

  const HpjSharePromoteScreen({
    super.key,
    this.previewCampaign,
    this.previewImageBytes,
  });

  @override
  State<HpjSharePromoteScreen> createState() =>
      _HpjSharePromoteScreenState();
}

class _HpjSharePromoteScreenState extends State<HpjSharePromoteScreen> {
  late Future<HpjShareCampaign?> _campaignFuture;
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    _campaignFuture = widget.previewCampaign == null
        ? hpjFetchShareCampaign()
        : Future<HpjShareCampaign?>.value(widget.previewCampaign);
  }

  bool get _adminPreview => widget.previewCampaign != null;

  void _notice(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // A desktop browser cannot insert a photo into WhatsApp Web's compose box.
  // In particular, share_plus's desktop-web fallback DOWNLOADS the photo and
  // does not send the accompanying caption to WhatsApp. Use a truthful two-step
  // workflow instead. A mobile browser/native app can attempt the share sheet.
  bool get _desktopWeb =>
      kIsWeb &&
      defaultTargetPlatform != TargetPlatform.android &&
      defaultTargetPlatform != TargetPlatform.iOS;

  String _shareMessage(HpjShareCampaign campaign) {
    final caption = campaign.caption.trim().isEmpty
        ? HpjShareCampaign.fallback.caption
        : campaign.caption.trim();
    return '$caption\n\n${hpjShareSafeDestination(campaign.destinationUrl)}';
  }

  /// On Android/iOS, offer the photo AND caption to the operating-system
  /// sharing sheet. The receiving app decides whether it retains the caption.
  Future<void> _share(HpjShareCampaign campaign) async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final artwork = await hpjPrepareSharePhoto(
        campaign.imageUrl,
        'hpj-share-and-promote',
      );
      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          files: <XFile>[artwork],
          fileNameOverrides: <String>[artwork.name],
          text: _shareMessage(campaign),
          title: 'The Harvest Place Ja',
          sharePositionOrigin: hpjShareOrigin(context),
          // Never silently download the file and claim that it was shared.
          downloadFallbackEnabled: false,
        ),
      );
      if (!mounted) return;
      _notice('Choose WhatsApp and check that the photo is attached before sending.');
    } catch (error) {
      farmDebugLog('Photo sharing unavailable: $error');
      if (!mounted) return;
      _notice(kIsWeb
          ? 'Your browser cannot share this photo directly. Use the photo and WhatsApp buttons below.'
          : 'Could not share the photo: $error');
      if (kIsWeb) setState(() => _showWebInstructions = true);
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  bool _showWebInstructions = false;

  /// Desktop web: share_plus downloads the selected image if native file
  /// sharing is unavailable. The user must attach the photo in WhatsApp Web.
  Future<void> _savePhotoForWhatsApp(HpjShareCampaign campaign) async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final artwork = await hpjPrepareSharePhoto(
        campaign.imageUrl,
        'hpj-whatsapp-advertisement',
      );
      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          files: <XFile>[artwork],
          fileNameOverrides: <String>[artwork.name],
          sharePositionOrigin: hpjShareOrigin(context),
          downloadFallbackEnabled: true,
        ),
      );
      if (!mounted) return;
      _notice('Photo download/share requested. Attach the image in WhatsApp using + or the paperclip.');
    } catch (error) {
      farmDebugLog('WhatsApp photo save failed: $error');
      _notice('Could not prepare the photo: $error');
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  /// Open WhatsApp directly from the button tap (no photo-fetch await), so
  /// browser popup blockers do not reject the new window as often.
  Future<void> _openWhatsAppWithCaption(HpjShareCampaign campaign) async {
    final message = _shareMessage(campaign);
    final url = 'https://wa.me/?text=${Uri.encodeComponent(message)}';
    final opened = await openExternalShareUrl(url);
    if (!opened) {
      await Clipboard.setData(ClipboardData(text: message));
      _notice('Could not open WhatsApp. The message was copied instead.');
    }
  }

  Future<void> _copyWhatsAppMessage(HpjShareCampaign campaign) async {
    await Clipboard.setData(ClipboardData(text: _shareMessage(campaign)));
    _notice('Advertisement caption and website link copied.');
  }

  /// A website link can generate a WhatsApp preview from the deployed HTML
  /// metadata. It cannot attach the campaign's separate image automatically.
  Future<void> _visitWebsite() async {
    final opened = await openExternalShareUrl(hpjWebsiteUrl);
    if (!opened) {
      await Clipboard.setData(const ClipboardData(text: hpjWebsiteUrl));
      _notice('Could not open the website. Website address copied.');
    }
  }

  Future<void> _shareWebsiteOnFacebook(HpjShareCampaign campaign) async {
    final destination = hpjShareSafeDestination(campaign.destinationUrl);
    final shareUrl = 'https://www.facebook.com/sharer/sharer.php?u='
        '${Uri.encodeComponent(destination)}';
    final opened = await openExternalShareUrl(shareUrl);
    if (!opened) {
      await Clipboard.setData(ClipboardData(text: destination));
      _notice('Could not open Facebook. Website link copied.');
    }
  }

  Future<void> _openAndroidAppLink() async {
    final opened = await openExternalShareUrl(hpjSharePlayUrl);
    if (!opened) _notice('Could not open Google Play.');
  }

  /// Refresh in place: do not recreate the screen or reset the Admin workspace.
  Future<void> _refreshCampaign() async {
    if (_adminPreview) return; // An in-memory draft is not a published record.
    final next = hpjFetchShareCampaign();
    if (!mounted) return;
    setState(() => _campaignFuture = next);
    await next;
  }

  Widget _panel({
    required Widget child,
    Color color = Colors.white,
    EdgeInsetsGeometry padding = const EdgeInsets.all(18),
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: FarmColors.border),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: FarmColors.shadow.withOpacity(0.045),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _label(String text, {Color color = FarmColors.primary}) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: color,
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _artwork(String? photo) {
    // Preview a newly selected image without pretending it was uploaded.
    if (_adminPreview && widget.previewImageBytes != null) {
      return Image.memory(widget.previewImageBytes!, fit: BoxFit.contain);
    }
    // Do not masquerade as a published advertisement when none was saved.
    if (photo == null) {
      return Container(
        color: FarmColors.primarySoft,
        padding: const EdgeInsets.all(34),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: Image.asset(
                'lib/assets/images/logo.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 12),
            _label('HPJ BRAND PREVIEW'),
          ],
        ),
      );
    }
    return Image.network(
      photo,
      key: ValueKey<String>(photo),
      fit: BoxFit.contain, // An advertisement can include text; never crop it.
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const Center(child: CircularProgressIndicator());
      },
      errorBuilder: (context, error, stackTrace) => Container(
        padding: const EdgeInsets.all(20),
        color: FarmColors.dangerSoft,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.broken_image_outlined,
                color: FarmColors.danger, size: 42),
            const SizedBox(height: 10),
            const Text(
              'Campaign image unavailable',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: FarmColors.primaryDark,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Ask Admin to check the published Storage image.',
              textAlign: TextAlign.center,
              style: TextStyle(color: FarmColors.mutedText, fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _refreshCampaign,
              icon: const Icon(Icons.refresh_rounded, size: 17),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _campaignCard(HpjShareCampaign campaign, String? photo) {
    final isLive = campaign.enabled;
    final headline = campaign.headline.trim().isEmpty
        ? HpjShareCampaign.fallback.headline
        : campaign.headline.trim();
    final caption = campaign.caption.trim().isEmpty
        ? HpjShareCampaign.fallback.caption
        : campaign.caption.trim();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: FarmColors.border),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: FarmColors.shadow.withOpacity(0.075),
            blurRadius: 24,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            color: FarmColors.primaryDark,
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 12),
            child: Row(
              children: <Widget>[
                const Icon(Icons.eco_rounded, color: FarmColors.accent, size: 19),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'THE HARVEST PLACE JA',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 0.7,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: isLive ? FarmColors.successSoft : FarmColors.accentSoft,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    _adminPreview ? 'PREVIEW' : (isLive ? 'LIVE' : 'BRAND'),
                    style: TextStyle(
                      color: isLive ? FarmColors.primaryDark : FarmColors.warning,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          AspectRatio(
            aspectRatio: 1.15,
            child: ColoredBox(
              color: FarmColors.primarySoft,
              child: _artwork(photo),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 19),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _label('Fresh  •  Local  •  Jamaican'),
                const SizedBox(height: 8),
                Text(
                  headline,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: FarmColors.primaryDark,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  caption,
                  style: const TextStyle(
                    fontSize: 14,
                    color: FarmColors.mutedText,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: FarmColors.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: <Widget>[
                      Icon(Icons.storefront_outlined,
                          size: 17, color: FarmColors.primary),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Discover Jamaican produce with HPJ',
                          style: TextStyle(
                            color: FarmColors.primaryDark,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_forward_rounded,
                          size: 17, color: FarmColors.primary),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filledAction({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 19),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        style: FilledButton.styleFrom(
          backgroundColor: FarmColors.primaryDark,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  Widget _outlineAction({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 19),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        style: OutlinedButton.styleFrom(
          foregroundColor: FarmColors.primaryDark,
          side: const BorderSide(color: FarmColors.border),
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  Widget _sharingPanel(HpjShareCampaign campaign) {
    final webSteps = _desktopWeb || _showWebInstructions;
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: FarmColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.ios_share_rounded,
                    color: FarmColors.primary, size: 21),
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Share this campaign',
                      style: TextStyle(
                        color: FarmColors.primaryDark,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Help someone discover fresh Jamaican produce.',
                      style: TextStyle(
                        color: FarmColors.mutedText,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (webSteps) ...<Widget>[
            const Text(
              'WhatsApp Web: photo + caption',
              style: TextStyle(
                fontSize: 13,
                color: FarmColors.primaryDark,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Browsers cannot automatically attach a photo using a WhatsApp link. '
              'Use these two steps to send the real image, not just its URL.',
              style: TextStyle(
                color: FarmColors.mutedText,
                fontSize: 12,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 15),
            _filledAction(
              label: _sharing ? 'Preparing advertisement…' : '1  ·  Save advertisement image',
              icon: _sharing ? Icons.hourglass_top_rounded : Icons.download_rounded,
              onPressed: _sharing ? null : () => _savePhotoForWhatsApp(campaign),
            ),
            const SizedBox(height: 9),
            _outlineAction(
              label: '2  ·  WhatsApp website link & caption',
              icon: Icons.chat_outlined,
              onPressed: _sharing ? null : () => _openWhatsAppWithCaption(campaign),
            ),
            const SizedBox(height: 11),
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: FarmColors.accentSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(Icons.info_outline_rounded,
                      size: 18, color: FarmColors.warning),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'In WhatsApp, attach the saved image using + or the '
                      'paperclip. Keep or paste the caption, then send.',
                      style: TextStyle(
                        color: FarmColors.warning,
                        fontSize: 11.5,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...<Widget>[
            _filledAction(
              label: _sharing ? 'Preparing artwork…' : 'Share photo & message',
              icon: _sharing ? Icons.hourglass_top_rounded : Icons.share_rounded,
              onPressed: _sharing ? null : () => _share(campaign),
            ),
            const SizedBox(height: 9),
            const Text(
              'Choose WhatsApp in your device sharing sheet. Confirm that '
              'both the photo and message appear before sending.',
              style: TextStyle(
                color: FarmColors.mutedText,
                fontSize: 11.5,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 13),
          if (!webSteps) ...<Widget>[
            _outlineAction(
              label: 'Share website link on WhatsApp',
              icon: Icons.chat_outlined,
              onPressed: () => _openWhatsAppWithCaption(campaign),
            ),
            const SizedBox(height: 9),
          ],
          _outlineAction(
            label: 'Share campaign link on Facebook',
            icon: Icons.public_rounded,
            onPressed: () => _shareWebsiteOnFacebook(campaign),
          ),
          const SizedBox(height: 9),
          _outlineAction(
            label: 'Copy caption & campaign link',
            icon: Icons.content_copy_outlined,
            onPressed: () => _copyWhatsAppMessage(campaign),
          ),
        ],
      ),
    );
  }

  Widget _linkPanel(HpjShareCampaign campaign) {
    final destination = hpjShareSafeDestination(campaign.destinationUrl);
    return _panel(
      color: FarmColors.cardSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _label('VISIT THE HARVEST PLACE JA'),
          const SizedBox(height: 8),
          const Text(
            hpjWebsiteUrl,
            style: TextStyle(
              color: FarmColors.primaryDark,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          _filledAction(
            label: 'Visit our website',
            icon: Icons.language_rounded,
            onPressed: _visitWebsite,
          ),
          const SizedBox(height: 10),
          _outlineAction(
            label: 'Copy website link',
            icon: Icons.copy_rounded,
            onPressed: () async {
              await Clipboard.setData(
                const ClipboardData(text: hpjWebsiteUrl),
              );
              _notice('Website link copied.');
            },
          ),
          if (destination != hpjWebsiteUrl) ...<Widget>[
            const SizedBox(height: 16),
            _label('CAMPAIGN DESTINATION'),
            const SizedBox(height: 7),
            SelectableText(destination,
                style: const TextStyle(
                  color: FarmColors.primaryDark,
                  fontSize: 12,
                )),
            const SizedBox(height: 8),
            _outlineAction(
              label: 'Copy campaign link',
              icon: Icons.link_rounded,
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: destination));
                _notice('Campaign link copied.');
              },
            ),
          ],
          const SizedBox(height: 18),
          const Divider(),
          const SizedBox(height: 7),
          const Text('Prefer the Android app?',
              style: TextStyle(
                color: FarmColors.primaryDark,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              )),
          const SizedBox(height: 9),
          _outlineAction(
            label: 'Get the app on Google Play',
            icon: Icons.android_rounded,
            onPressed: _openAndroidAppLink,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: AppBar(
        backgroundColor: FarmColors.card,
        foregroundColor: FarmColors.primaryDark,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Share & Promote',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        actions: <Widget>[
          if (!_adminPreview)
            IconButton(
              tooltip: 'Refresh published campaign',
              onPressed: _refreshCampaign,
              icon: const Icon(Icons.refresh_rounded),
            ),
        ],
      ),
      body: FutureBuilder<HpjShareCampaign?>(
        future: _campaignFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(Icons.wifi_off_rounded,
                        size: 40, color: FarmColors.danger),
                    const SizedBox(height: 10),
                    const Text('Could not load the campaign.'),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _refreshCampaign,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            );
          }
          // Never display unpublished Admin drafts on the customer screen.
          final campaign = snapshot.data ?? HpjShareCampaign.fallback;
          final photo = cleanHostedImageUrl(campaign.imageUrl);
          final isLive = campaign.enabled;
          return RefreshIndicator(
            onRefresh: _refreshCampaign,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 22, 16, 36),
                  children: <Widget>[
                    if (_adminPreview) ...<Widget>[
                      _panel(
                        color: FarmColors.warningSoft,
                        child: const Row(
                          children: <Widget>[
                            Icon(Icons.visibility_outlined,
                                color: FarmColors.warning),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'ADMIN PREVIEW ONLY • Not published or shared. '
                                'Return to Marketing to save and publish.',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: FarmColors.warning,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    _label('GROW THE HARVEST'),
                    const SizedBox(height: 6),
                    const Text(
                      'Good food is worth sharing.',
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w900,
                        color: FarmColors.primaryDark,
                        height: 1.14,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'Preview the latest HPJ campaign and send it to your '
                      'friends, family or customers.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: FarmColors.mutedText,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _campaignCard(campaign, photo),
                    if (!isLive && !_adminPreview) ...<Widget>[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: FarmColors.accentSoft,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Icon(Icons.campaign_outlined,
                                size: 19, color: FarmColors.warning),
                            SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                'No campaign is published yet. This is HPJ '
                                'branding. Admin can upload and publish an '
                                'advertisement under Marketing & Sharing.',
                                style: TextStyle(
                                  color: FarmColors.warning,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    if (_adminPreview)
                      _panel(
                        color: FarmColors.warningSoft,
                        child: const Text(
                          'Sharing is disabled in draft preview. '
                          'Only saved, published campaigns can be shared.',
                          style: TextStyle(
                            color: FarmColors.warning,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    else ...<Widget>[
                      _sharingPanel(campaign),
                      const SizedBox(height: 14),
                      _linkPanel(campaign),
                    ],
                    const SizedBox(height: 25),
                    const Center(
                      child: Text(
                        'THE HARVEST PLACE JA  ·  FRESH • LOCAL • JAMAICAN',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: FarmColors.mutedText,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.55,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
