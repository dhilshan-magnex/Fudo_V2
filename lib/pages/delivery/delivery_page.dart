import 'package:flutter/material.dart';

import 'package:fudo_v2/core/theme/global_colors.dart';
import 'package:fudo_v2/pages/dinein/dinein_page.dart';
import 'package:fudo_v2/shared/layout/layout.dart';
import 'package:fudo_v2/shared/widgets/buttons/back_button.dart';
import 'package:fudo_v2/shared/widgets/contact_form.dart';

part 'widgets/delivery_header.dart';
part 'logic/delivery_controller.dart';
part 'widgets/delivery_form.dart';
part 'widgets/delivery_field.dart';

class DeliveryPage extends StatefulWidget {
  const DeliveryPage({super.key});

  @override
  State<DeliveryPage> createState() => _DeliveryPageState();
}
