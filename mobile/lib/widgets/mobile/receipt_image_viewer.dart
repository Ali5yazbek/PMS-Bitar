import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_config.dart';
import '../../config/app_theme.dart';
import '../../services/camera_service.dart';

/// Resolves a receipt image reference (`uploads/receipts/...`, `http...`,
/// `base64:...`, `data:image/...;base64,...`) and renders a thumbnail + full-screen
/// zoomable lightbox preview.
class ReceiptImageViewer {
  static final Map<String, Uint8List> _decodedCache = {};

  /// Returns candidate network URLs for a relative path like `uploads/receipts/agent/xxx.jpg`.
  static List<String> resolveUrls(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty ||
        trimmed.startsWith('base64:') ||
        trimmed.startsWith('data:image')) {
      return const [];
    }
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return [trimmed];
    }
    final cleanPath = trimmed.startsWith('/') ? trimmed.substring(1) : trimmed;
    final backendBase = AppConfig.apiBaseUrl.replaceAll(RegExp(r'/api/?$'), '');
    final rootBase = backendBase.replaceAll(RegExp(r'/backend/?$'), '');
    final urls = <String>['$backendBase/$cleanPath'];
    if (rootBase != backendBase) {
      urls.add('$rootBase/$cleanPath');
    }
    return urls;
  }

  /// Decodes base64 (`base64:...` or `data:image/...;base64,...`) with in-memory caching.
  static Uint8List? decodeBase64(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final cacheKey = trimmed.length > 160
        ? '${trimmed.length}:${trimmed.substring(0, 80)}:${trimmed.substring(trimmed.length - 80)}'
        : trimmed;
    final cached = _decodedCache[cacheKey];
    if (cached != null) return cached;

    try {
      String b64 = '';
      if (trimmed.startsWith('base64:')) {
        b64 = trimmed.substring(7);
      } else if (trimmed.startsWith('data:image')) {
        final idx = trimmed.indexOf(',');
        if (idx != -1) b64 = trimmed.substring(idx + 1);
      }
      if (b64.isEmpty) return null;
      final bytes = base64Decode(b64);
      if (_decodedCache.length > 60) {
        _decodedCache.remove(_decodedCache.keys.first);
      }
      _decodedCache[cacheKey] = bytes;
      return bytes;
    } catch (_) {
      return null;
    }
  }

  /// Builds an image widget for any receipt source (base64, local file, or network URL with fallback).
  static Widget buildImage(
    String rawSource, {
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
  }) {
    final memBytes = decodeBase64(rawSource);
    if (memBytes != null) {
      return Image.memory(
        memBytes,
        fit: fit,
        width: width,
        height: height,
        gaplessPlayback: true,
      );
    }

    // Check if it's a local device path (Android/iOS) before upload
    if (!kIsWeb &&
        !rawSource.startsWith('http') &&
        !rawSource.startsWith('uploads/') &&
        !rawSource.startsWith('/uploads/') &&
        (rawSource.startsWith('/') || rawSource.contains(':\\') || rawSource.contains(':/'))) {
      return FutureBuilder<Uint8List?>(
        future: CameraService.instance.readPhotoBytes(rawSource),
        builder: (context, snap) {
          if (snap.data != null) {
            return Image.memory(
              snap.data!,
              fit: fit,
              width: width,
              height: height,
              gaplessPlayback: true,
            );
          }
          return _errorPlaceholder(width: width, height: height);
        },
      );
    }

    final urls = resolveUrls(rawSource);
    if (urls.isEmpty) {
      return _errorPlaceholder(width: width, height: height);
    }

    return Image.network(
      urls.first,
      fit: fit,
      width: width,
      height: height,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          width: width,
          height: height,
          color: AppTheme.background,
          alignment: Alignment.center,
          child: const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        if (urls.length > 1) {
          return Image.network(
            urls[1],
            fit: fit,
            width: width,
            height: height,
            errorBuilder: (_, __, ___) => _errorPlaceholder(width: width, height: height),
          );
        }
        return _errorPlaceholder(width: width, height: height);
      },
    );
  }

  static Widget _errorPlaceholder({double? width, double? height}) {
    return Container(
      width: width,
      height: height,
      color: AppTheme.background,
      alignment: Alignment.center,
      child: const Icon(Icons.broken_image_outlined, color: AppTheme.textMuted, size: 22),
    );
  }

  /// Opens a full-screen zoomable lightbox dialog to inspect the receipt image.
  static void showLightbox(
    BuildContext context,
    String rawSource, {
    String title = 'Purchase Receipt Evidence',
    String? subtitle,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.88),
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long_rounded, color: AppTheme.primary, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.outfit(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          if (subtitle != null && subtitle.isNotEmpty)
                            Text(
                              subtitle,
                              style: GoogleFonts.plusJakartaSans(
                                color: AppTheme.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppTheme.textPrimary, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 540),
                  decoration: BoxDecoration(
                    color: const Color(0xFF050A0E),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
                    child: InteractiveViewer(
                      minScale: 0.8,
                      maxScale: 4.5,
                      child: Center(
                        child: buildImage(rawSource, fit: BoxFit.contain),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

