import 'package:flutter/material.dart';
import 'package:fudo_v2/core/config/server_settings.dart';
import 'package:fudo_v2/data/server/users_api.dart';
import 'package:fudo_v2/functions/uservalidation/access_control_service.dart';
import 'package:fudo_v2/core/session/session_provider.dart';
import 'package:fudo_v2/core/theme/global_colors.dart';
import 'package:fudo_v2/data/synchronization/api_route_registry.dart';
import 'package:fudo_v2/functions/uservalidation/app_functions.dart';
import 'package:fudo_v2/shared/layout/layout.dart';
import 'package:fudo_v2/shared/widgets/authorization.dart';
import 'package:provider/provider.dart';
part 'widgets/sync_server_dialog.dart';
part 'logic/data_sync_controller.dart';
part 'widgets/data_sync_dialog.dart';
part 'logic/sync_server_controller.dart';

class DataSyncDialog extends StatefulWidget {
  const DataSyncDialog({super.key});

  @override
  State<DataSyncDialog> createState() => _DataSyncDialogState();
}
