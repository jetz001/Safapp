import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:safety_superapp/core/database/database_helper.dart';

final databaseProvider = FutureProvider<Database>((ref) async {
  final dbHelper = DatabaseHelper();
  return await dbHelper.database;
});
