import 'package:bs_mobile/src/global/local/app_storage.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DrawerProfileState extends Equatable {
  const DrawerProfileState({this.username = 'User Name', this.version = '-'});

  final String username;
  final String version;

  @override
  List<Object?> get props => [username, version];
}

/// Loads drawer display fields from persistence (single read path).
class DrawerProfileCubit extends Cubit<DrawerProfileState> {
  DrawerProfileCubit() : super(const DrawerProfileState());

  Future<void> load() async {
    final username = await AppStorage.getUsername();
    final version = await AppStorage.getVersion();
    emit(
      DrawerProfileState(
        username: (username == null || username.isEmpty)
            ? 'User Name'
            : username,
        version: (version == null || version.isEmpty) ? '-' : version,
      ),
    );
  }
}
