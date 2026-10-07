part of 'table_page.dart';

class _TableOrderDetails {
  const _TableOrderDetails({
    required this.customerName,
    required this.waiterName,
    required this.pax,
  });

  final String customerName;
  final String waiterName;
  final int pax;
}

class _TablePageData {
  const _TablePageData(this.sections, this.tables);
  final List<TableSection> sections;
  final List<TableLayoutTable> tables;
}

class TableSection {
  const TableSection(this.id, this.name, this.order);
  factory TableSection.fromRow(Map<String, dynamic> row) {
    final id = row['Section_ID']?.toString().trim() ?? '';
    final name = row['Section_Name']?.toString().trim() ?? '';
    return TableSection(
      id,
      name.isNotEmpty ? name : id,
      num.tryParse(row['Section_Order']?.toString() ?? '')?.toInt() ?? 0,
    );
  }
  final String id;
  final String name;
  final int order;
}

class TableLayoutTable {
  const TableLayoutTable({
    required this.number,
    required this.sectionId,
    required this.shape,
    required this.isActive,
  });

  factory TableLayoutTable.fromRow(Map<String, dynamic> row) {
    final active = row['Active']?.toString().trim().toLowerCase();
    return TableLayoutTable(
      number: row['Table_No']?.toString().trim() ?? '',
      sectionId: row['Section_ID']?.toString().trim() ?? '',
      shape: row['Table_Shape']?.toString().trim() ?? '',
      isActive:
          active == null ||
          active.isEmpty ||
          active == '1' ||
          active == 'true' ||
          active == 'yes',
    );
  }

  final String number;
  final String sectionId;
  final String shape;
  final bool isActive;
}
