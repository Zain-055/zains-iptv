import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/playlist_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/tv_focusable.dart';
import 'home_screen.dart';

class PlaylistSetupScreen extends StatefulWidget {
  final bool isChangeMode;

  const PlaylistSetupScreen({super.key, this.isChangeMode = false});

  @override
  State<PlaylistSetupScreen> createState() => _PlaylistSetupScreenState();
}

class _PlaylistSetupScreenState extends State<PlaylistSetupScreen> {
  final TextEditingController _urlController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['m3u', 'm3u8', 'txt'],
      );

      if (files.isNotEmpty) {
        final filePath = files.first.path;
        if (filePath != null) {
          if (!mounted) return;
          final provider = Provider.of<PlaylistProvider>(context, listen: false);
          final success = await provider.loadFromFile(filePath);

          if (success && mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          } else if (mounted) {
            setState(() {
              _isLoading = false;
              _errorMessage = provider.errorMessage ?? 'Unable to load playlist file.';
            });
          }
        } else if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Selected file path was null.';
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error picking file: ${e.toString().replaceAll('Exception: ', '')}';
        });
      }
    }
  }

  void _showUrlDialog() {
    _urlController.clear();

    showDialog(
      context: context,
      builder: (dialogContext) {
        final colors = Theme.of(dialogContext).colorScheme;

        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.link_rounded, color: AppTheme.primaryAccent),
              SizedBox(width: 10),
              Text('Playlist URLs'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter one M3U/M3U8 URL per line:',
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 14),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _urlController,
                autofocus: true,
                style: TextStyle(color: colors.onSurface, fontSize: 16),
                decoration: const InputDecoration(
                  hintText: 'https://example.com/playlist1.m3u\nhttps://example.com/playlist2.m3u',
                  prefixIcon: Icon(Icons.http),
                  alignLabelWithHint: true,
                ),
                minLines: 3,
                maxLines: 6,
                keyboardType: TextInputType.multiline,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _loadUrls(_urlController.text);
              },
              child: const Text('Load Playlists'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadUrls(String input) async {
    final urls = input
        .split(RegExp(r'[\r\n]+'))
        .map((url) => url.trim())
        .where((url) => url.isNotEmpty)
        .toSet()
        .toList();

    if (urls.isEmpty) {
      setState(() {
        _errorMessage = 'Enter at least one playlist URL.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final provider = Provider.of<PlaylistProvider>(context, listen: false);
    final success = await provider.loadFromUrls(urls);

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else if (mounted) {
      setState(() {
        _isLoading = false;
        _errorMessage = provider.errorMessage ?? 'Unable to load playlist URLs.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: widget.isChangeMode
          ? AppBar(
              title: const Text('Change Playlist'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            )
          : null,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo Icon
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryAccent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.primaryAccent.withValues(alpha: 0.3), width: 2),
                    ),
                    child: const Icon(
                      Icons.tv_rounded,
                      size: 80,
                      color: AppTheme.primaryAccent,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // App Name
                  Text(
                    "ZAIN'S IPTV",
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Subtitle
                  Text(
                    'Load your playlist to get started',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 18,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'Unavailable channels are hidden automatically. Your source playlist file is never changed.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (_isLoading) ...[
                    const CircularProgressIndicator(color: AppTheme.primaryAccent),
                    const SizedBox(height: 20),
                    Text(
                      'Loading playlist...',
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Checking stream availability before showing channels.',
                      style: TextStyle(color: colors.onSurfaceVariant, fontSize: 14),
                    ),
                  ] else ...[
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.errorRed.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.4)),
                        ),
                        child: Column(
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error_outline_rounded, color: AppTheme.errorRed),
                                SizedBox(width: 8),
                                Text(
                                  'Unable to load playlist',
                                  style: TextStyle(
                                    color: AppTheme.errorRed,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: colors.onSurface, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Button 1: Load M3U File
                    TvFocusable(
                      autoFocus: true,
                      onPressed: _pickFile,
                      normalBackgroundColor: context.appCard,
                      focusedBackgroundColor: AppTheme.primaryAccent,
                      borderRadius: BorderRadius.circular(16),
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Icon(Icons.folder_open_rounded, size: 32, color: colors.onSurface),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Load M3U File',
                                  style: TextStyle(
                                    color: colors.onSurface,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Select .m3u or .m3u8 file from storage',
                                  style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Button 2: Enter Playlist URL
                    TvFocusable(
                      onPressed: _showUrlDialog,
                      normalBackgroundColor: context.appCard,
                      focusedBackgroundColor: AppTheme.primaryAccent,
                      borderRadius: BorderRadius.circular(16),
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Icon(Icons.language_rounded, size: 32, color: colors.onSurface),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Enter Playlist URLs',
                                  style: TextStyle(
                                    color: colors.onSurface,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Add multiple HTTP or HTTPS playlist links',
                                  style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
