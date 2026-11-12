import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fudo_v2/core/session/session_provider.dart';
import 'package:fudo_v2/core/theme/global_colors.dart';
import 'package:fudo_v2/data/database/db_manager.dart';
import 'package:fudo_v2/functions/orders/models/order.dart';
import 'package:fudo_v2/functions/orders/models/confirmed_order.dart';
import 'package:fudo_v2/functions/orders/state/order_provider.dart';
import 'package:fudo_v2/shared/layout/layout.dart';
import 'package:fudo_v2/shared/widgets/buttons/back_button.dart';
import 'package:fudo_v2/shared/widgets/buttons/discard_button.dart';
import 'package:fudo_v2/shared/widgets/contact_form.dart';

part 'widgets/dinein_header.dart';
part 'widgets/dinein_searchbar.dart';
part 'widgets/dinein_menu.dart';
part 'widgets/dinein_cart_bottom_sheet.dart';
part 'widgets/dinein_cart_panel.dart';
part 'widgets/dinein_customer_dialog.dart';
part 'models/dinein_cart_models.dart';
part 'widgets/dinein_add_note.dart';
part 'logic/dinein_controller.dart';
part 'widgets/dinein_view.dart';
part 'models/dinein_menu_models.dart';
part 'widgets/dinein_cart_badges.dart';
part 'logic/dinein_customer_controller.dart';

class DineInPage extends StatefulWidget {
  const DineInPage({
    super.key,
    this.tableNumber,
    this.customerName,
    this.customer,
    this.orderType,
    this.customerPhone,
    this.deliveryAddress,
    this.deliveryArea,
    this.orderNote,
    this.waiterName,
    this.pax,
    this.orderToUpdate,
  });

  final String? tableNumber;
  final String? customerName;
  final CustomerContact? customer;
  final String? orderType;
  final String? customerPhone;
  final String? deliveryAddress;
  final String? deliveryArea;
  final String? orderNote;
  final String? waiterName;
  final int? pax;
  final ConfirmedOrder? orderToUpdate;

  @override
  State<DineInPage> createState() => _DineInPageState();
}
