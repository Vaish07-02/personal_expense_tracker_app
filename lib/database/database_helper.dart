import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/expense.dart';

class DatabaseHelper {
  DatabaseHelper._privateConstructor();

  static final DatabaseHelper instance =
  DatabaseHelper._privateConstructor();

  static const String _databaseName = 'personal_expenses.db';
  static const int _databaseVersion = 1;
  static const String _tableName = 'expenses';

  Database? _database;

  // Return the existing database or initialize it.
  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initializeDatabase();
    return _database!;
  }

  // Open the SQLite database.
  Future<Database> _initializeDatabase() async {
    final directory = await getDatabasesPath();
    final databasePath = join(directory, _databaseName);

    return openDatabase(
      databasePath,
      version: _databaseVersion,
      onCreate: _createDatabase,
    );
  }

  // Create the expenses table.
  Future<void> _createDatabase(
      Database db,
      int version,
      ) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        description TEXT
      )
    ''');
  }

  // Insert an expense.
  Future<int> insertExpense(Expense expense) async {
    final db = await database;

    final data = expense.toMap();
    data.remove('id');

    return db.insert(
      _tableName,
      data,
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  // Retrieve all expenses, newest first.
  Future<List<Expense>> getAllExpenses() async {
    final db = await database;

    final records = await db.query(
      _tableName,
      orderBy: 'date DESC, id DESC',
    );

    return records.map(Expense.fromMap).toList();
  }

  // Retrieve a single expense by ID.
  Future<Expense?> getExpenseById(int id) async {
    final db = await database;

    final records = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (records.isEmpty) {
      return null;
    }

    return Expense.fromMap(records.first);
  }

  // Update an existing expense.
  Future<int> updateExpense(Expense expense) async {
    if (expense.id == null) {
      throw ArgumentError(
        'An expense ID is required for updating.',
      );
    }

    final db = await database;

    final data = expense.toMap();
    data.remove('id');

    return db.update(
      _tableName,
      data,
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  // Delete an expense by ID.
  Future<int> deleteExpense(int id) async {
    final db = await database;

    return db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Calculate the total of all expenses.
  Future<double> getTotalExpenses() async {
    final db = await database;

    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) AS total '
          'FROM $_tableName',
    );

    return (result.first['total'] as num).toDouble();
  }

  // Calculate expenses for one category.
  Future<double> getCategoryTotal(String category) async {
    final db = await database;

    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) AS total '
          'FROM $_tableName WHERE category = ?',
      [category],
    );

    return (result.first['total'] as num).toDouble();
  }

  // Close the database connection.
  Future<void> closeDatabase() async {
    final db = _database;

    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}