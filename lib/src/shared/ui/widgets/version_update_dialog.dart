import 'package:bs_mobile/src/core/theme/theme_extensions.dart';
import 'package:bs_mobile/src/global/blocs/version/version_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app_text.dart';

class VersionUpdateDialog extends StatelessWidget {
  final String message;
  final bool isForceUpdate;

  const VersionUpdateDialog({
    super.key,
    required this.message,
    this.isForceUpdate = false,
  });

  @override
  Widget build(BuildContext context) {
    final app = context.appTheme;
    final cs = context.colorScheme;

    return PopScope(
      canPop: !isForceUpdate,
      child: BlocListener<VersionBloc, VersionState>(
        listener: (context, state) {
          if (state is VersionDownloadSuccess) {
            Navigator.of(context).pop();
          } else if (state is VersionDownloadFailure && !isForceUpdate) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.error, color: app.buttonDangerOn),
                    SizedBox(width: 8),
                    Expanded(
                      child: AppText(state.error, color: app.buttonDangerOn),
                    ),
                  ],
                ),
                backgroundColor: app.buttonDanger,
                duration: Duration(seconds: 5),
              ),
            );
          }
        },
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.system_update, color: cs.primary, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: AppText(
                  isForceUpdate ? 'Update Required' : 'App Update Available',
                  style: TextStyle(
                    color: cs.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: message.isEmpty
              ? null
              : AppText(message, style: TextStyle(fontSize: 15)),
          actions: [
            if (!isForceUpdate)
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: AppText(
                  'Later',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 16),
                ),
              ),
            BlocBuilder<VersionBloc, VersionState>(
              builder: (context, state) {
                return ElevatedButton(
                  onPressed: state is VersionDownloadInProgress
                      ? null
                      : () {
                          context.read<VersionBloc>().add(
                            VersionDownloadEvent(),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: app.buttonPrimary,
                    foregroundColor: app.buttonPrimaryOn,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: state is VersionDownloadInProgress
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              app.buttonPrimaryOn,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.download, size: 20),
                            SizedBox(width: 8),
                            AppText(
                              'Download',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
