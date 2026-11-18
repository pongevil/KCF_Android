import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bs_mobile/src/features/goods_receive_weight_scale/models/goods_receive_models.dart';

class WeightScaleTcpService {
  const WeightScaleTcpService();

  Future<WeightReading> readStableWeight({
    required String scaleIp,
    required int scalePort,
    Duration connectTimeout = const Duration(seconds: 3),
    Duration readingTimeout = const Duration(seconds: 10),
  }) async {
    final socket = await Socket.connect(
      scaleIp,
      scalePort,
      timeout: connectTimeout,
    );
    final completer = Completer<WeightReading>();
    final buffer = StringBuffer();
    Timer? frameSettleTimer;
    late final StreamSubscription<List<int>> subscription;
    late final Timer timer;

    void inspect(String payload) {
      if (completer.isCompleted) return;
      buffer.write(payload);
      final accumulated = buffer.toString();
      final frames = accumulated.split(RegExp(r'[\r\n]+'));
      final hasTerminator = RegExp(r'[\r\n]').hasMatch(accumulated);
      final candidates = hasTerminator
          ? frames.take(frames.length - 1)
          : const <String>[];
      if (hasTerminator) {
        buffer
          ..clear()
          ..write(frames.last);
      }
      for (final frame in candidates) {
        final reading = WeightScaleFrameParser.tryParse(frame);
        if (reading != null && !completer.isCompleted) {
          completer.complete(reading);
          return;
        }
      }
      if (!hasTerminator) {
        frameSettleTimer?.cancel();
        frameSettleTimer = Timer(const Duration(milliseconds: 120), () {
          final reading = WeightScaleFrameParser.tryParse(buffer.toString());
          if (reading != null && !completer.isCompleted) {
            completer.complete(reading);
          }
        });
      }
      if (accumulated.length > 4096) buffer.clear();
    }

    subscription = socket.listen(
      (bytes) => inspect(ascii.decode(bytes, allowInvalid: true)),
      onError: (Object error, StackTrace stackTrace) {
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
      },
      onDone: () {
        if (!completer.isCompleted) {
          completer.completeError(
            const SocketException(
              'Scale connection closed before a stable weight was received',
            ),
          );
        }
      },
      cancelOnError: true,
    );
    timer = Timer(readingTimeout, () {
      if (!completer.isCompleted) {
        completer.completeError(
          TimeoutException(
            'No stable weight received from '
            '$scaleIp:$scalePort',
            readingTimeout,
          ),
        );
      }
    });

    try {
      return await completer.future;
    } finally {
      timer.cancel();
      frameSettleTimer?.cancel();
      await subscription.cancel();
      socket.destroy();
    }
  }
}

class WeightScaleFrameParser {
  WeightScaleFrameParser._();

  static final _numberPattern = RegExp(r'[-+]?\s*\d+(?:[.,]\d+)?');
  static final _unstablePattern = RegExp(
    r'(^|[,;\s])(US|UNSTABLE|MOTION|MOVING)(?=$|[,;\s])',
    caseSensitive: false,
  );

  static WeightReading? tryParse(String frame) {
    final normalized = frame.trim();
    if (normalized.isEmpty || _unstablePattern.hasMatch(normalized)) {
      return null;
    }

    final matches = _numberPattern.allMatches(normalized).toList();
    if (matches.isEmpty) return null;
    final numericText = matches.last
        .group(0)!
        .replaceAll(' ', '')
        .replaceAll(',', '.');
    var weight = double.tryParse(numericText);
    if (weight == null) return null;

    final unitText = normalized.toLowerCase();
    if (!unitText.contains('kg') && RegExp(r'\d\s*g\b').hasMatch(unitText)) {
      weight /= 1000;
    }

    return WeightReading(
      weightKg: weight,
      readAt: DateTime.now(),
      isStable: true,
    );
  }
}
