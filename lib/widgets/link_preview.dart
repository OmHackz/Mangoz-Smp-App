import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:oreui_flutter/oreui_flutter.dart';
import '../services/link_preview_service.dart';

/// Rich embedded link card.
class LinkPreviewView extends StatelessWidget {
  final LinkPreview preview;
  final void Function(String url)? onOpen;

  const LinkPreviewView({super.key, required this.preview, this.onOpen});

  @override
  Widget build(BuildContext context) {
    final ore = OreTheme.of(context);
    return GestureDetector(
      onTap: onOpen == null ? null : () => onOpen!(preview.url),
      child: OreCard(
        padding: const EdgeInsets.all(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (preview.imageUrl != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: CachedNetworkImage(
                  imageUrl: preview.imageUrl!,
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  errorWidget: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    preview.domain,
                    style: ore.typography.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (preview.title != null)
                    Text(
                      preview.title!,
                      style: ore.typography.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (preview.description != null)
                    Text(
                      preview.description!,
                      style: ore.typography.caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fetches metadata, falls back to a plain clickable URL.
class LinkPreviewCard extends StatefulWidget {
  final String url;
  final void Function(String url)? onOpen;

  const LinkPreviewCard({super.key, required this.url, this.onOpen});

  @override
  State<LinkPreviewCard> createState() => _LinkPreviewCardState();
}

class _LinkPreviewCardState extends State<LinkPreviewCard> {
  late final Future<LinkPreview?> _future;

  @override
  void initState() {
    super.initState();
    _future = LinkPreviewService.fetch(widget.url);
  }

  @override
  Widget build(BuildContext context) {
    final ore = OreTheme.of(context);
    return FutureBuilder<LinkPreview?>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Text(widget.url,
              style: ore.typography.body
                  .copyWith(color: ore.colors.info));
        }
        final preview = snap.data;
        if (preview == null) {
          return GestureDetector(
            onTap: widget.onOpen == null
                ? null
                : () => widget.onOpen!(widget.url),
            child: Text(
              widget.url,
              style: ore.typography.body.copyWith(
                color: ore.colors.info,
                decoration: TextDecoration.underline,
              ),
            ),
          );
        }
        return LinkPreviewView(preview: preview, onOpen: widget.onOpen);
      },
    );
  }
}
