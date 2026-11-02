import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_theme.dart';
import 'package:dio/dio.dart';

class AsyncButton extends StatefulWidget {
  final String text;
  final IconData? icon;
  final Future<void> Function() onPressed;
  final Color backgroundColor;
  final Color textColor;
  final double width;

  const AsyncButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.backgroundColor = AppTheme.primary,
    this.textColor = Colors.white,
    this.width = double.infinity,
  });

  @override
  State<AsyncButton> createState() => _AsyncButtonState();
}

class _AsyncButtonState extends State<AsyncButton> {
  bool _isLoading = false;

  Future<void> _handlePress() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    
    try {
      await widget.onPressed();
    } on DioException catch (e) {
      if (mounted) {
        String msg = 'An error occurred';
        if (e.error == 'OFFLINE_QUEUED') {
          msg = e.message?.toString() ?? 'Saved offline. Will sync later.';
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppTheme.info));
          return;
        } else if (e.error == 'OFFLINE_UNSUPPORTED') {
          msg = e.message?.toString() ?? 'You must be online to upload files.';
        } else if (e.response != null && e.response?.data is Map && e.response?.data['error'] != null) {
          msg = e.response?.data['error'].toString() ?? 'Failed to submit';
        } else if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.connectionError) {
          msg = 'Network error. Please check your connection.';
        } else {
          msg = e.message ?? 'Network error';
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppTheme.danger));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.backgroundColor,
          foregroundColor: widget.textColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        onPressed: _isLoading ? null : _handlePress,
        child: _isLoading
            ? const SizedBox(
                width: 24, height: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(widget.text, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16)),
                ],
              ),
      ),
    );
  }
}
