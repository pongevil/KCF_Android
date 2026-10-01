import 'dart:io';

import 'package:bs_mobile/src/core/network/app_exception.dart';
import 'package:bs_mobile/src/global/blocs/version/repository/version_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'version_event.dart';
part 'version_state.dart';

class VersionBloc extends Bloc<VersionEvent, VersionState> {
  final VersionRepository _repository;

  VersionBloc(this._repository) : super(VersionInitial()) {
    on<VersionCheckEvent>(_onCheck);
    on<VersionDownloadEvent>(_onDownload);
  }

  Future<void> _onCheck(
    VersionCheckEvent event,
    Emitter<VersionState> emit,
  ) async {
    emit(VersionCheckInProgress());
    try {
      final result = await _repository.fetchVersionStatus();
      if (result.messageCode == 0 && result.isUpdateAvailable == true) {
        emit(
          VersionUpdateAvailable(
            result.messageText ?? '',
            isForceUpdate: result.isForceUpdate == true,
          ),
        );
      } else {
        emit(VersionUpToDate());
      }
    } catch (e) {
      emit(VersionCheckFailure('Failed to check version: $e'));
    }
  }

  Future<void> _onDownload(
    VersionDownloadEvent event,
    Emitter<VersionState> emit,
  ) async {
    emit(VersionDownloadInProgress());
    try {
      final permissions = await _repository.requestDownloadPermissions();
      if (!permissions.canDownload) {
        emit(
          VersionDownloadFailure('Storage permission required for download'),
        );
        return;
      }

      emit(VersionDownloading(0));

      final downloadsDir = await _repository.resolveDownloadsDirectory();
      if (downloadsDir == null) {
        emit(VersionDownloadFailure('Unable to access downloads directory'));
        return;
      }

      final downloadUrl = await _repository.buildDownloadUrl();
      final fileName = _repository.buildApkFileName();
      final savePath = '${downloadsDir.path}/$fileName';

      try {
        await _repository.downloadApk(
          url: downloadUrl,
          savePath: savePath,
          onProgress: (progress) => emit(VersionDownloading(progress)),
        );

        final apkFile = File(savePath);
        if (!await apkFile.exists()) {
          emit(VersionDownloadFailure('File not found after download'));
          return;
        }

        emit(
          VersionDownloadNotify(
            'Download completed!',
            VersionAlertType.success,
          ),
        );

        if (!permissions.installGranted) {
          emit(
            VersionDownloadNotify(
              'Go to Settings > Install unknown apps and allow this app.\nFile saved at: ${downloadsDir.path}',
              VersionAlertType.info,
            ),
          );
          emit(
            VersionDownloadSuccess(
              'Download completed. Enable install permission to proceed.',
            ),
          );
          return;
        }

        emit(VersionShouldOpenApk(savePath));
        emit(VersionDownloadSuccess('Download completed successfully'));
      } on AppException catch (e) {
        final statusCode = e.statusCode;
        emit(
          VersionDownloadFailure(
            'Download failed${statusCode != null ? ' ($statusCode)' : ''}: ${_repository.extractDownloadErrorMessage(e)}',
          ),
        );
      } catch (e) {
        emit(VersionDownloadFailure('Download failed: $e'));
      }
    } catch (e) {
      emit(VersionDownloadFailure('Download failed: $e'));
    } finally {
      emit(VersionDownloadDismissLoading());
    }
  }
}
