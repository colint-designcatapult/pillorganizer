import 'package:app/apiv2/control_plane.dart';
import 'package:app/apiv2/models/dto.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'control_plane_providers.g.dart';

@riverpod
ControlPlaneApiClient controlPlaneClient(Ref ref) {
  final dio = ref.watch(controlPlaneDioProvider);
  return ControlPlaneApiClient(dio);
}

