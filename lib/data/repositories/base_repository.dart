import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../database/database_helper.dart';

/// Tüm repository'ler için ortak taban.
abstract class BaseRepository {
  final DatabaseHelper _helper = DatabaseHelper.instance;

  Future<Database> get db => _helper.database;
}
