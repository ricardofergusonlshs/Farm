// HPJ Share & Promote — the shared customer, marketing and Invite & Grow module.

// Add exactly once to lib/main.dart:

// part 'screens/marketing/share_and_promote.dart';

// This file is a PART of harvest_place_app; do not import main.dart here.

part of harvest_place_app;

// Official HPJ Google Play listing. Edit this constant if the public app ID changes.

const String hpjSharePlayUrl =
    'https://play.google.com/store/apps/details?id=com.harvestplaceja.myapp';

/// Accept only an HTTPS destination, otherwise return the official HPJ website.

String hpjShareSafeDestination(String? destination) {
  final candidate = destination?.trim() ?? '';

  final uri = Uri.tryParse(candidate);

  if (uri == null ||
      uri.scheme.toLowerCase() != 'https' ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty) {
    return AppConfig.publicShareUrl;
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
    caption: 'Fresh • Local • Jamaican. Discover fresh Jamaican produce.',
    destinationUrl: AppConfig.publicShareUrl,
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
    // On older installs the campaign table may not exist yet. Falling back to

    // branded sharing must not prevent customer checkout or app startup.

    farmDebugLog('Share & Promote campaign unavailable: $error');

    return null;
  }
}

/// Create a real shareable XFile, preferring the published campaign artwork.

/// Supabase Storage downloads use the existing authenticated client. For other

/// HTTPS images, use Flutter's network asset bundle; if the host blocks CORS,

/// use the bundled HPJ logo instead of generating a broken image attachment.

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

      return hpj_share_files.hpjImageShareFile(
        bytes,
        mimeType: mime,
        fileName: '$baseName.$extension',
      );
    } catch (error) {
      farmDebugLog('Marketing artwork download failed; using HPJ logo: $error');
    }
  }

  final logoBytes = await rootBundle.load('lib/assets/images/logo.png');

  return hpj_share_files.hpjImageShareFile(
    logoBytes.buffer.asUint8List(
      logoBytes.offsetInBytes,
      logoBytes.lengthInBytes,
    ),
    mimeType: 'image/png',
    fileName: '$baseName.png',
  );
}

/// Functional customer preview and share screen; no placeholder widgets.

class HpjSharePromoteScreen extends StatefulWidget {
  final HpjShareCampaign? previewCampaign;

  final Uint8List? previewImageBytes;

  const HpjSharePromoteScreen({
    super.key,
    this.previewCampaign,
    this.previewImageBytes,
  });

  @override
  State<HpjSharePromoteScreen> createState() => _HpjSharePromoteScreenState();
}

class _HpjSharePromoteScreenState extends State<HpjSharePromoteScreen> {
  late Future<HpjShareCampaign?> _campaignFuture;

  bool _sharing = false;

  Future<HpjShareCampaign?> _campaignSource() {
    final preview = widget.previewCampaign;

    return preview == null
        ? hpjFetchShareCampaign()
        : Future<HpjShareCampaign?>.value(preview);
  }

  @override
  void initState() {
    super.initState();

    _campaignFuture = _campaignSource();
  }

  @override
  void didUpdateWidget(covariant HpjSharePromoteScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.previewCampaign != widget.previewCampaign ||
        !identical(oldWidget.previewImageBytes, widget.previewImageBytes)) {
      _campaignFuture = _campaignSource();
    }
  }

  String _previewMimeType(Uint8List bytes) {
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }

    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'image/webp';
    }

    return 'image/jpeg';
  }

  String _extensionForMime(String mimeType) {
    switch (mimeType) {
      case 'image/png':
        return 'png';

      case 'image/webp':
        return 'webp';

      default:
        return 'jpg';
    }
  }

  Future<XFile> _prepareArtwork(HpjShareCampaign campaign) async {
    final previewBytes = widget.previewImageBytes;

    if (previewBytes != null && previewBytes.isNotEmpty) {
      final mimeType = _previewMimeType(previewBytes);

      return hpj_share_files.hpjImageShareFile(
        previewBytes,
        mimeType: mimeType,
        fileName: 'hpj-share-and-promote.${_extensionForMime(mimeType)}',
      );
    }

    return hpjPrepareSharePhoto(
      campaign.imageUrl,
      'hpj-share-and-promote',
    );
  }

  void _notice(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _share(HpjShareCampaign campaign) async {
    if (_sharing) return;

    setState(() => _sharing = true);

    final url = hpjShareSafeDestination(campaign.destinationUrl);

    final caption = campaign.caption.trim().isEmpty
        ? HpjShareCampaign.fallback.caption
        : campaign.caption.trim();

    final message = '$caption\n\n$url';

    try {
      try {
        final artwork = await _prepareArtwork(campaign);

        if (!mounted) return;

        await SharePlus.instance.share(
          ShareParams(
            files: <XFile>[artwork],
            fileNameOverrides: <String>[artwork.name],
            text: message,
            title: 'The Harvest Place Ja',
            sharePositionOrigin: hpjShareOrigin(context),
            downloadFallbackEnabled: true,
          ),
        );
      } catch (imageError) {
        farmDebugLog(
            'Share artwork unavailable; sharing link instead: $imageError');

        if (!mounted) return;

        await SharePlus.instance.share(
          ShareParams(
            text: message,
            title: 'The Harvest Place Ja',
            sharePositionOrigin: hpjShareOrigin(context),
          ),
        );
      }

      _notice('Share sheet opened. Confirm the recipient before sending.');
    } catch (error) {
      await Clipboard.setData(ClipboardData(text: message));

      _notice('Share sheet unavailable. The campaign message was copied.');

      farmDebugLog('Share & Promote unavailable: $error');
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  String _shortDestination(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null || uri.host.isEmpty) return value;
    final path = uri.path == '/' ? '' : uri.path;
    final result = '${uri.host}$path';
    return result.length > 38 ? '${result.substring(0, 35)}…' : result;
  }

  Widget _actionChip({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8F1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFDDE6DA)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: FarmColors.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: FarmColors.deepGreen,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
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
        title: const Text('Share HPJ'),
      ),
      body: FutureBuilder<HpjShareCampaign?>(
        future: _campaignFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final campaign = snapshot.data ?? HpjShareCampaign.fallback;
          final photo = cleanHostedImageUrl(campaign.imageUrl);
          final previewBytes = widget.previewImageBytes;
          final destination = hpjShareSafeDestination(campaign.destinationUrl);
          final headline = campaign.headline.trim().isEmpty
              ? HpjShareCampaign.fallback.headline
              : campaign.headline.trim();
          final caption = campaign.caption.trim().isEmpty
              ? HpjShareCampaign.fallback.caption
              : campaign.caption.trim();

          Widget artwork() {
            if (previewBytes != null && previewBytes.isNotEmpty) {
              return Image.memory(
                previewBytes,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              );
            }

            if (photo != null) {
              return Image.network(
                photo,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFFF8F6EA),
                  alignment: Alignment.center,
                  child: Image.asset(
                    'lib/assets/images/logo.png',
                    width: 115,
                    fit: BoxFit.contain,
                  ),
                ),
              );
            }

            return Container(
              color: const Color(0xFFF8F6EA),
              alignment: Alignment.center,
              child: Image.asset(
                'lib/assets/images/logo.png',
                width: 115,
                fit: BoxFit.contain,
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 110),
            children: <Widget>[
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: const Color(0xFFDDE6DA),
                      ),
                    ),
                    child: Image.asset(
                      'lib/assets/images/logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.eco_rounded,
                        color: FarmColors.primary,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Share HPJ',
                          style: TextStyle(
                            color: FarmColors.ink,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 1),
                        Text(
                          'Fresh Jamaican produce. One clean share.',
                          style: TextStyle(
                            color: FarmColors.mutedText,
                            fontSize: 8.8,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFDDE6DA),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x12000000),
                      blurRadius: 14,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 205,
                      width: double.infinity,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          artwork(),
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Color(0x10000000),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(13, 12, 13, 13),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            headline,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: FarmColors.ink,
                              fontSize: 16,
                              height: 1.08,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            caption,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: FarmColors.mutedText,
                              fontSize: 9.2,
                              height: 1.35,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F8F1),
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(
                                color: const Color(0xFFDDE6DA),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.link_rounded,
                                  size: 16,
                                  color: FarmColors.primary,
                                ),
                                const SizedBox(width: 7),
                                Expanded(
                                  child: Text(
                                    _shortDestination(destination),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: FarmColors.deepGreen,
                                      fontSize: 9.2,
                                      fontWeight: FontWeight.w800,
                                    ),
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
              const SizedBox(height: 12),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  _actionChip(
                    icon: Icons.eco_outlined,
                    label: 'Fresh',
                  ),
                  _actionChip(
                    icon: Icons.location_on_outlined,
                    label: 'Jamaican',
                  ),
                  _actionChip(
                    icon: Icons.handshake_outlined,
                    label: 'Local network',
                  ),
                ],
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: _sharing ? null : () => _share(campaign),
                  icon: _sharing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.ios_share_rounded,
                          size: 18,
                        ),
                  label: Text(
                    _sharing ? 'Preparing…' : 'Share HPJ',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: FarmColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: destination),
                    );
                    _notice('HPJ link copied.');
                  },
                  icon: const Icon(
                    Icons.copy_rounded,
                    size: 17,
                  ),
                  label: const Text(
                    'Copy Link',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: FarmColors.primary,
                    side: const BorderSide(
                      color: Color(0xFFBFD4BA),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'You choose the recipient and confirm the share before anything is sent.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: FarmColors.mutedText,
                  fontSize: 8.2,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
