
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pending_command_provider.g.dart';

/// Tracks whether a device command has been sent and is awaiting an MQTT
/// state update to confirm it was received.  All command-triggering buttons
/// should be disabled while this is true.
@riverpod
class PendingCommand extends _$PendingCommand {
  @override
  bool build() => false;

  void setCommandPending() => state = true;
  void clearCommandPending() => state = false;
}
