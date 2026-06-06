Widget productImagePreviewFromUrl({
  required String? imageUrl,
  double height = 130,
}) {
  final cleanUrl = cleanHostedImageUrl(imageUrl);

  Widget fallbackPreview() {
    return Container(
      height: height,
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            FarmColors.cardSoft,
            Color(0xFFEAF6E8),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: FarmColors.line),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: height >= 180 ? 72 : 52,
            height: height >= 180 ? 72 : 52,
            decoration: BoxDecoration(
              color: FarmColors.lightGreen,
              shape: BoxShape.circle,
              border: Border.all(color: FarmColors.green.withOpacity(0.12)),
            ),
            child: Icon(
              Icons.eco_outlined,
              size: height >= 180 ? 34 : 26,
              color: FarmColors.green,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Image coming soon',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: FarmColors.deepGreen,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Fresh product details are still available below.',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: FarmColors.mutedText,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  if (cleanUrl == null || cleanUrl.trim().isEmpty) {
    return fallbackPreview();
  }

  return ClipRRect(
    borderRadius: BorderRadius.circular(22),
    child: Container(
      height: height,
      width: double.infinity,
      color: FarmColors.cardSoft,
      alignment: Alignment.center,
      child: Image.network(
        cleanUrl,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
        cacheWidth: height >= 180 ? 900 : 600,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;

          return Container(
            height: height,
            width: double.infinity,
            decoration: BoxDecoration(
              color: FarmColors.cardSoft,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: FarmColors.line),
            ),
            child: const Center(
              child: SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) => fallbackPreview(),
      ),
    ),
  );
}
