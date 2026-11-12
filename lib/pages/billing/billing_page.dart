import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fudo_v2/functions/uservalidation/access_control_service.dart';
import 'package:fudo_v2/core/session/session_provider.dart';
import 'package:fudo_v2/core/theme/global_colors.dart';
import 'package:fudo_v2/pages/delivery/delivery_page.dart';
import 'package:fudo_v2/pages/dinein/dinein_page.dart';
import 'package:fudo_v2/pages/tables/table_page.dart';
import 'package:fudo_v2/functions/uservalidation/app_functions.dart';
import 'package:fudo_v2/functions/orders/state/order_provider.dart';
import 'package:fudo_v2/functions/orders/models/order.dart';
import 'package:fudo_v2/functions/orders/models/confirmed_order.dart';
import 'package:fudo_v2/shared/layout/layout.dart';
import 'package:fudo_v2/shared/widgets/authorization.dart';
import 'package:fudo_v2/shared/widgets/buttons/back_button.dart';
import 'package:fudo_v2/shared/widgets/buttons/button.dart';

part 'widgets/billing_header.dart';
part 'widgets/billing_order_table.dart';
part 'widgets/billing_buttons.dart';
part 'logic/billing_controller.dart';
part 'logic/billing_order_actions.dart';
part 'widgets/billing_view.dart';
part 'widgets/billing_order_details_sheet.dart';
part 'models/billing_running_order.dart';
part 'widgets/billing_content.dart';

const _orderIdColumnFlex = 9;
const _orderTypeColumnFlex = 7;
const _orderRefNoColumnFlex = 5;
const _orderActionColumnWidth = 24.0;

class BillingPage extends StatefulWidget {
  const BillingPage({super.key});

  @override
  State<BillingPage> createState() => _BillingPageState();
}
