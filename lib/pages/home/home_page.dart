import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fudo_v2/core/session/session_provider.dart';
import 'package:fudo_v2/core/theme/global_colors.dart';
import 'package:fudo_v2/functions/authentication/client_service.dart';
import 'package:fudo_v2/pages/billing/billing_page.dart';
import 'package:fudo_v2/pages/data_sync/data_sync_page.dart';
import 'package:fudo_v2/shared/layout/layout.dart';
import 'package:fudo_v2/shared/widgets/buttons/button.dart';
import 'package:fudo_v2/shared/widgets/buttons/exit_button.dart';
import 'package:fudo_v2/shared/widgets/client_details.dart';
part 'logic/home_controller.dart';
part 'widgets/home_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}
