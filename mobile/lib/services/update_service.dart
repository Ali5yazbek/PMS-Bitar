// ─── Autonomous In-App Update Engine & Mandatory Release Enforcement ──────────
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api_service.dart';

class UpdateService {
  static const String currentVersion = '1.0.0';
  static const int currentCode = 1;

  static const String _dismissedVersionKey = 'update_dismissed_version';
  static const String _dismissedTimestampKey = 'update_dismissed_timestamp';

  static bool _isShowingDialog = false;

  /// Checks for available releases on startup or resume.
  static Future<void> checkForUpdates(
    BuildContext context, {
    bool isManual = false,
  }) async {
    if (!context.mounted) return;

    try {
      final platform = kIsWeb
          ? 'web'
          : (Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : 'universal'));

      final response = await ApiService().client.get(
        '/releases/check-update',
        queryParameters: {
          'platform': platform,
          'current_version': currentVersion,
          'current_code': currentCode,
        },
      );

      final data = response.data;
      if (data is! Map) return;

      final bool updateAvailable = data['update_available'] == true;
      final bool isMandatory = data['is_mandatory'] == true;
      final String latestVersion = (data['latest_version'] ?? '').toString();
      final String downloadUrl = (data['download_url'] ?? '').toString();
      final String releaseNotes = (data['release_notes'] ?? '').toString();
      final String fileSize = (data['file_size_formatted'] ?? '').toString();
      final String releaseDate = (data['release_date'] ?? '').toString();

      if (!updateAvailable) {
        if (isManual && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF0F172A),
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'You are using the latest version (v$currentVersion).',
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          );
        }
        return;
      }

      // If optional update, check if user dismissed it in the last 24 hours
      if (!isMandatory && !isManual) {
        final prefs = await SharedPreferences.getInstance();
        final dismissedVersion = prefs.getString(_dismissedVersionKey);
        final dismissedTime = prefs.getInt(_dismissedTimestampKey) ?? 0;
        final now = DateTime.now().millisecondsSinceEpoch;

        if (dismissedVersion == latestVersion && (now - dismissedTime) < 86400000) {
          // Dismissed within last 24h
          return;
        }
      }

      if (_isShowingDialog || !context.mounted) return;

      _isShowingDialog = true;
      await showDialog(
        context: context,
        barrierDismissible: !isMandatory,
        builder: (ctx) => _buildUpdateDialog(
          ctx,
          latestVersion: latestVersion,
          downloadUrl: downloadUrl,
          releaseNotes: releaseNotes,
          fileSize: fileSize,
          releaseDate: releaseDate,
          isMandatory: isMandatory,
        ),
      );
      _isShowingDialog = false;
    } catch (e) {
      if (kDebugMode) {
        print('Update check failed (non-blocking): $e');
      }
      if (isManual && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF7F1D1D),
            content: Text(
              'Unable to check for updates. Check connection.',
              style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
            ),
          ),
        );
      }
    }
  }

  static Widget _buildUpdateDialog(
    BuildContext context, {
    required String latestVersion,
    required String downloadUrl,
    required String releaseNotes,
    required String fileSize,
    required String releaseDate,
    required bool isMandatory,
  }) {
    return PopScope(
      canPop: !isMandatory,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isMandatory ? const Color(0xFFEF4444).withValues(alpha: 0.4) : const Color(0xFF10B981).withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (isMandatory ? const Color(0xFFEF4444) : const Color(0xFF10B981)).withValues(alpha: 0.2),
                blurRadius: 32,
                spreadRadius: 2,
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Badge & Icon
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: (isMandatory ? const Color(0xFFEF4444) : const Color(0xFF10B981)).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: (isMandatory ? const Color(0xFFEF4444) : const Color(0xFF10B981)).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(
                      isMandatory ? Icons.security_update_warning_rounded : Icons.system_update_rounded,
                      color: isMandatory ? const Color(0xFFF87171) : const Color(0xFF34D399),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isMandatory ? 'Required Update' : 'New Version Available',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'v$latestVersion (Installed: v$currentVersion)',
                          style: GoogleFonts.firaCode(
                            color: const Color(0xFF94A3B8),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Badges
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (fileSize.isNotEmpty)
                    _buildPill(Icons.inventory_2_outlined, fileSize),
                  if (releaseDate.isNotEmpty)
                    _buildPill(Icons.calendar_today_outlined, releaseDate),
                  _buildPill(Icons.verified_user_outlined, 'Signed Production'),
                ],
              ),

              const SizedBox(height: 16),

              // Release Notes Box
              Text(
                "What's New in This Version:",
                style: GoogleFonts.inter(
                  color: const Color(0xFFCBD5E1),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),

              Container(
                constraints: const BoxConstraints(maxHeight: 180),
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF07090E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    releaseNotes.isNotEmpty
                        ? releaseNotes
                        : '• Critical performance upgrades and enhancements.\n• Autonomous Agency AI cross-platform sync.\n• Faster image compression and offline sync.',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF94A3B8),
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ),
              ),

              if (isMandatory) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Color(0xFFF87171), size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'This update contains critical database compatibility fixes and is required to continue.',
                        style: GoogleFonts.inter(color: const Color(0xFFFCA5A5), fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 22),

              // Action buttons
              Row(
                children: [
                  if (!isMandatory)
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString(_dismissedVersionKey, latestVersion);
                          await prefs.setInt(_dismissedTimestampKey, DateTime.now().millisecondsSinceEpoch);
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          'Later',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF94A3B8),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  if (!isMandatory) const SizedBox(width: 12),
                  Expanded(
                    flex: isMandatory ? 2 : 1,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF14B8A6)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () async {
                          if (downloadUrl.isNotEmpty) {
                            final uri = Uri.parse(downloadUrl);
                            try {
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              } else {
                                await launchUrl(uri);
                              }
                            } catch (_) {
                              try {
                                await launchUrl(uri, mode: LaunchMode.externalNonBrowserApplication);
                              } catch (_) {}
                            }
                          }
                          if (!isMandatory && context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.download_rounded, color: Color(0xFF022C22), size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Update Now',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF022C22),
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 5),
          Text(
            text,
            style: GoogleFonts.inter(
              color: const Color(0xFFCBD5E1),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

