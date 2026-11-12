import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fudo_v2/core/session/session_provider.dart';
import 'package:fudo_v2/functions/orders/state/order_provider.dart';
import 'package:fudo_v2/functions/orders/models/order.dart';
import 'package:fudo_v2/functions/orders/models/confirmed_order.dart';
import 'package:fudo_v2/pages/tables/models/table_models.dart';
import 'package:fudo_v2/pages/tables/logic/table_layout_provider.dart';
import 'package:fudo_v2/core/theme/global_colors.dart';
import 'package:fudo_v2/pages/dinein/dinein_page.dart';
import 'package:fudo_v2/shared/layout/layout.dart';
import 'package:fudo_v2/shared/widgets/buttons/back_button.dart';
import 'package:fudo_v2/shared/widgets/contact_form.dart';

part 'widgets/table_header.dart';
part 'widgets/table_grid.dart';
part 'widgets/table_details_dialog.dart';
part 'logic/table_controller.dart';
part 'widgets/table_view.dart';
part 'models/table_order_details.dart';
part 'logic/table_details_controller.dart';

/// Displays the restaurant floor plan stored in `Table_Layout`.
///
/// The layout data is deliberately read from the local database: it is kept up
/// to date by Data Sync and therefore still works while the POS is offline.
class TablePage extends StatefulWidget {
  const TablePage({super.key, this.onTableSelected});

  final ValueChanged<TableLayoutTable>? onTableSelected;

  @override
  State<TablePage> createState() => _TablePageState();
}
