import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/dio_client.dart';
import 'thai_province.dart';

final thaiProvincesProvider = FutureProvider<List<ThaiProvince>>((ref) async {
  final response = await ref
      .watch(dioProvider)
      .get<List<dynamic>>('/provinces');
  final items = response.data;
  if (items == null) {
    throw const FormatException('ไม่พบรายการจังหวัด');
  }
  return items
      .map((item) => ThaiProvince.fromJson(item as Map<String, dynamic>))
      .toList(growable: false);
});
