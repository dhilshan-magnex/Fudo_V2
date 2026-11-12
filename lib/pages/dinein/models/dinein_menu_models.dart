part of '../dinein_page.dart';

class _DineInData {
  const _DineInData(this.categories, this.items);
  final List<DineInCategory> categories;
  final List<DineInMenuItem> items;
}

class DineInCategory {
  const DineInCategory(this.code, this.name, this.order, this.colorCode);
  factory DineInCategory.fromRow(Map<String, dynamic> row) {
    final code = row['Cat_Code']?.toString().trim() ?? '';
    final name = row['Cat_Name']?.toString().trim() ?? '';
    return DineInCategory(
      code,
      name.isEmpty ? code : name,
      num.tryParse(row['Display_Order_ID']?.toString() ?? '')?.toInt() ?? 0,
      row['Color_Code']?.toString() ?? '',
    );
  }
  final String code;
  final String name;
  final int order;
  final String colorCode;
}

class DineInMenuItem {
  const DineInMenuItem({
    required this.id,
    required this.name,
    required this.longName,
    required this.categoryCode,
    required this.price,
    required this.colorCode,
    required this.order,
    required this.isAvailableForDineIn,
    this.image,
  });
  factory DineInMenuItem.fromRow(Map<String, dynamic> row) {
    final dine = row['Dine']?.toString().trim().toLowerCase();
    return DineInMenuItem(
      id: row['Menu_ID']?.toString().trim() ?? '',
      name: row['Menu_Name']?.toString().trim() ?? '',
      longName: row['Menu_Long_Name']?.toString().trim() ?? '',
      categoryCode: row['Cat_Code']?.toString().trim() ?? '',
      price: num.tryParse(row['Menu_Price']?.toString() ?? '')?.toDouble() ?? 0,
      colorCode: row['Color_Code']?.toString() ?? '',
      order:
          num.tryParse(row['Display_Order_ID']?.toString() ?? '')?.toInt() ?? 0,
      isAvailableForDineIn:
          dine == null ||
          dine.isEmpty ||
          dine == '1' ||
          dine == 'true' ||
          dine == 'yes',
      image: row['Menu_Image'],
    );
  }
  final String id;
  final String name;
  final String longName;
  final String categoryCode;
  final double price;
  final String colorCode;
  final int order;
  final bool isAvailableForDineIn;
  final Object? image;
}
