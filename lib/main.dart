// main.dart - copy-paste this whole code block to replace your existing main.dart file

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'package:path/path.dart' as p;

void main() {
  runApp(const KnomApp());
}

class KnomApp extends StatefulWidget {
  const KnomApp({super.key});

  @override
  State<KnomApp> createState() => _KnomAppState();
}

class _KnomAppState extends State<KnomApp> {
  ThemeMode _themeMode = ThemeMode.system;
  Color _seedColor = Colors.deepOrange; // Default seed color

  @override
  void initState() {
    super.initState();
    _loadThemePreferences();
  }


  /// Loads the saved theme mode and seed color preference from SharedPreferences.
  Future<void> _loadThemePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('theme_mode') ?? 0;
    final seedColorValue = prefs.getInt('seed_color') ?? Colors.deepOrange.value;
    setState(() {
      _themeMode = ThemeMode.values[themeIndex];
      _seedColor = Color(seedColorValue);
    });
  }

  /// Saves the selected theme mode preference to SharedPreferences.
  Future<void> _saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', mode.index);
    setState(() {
      _themeMode = mode;
    });
  }

  /// Saves the selected seed color preference to SharedPreferences.
  Future<void> _saveSeedColor(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('seed_color', color.value);
    setState(() {
      _seedColor = color;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Define the color schemes dynamically based on the selected seed color
    // Light theme color scheme
    final ColorScheme lightColorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: _seedColor,
      onPrimary: Colors.white,
      secondary: _seedColor.withOpacity(0.7),
      onSecondary: Colors.black,
      surface: Colors.white,
      onSurface: Colors.grey.shade800,
      background: _seedColor.withOpacity(0.05),
      onBackground: Colors.grey.shade700,
      error: Colors.red,
      onError: Colors.white,
      surfaceVariant: _seedColor.withOpacity(0.1),
      onSurfaceVariant: Colors.grey.shade700,
    );

    // Dark theme color scheme
    final ColorScheme darkColorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: _seedColor,
      onPrimary: Colors.white,
      secondary: _seedColor,
      onSecondary: Colors.black,
      surface: Colors.grey.shade900,
      onSurface: Colors.white,
      background: Colors.black,
      onBackground: Colors.white,
      error: Colors.red.shade400,
      onError: Colors.black,
      surfaceVariant: Colors.grey.shade800,
      onSurfaceVariant: Colors.grey.shade300,
    );


    return MaterialApp(
      title: 'Knom - Know Your Money',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: lightColorScheme,
        appBarTheme: AppBarTheme(
          backgroundColor: lightColorScheme.primary,
          foregroundColor: lightColorScheme.onPrimary,
          elevation: 4,
          shadowColor: lightColorScheme.shadow.withOpacity(0.2),
        ),
        cardTheme: CardThemeData(
          color: lightColorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: lightColorScheme.primary,
          contentTextStyle: TextStyle(color: lightColorScheme.onPrimary),
        ),
        // Further customize other widgets if needed
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: darkColorScheme,
        appBarTheme: AppBarTheme(
          backgroundColor: darkColorScheme.primary,
          foregroundColor: darkColorScheme.onPrimary,
          elevation: 4,
          shadowColor: darkColorScheme.shadow.withOpacity(0.2),
        ),
        cardTheme: CardThemeData(
          color: darkColorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: darkColorScheme.primary,
          contentTextStyle: TextStyle(color: darkColorScheme.onPrimary),
        ),
      ),
      home: HomePage(
        onThemeChanged: _saveThemeMode,
        currentThemeMode: _themeMode,
        onSeedColorChanged: _saveSeedColor,
        currentSeedColor: _seedColor,
      ),
    );
  }
}

class Transaction {
  final int? id;
  final String type;
  final double amount;
  final DateTime date;
  final String message;
  final String? source;
  final String? description;

  Transaction({
    this.id,
    required this.type,
    required this.amount,
    required this.date,
    required this.message,
    this.source,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'date': date.millisecondsSinceEpoch,
      'message': message,
      'source': source,
      'description': description,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      type: map['type'],
      amount: map['amount'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      message: map['message'],
      source: map['source'],
      description: map['description'],
    );
  }

  @override
  String toString() {
    return 'Transaction(Type: $type, Amount: $amount, Date: $date, Source: $source, Description: $description)';
  }
}

class DatabaseHelper {
  static Database? _database;
  static const String _tableName = 'transactions';
  static const int _databaseVersion = 2;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = p.join(directory.path, 'knom.db');

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        date INTEGER NOT NULL,
        message TEXT NOT NULL,
        source TEXT,
        description TEXT
      )
    ''');
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        ALTER TABLE $_tableName
        ADD COLUMN description TEXT;
      ''');
    }
  }

  static Future<void> insertTransaction(Transaction transaction) async {
    final db = await database;
    await db.insert(_tableName, transaction.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Fetches transactions from the database, optionally filtered by date range.
  /// This is optimized to query the database directly for the date range.
  static Future<List<Transaction>> getTransactions({DateTime? startDate, DateTime? endDate}) async {
    final db = await database;
    List<String> whereClauses = [];
    List<dynamic> whereArgs = [];

    if (startDate != null) {
      whereClauses.add('date >= ?');
      whereArgs.add(startDate.millisecondsSinceEpoch);
    }
    if (endDate != null) {
      whereClauses.add('date <= ?');
      whereArgs.add(endDate.millisecondsSinceEpoch);
    }

    String? whereString = whereClauses.isEmpty ? null : whereClauses.join(' AND ');

    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: whereString,
      whereArgs: whereArgs,
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => Transaction.fromMap(maps[i]));
  }

  static Future<void> clearAllTransactions() async {
    final db = await database;
    await db.delete(_tableName);
  }
}

class SMSReader {
  static const MethodChannel _channel = MethodChannel('sms_reader');

  static Future<List<Map<String, dynamic>>> readSMS() async {
    try {
      final dynamic result = await _channel.invokeMethod('readSMS');

      if (result == null) {
        print("SMS result is null");
        return [];
      }

      if (result is! List) {
        print("SMS result is not a List: ${result.runtimeType}");
        return [];
      }

      List<Map<String, dynamic>> messages = [];
      for (var item in result) {
        try {
          if (item is Map) {
            Map<String, dynamic> messageMap = {};
            item.forEach((key, value) {
              if (key != null) {
                messageMap[key.toString()] = value;
              }
            });

            // Validate that we have required fields
            if (messageMap.containsKey('body') &&
                messageMap.containsKey('date') &&
                messageMap.containsKey('address')) {
              messages.add(messageMap);
            } else {
              print("SMS message missing required fields: $messageMap");
            }
          } else if (item is String) {
            print("Received SMS as string (should be fixed in native code): ${item.substring(0, min(50, item.length))}...");
            Map<String, dynamic> messageMap = {
              'body': item,
              'date': DateTime.now().millisecondsSinceEpoch,
              'address': 'UNKNOWN',
              'id': DateTime.now().millisecondsSinceEpoch.toString(),
              'type': 1
            };
            messages.add(messageMap);
          } else {
            print("SMS item is unexpected type: ${item.runtimeType}");
          }
        } catch (e) {
          print("Error processing SMS item: $e");
          continue;
        }
      }

      print("Successfully processed ${messages.length} SMS messages");
      return messages;
    } on PlatformException catch (e) {
      print("Failed to read SMS: '${e.message}'");
      return [];
    } catch (e) {
      print("Unexpected error reading SMS: $e");
      return [];
    }
  }
}

class TransactionParser {
  // --- Debit Patterns ---
  static final List<RegExp> _debitPatterns = [
    RegExp(r'debited|debit|withdrawn|purchase|spent|paid|charged|deducted|katoti|bhugtan|kharch|nikala', caseSensitive: false),
    RegExp(r'ATM\s*withdrawal|POS\s*transaction', caseSensitive: false),
    RegExp(r'UPI.*(?:debited|paid|transfer|bhugtan|cut)', caseSensitive: false),
    RegExp(r'card.*(?:used|transaction|payment|bhugtan|kharid)', caseSensitive: false),
    RegExp(r'.*(?:paid|bhugtan)|utility.*paid', caseSensitive: false),
    RegExp(r'transaction.*successful.*(?:for|of|ka|ke).*rs\.?', caseSensitive: false),
    RegExp(r'payment.*successful.*(?:for|of|ka|ke).*rs\.?', caseSensitive: false),
    RegExp(r'recharge.*(?:successful|done|completed|hogaya|safal)', caseSensitive: false),
    RegExp(r'plan.*(?:activated|pack.*activated|chaalu|shuru)', caseSensitive: false),
    RegExp(r'subscription.*(?:charged|premium.*charged|kat gaya)', caseSensitive: false),
    RegExp(r'order.*(?:placed|payment.*made|book hua)', caseSensitive: false),
    RegExp(r'amount.*(?:deducted|cut|kata)|money.*(?:deducted|cut|kata)', caseSensitive: false),
  ];

  // --- Credit Patterns ---
  static final List<RegExp> _creditPatterns = [
    RegExp(r'credited|credit|received|deposit|salary|refund|transfer(?:red)?|prapt|jamma|aaya|wapas', caseSensitive: false),
    RegExp(r'amount\s*credited|money\s*received|rupya\s*aaya', caseSensitive: false),
    RegExp(r'UPI.*(?:credited|received|prapt)', caseSensitive: false),
    RegExp(r'imps.*credited|neft.*credited|rtgs.*credited', caseSensitive: false),
    RegExp(r'refund|reversed|returned|wapas|lapta hua', caseSensitive: false),
    RegExp(r'.*credited|talk.*time.*added|data.*added', caseSensitive: false),
    RegExp(r'amount.*added|money.*added|jamma hua', caseSensitive: false),
  ];

  // --- Amount Patterns (prioritizing currency symbols) ---
  static final List<RegExp> _amountPatterns = [
    RegExp(r'(?:INR|Rs\.?|₹)\s*(\d{1,3}(?:,\d{3})*(?:\.\d{1,2})?)', caseSensitive: false),
    RegExp(r'(\d{1,3}(?:,\d{3})*(?:\.\d{1,2})?)\s*(?:INR|Rs\.?|₹)', caseSensitive: false),
    RegExp(r'(?:rupees|rs\.?|rupya)\s*(\d{1,3}(?:,\d{3})*(?:\.\d{1,2})?)', caseSensitive: false),
    RegExp(r'(\d{1,3}(?:,\d{3})*(?:\.\d{1,2})?)\s*(?:rupees|rs\.?|rupya)', caseSensitive: false),
    RegExp(r'(?:of|for|ka|ke)\s*(\d{1,3}(?:,\d{3})*(?:\.\d{1,2})?)', caseSensitive: false),
  ];

  // --- Bank, Telecom, Payment Gateway & Merchant Patterns ---
  static final List<RegExp> _sourcePatterns = [
    RegExp(r'(SBI|ICICI|HDFC|AXIS|PNB|BOI|KOTAK|CANARA|UNION|FEDERAL|YES|INDUSIND|IDFC|BANDHAN|RBL|ALLAHABAD|ANDHRA|BANK OF BARODA|CENTRAL BANK|DENA BANK|INDIAN BANK|ORIENTAL BANK|PUNJAB & SIND|UCO BANK|UNITED BANK)', caseSensitive: false),
    RegExp(r'([A-Z]{2,4}BANK|BANK\s*OF\s*[A-Z]+)', caseSensitive: false),
    RegExp(r'account\s*number\s*(?:X+|xx+|XX+)?\d{4}', caseSensitive: false),
    RegExp(r'(?:saving|current)\s*a\/c', caseSensitive: false),
    RegExp(r'(AIRTEL|JIO|VI|VODAFONE|BSNL)', caseSensitive: false),
    RegExp(r'(PAYTM|PHONEPE|GOOGLEPAY|GPAY|AMAZONPAY|FREECHARGE|MOBIKWIK|BHIM|WALLET)', caseSensitive: false),
    RegExp(r'(ZOMATO|SWIGGY|UBER|OLA|FLIPKART|AMAZON|MYNTRA|BIGBASKET|GROFERS|DOMINOS|PIZZA HUT|STARBUCKS|NETFLIX|HOTSTAR|PRIME VIDEO|SPOTIFY)', caseSensitive: false),
    RegExp(r'(?:(?:online|atm|pos)\s*|e-comm\s*|credit card|debit card|upi)\s*(transaction|payment|purchase|kharid)', caseSensitive: false),
    RegExp(r'(?:merchant|shop|store)\s*(?:payment|purchase|dukan)', caseSensitive: false),
  ];

  // --- OTP Patterns (very strict to avoid false positives) ---
  static final List<RegExp> _otpPatterns = [
    RegExp(r'\b\d{4,6}\b\s*(?:is|are|hai)\s*(?:your|the|apka|apki)\s*(?:otp|one time password|code|pin|verification code|security code|gupt code)', caseSensitive: false),
    RegExp(r'^(?:otp|code|pin|verification)\s*(?:is|:|hai)\s*\d{4,6}\b', caseSensitive: false),
    RegExp(r'\buse\s*\d{4,6}\s*to\s*(?:verify|confirm|authenticate|authorize|validate|complete|satyapit karein|pushti karein)', caseSensitive: false),
    RegExp(r'\benter\s*\d{4,6}\s*to\s*(?:complete|proceed|login|reset|pura karein|aage badhein)', caseSensitive: false),
    RegExp(r'(?=.*\b(?:otp|code|pin|verification|gupt code)\b)(?!.*\b(?:debited|credited|transaction|amount|balance|rupees|rs|₹|winning|recharge|payment|paid|withdrawn|credited|successful|failed|bhugtan|prapt|katoti)\b)(?=.*\d{4,6})', caseSensitive: false),
  ];

  // --- Promotional Patterns (specific keywords for offers/ads) ---
  static final List<RegExp> _promotionalPatterns = [
    RegExp(r'congratulations.*you.*won.*(?:click|visit|jeet gaye|click karein)', caseSensitive: false),
    RegExp(r'pre-approved.*loan.*apply.*now|loan.*paayein', caseSensitive: false),
    RegExp(r'limited.*time.*offer.*(?:click|avail|grab).*here|simit samay ki peshkash|jaldi karein', caseSensitive: false),
    RegExp(r'download.*app.*get.*free|app download karein|muft mein paayein', caseSensitive: false),
    RegExp(r'visit.*website.*claim.*prize|website par jaakar inaam paayein', caseSensitive: false),
    RegExp(r'get.*\d+%.*cashback.*(?:download|activate|recharge).*|paayein.*\d+%.*cashback', caseSensitive: false),
    RegExp(r'discount|coupon|deal|sale|offer|chhoot|peshkash|prastav', caseSensitive: false),
    RegExp(r'recharge.*(?:plan|pack).*details.*(?:validity|data|talktime).*', caseSensitive: false),
    RegExp(r'kyc.*update|account.*block|link.*account|khata band|link karein', caseSensitive: false),
    RegExp(r'loan.*(?:approved| disbursed)|credit card.*(?:offer|limit)|credit card offer', caseSensitive: false),
    RegExp(r'earn.*money|invest.*now|trading.*tips|paise kamao|invest karein', caseSensitive: false),
    RegExp(r'bill bhugtan par apko', caseSensitive: false),
    RegExp(r'cashback(?:.*)?offer', caseSensitive: false),
    RegExp(r'get(?:.*)?loanr', caseSensitive: false),
    RegExp(r'is(?:.*)?due', caseSensitive: false),
    RegExp(r'is(?:.*)?overdue', caseSensitive: false),
    RegExp(r'apply(?:.*)', caseSensitive: false),
    RegExp(r'exclusive offer|special offer|maha bachat|big saving|discount code', caseSensitive: false),
    RegExp(r'valid till|expires on|limited period|hurry up|jaldi karein', caseSensitive: false),
    RegExp(r'click here|visit us|know more|apply now|download now|buy now', caseSensitive: false),
    RegExp(r'congratulations|you have won|inaam|lucky draw|jackpot', caseSensitive: false),
    RegExp(r'best deals|great offers|unbeatable price|kam daam', caseSensitive: false),
    RegExp(r'kyc pending|aadhaar link|update your profile|link your pan', caseSensitive: false),
    RegExp(r'free(?:bies)?|muft|complimentary|bonus points', caseSensitive: false),
    RegExp(r'app link|website link|url\.com|bit\.ly', caseSensitive: false),
    RegExp(r'unlimited|data pack|talktime pack|best plan', caseSensitive: false),
    RegExp(r'subscribe|unsubscribe|opt out|stop sms', caseSensitive: false),
    RegExp(r'(?:your|apka)\s*(?:account|khata).*?(?:block|freeze|suspended|band kar diya gaya)', caseSensitive: false),
    RegExp(r'loan\s*apply|credit card\s*offer|pre-approved', caseSensitive: false),
    RegExp(r'emi\s*option|no cost emi|easy emi', caseSensitive: false),
    RegExp(r'earn\s*money|invest\s*now|trade\s*online|refer\s*and\s*earn', caseSensitive: false),
    RegExp(r'validate\s*your\s*details|verify\s*your\s*otp', caseSensitive: false),
    RegExp(r'last day|ending soon', caseSensitive: false),
    RegExp(r'reward points|cashback\s*offer|get\s*discount', caseSensitive: false),
    RegExp(r'activate\s*(?:offer|plan|service)', caseSensitive: false),
    RegExp(r'customer care|helpline number', caseSensitive: false),
    RegExp(r'visit\s*(?:our|us)\s*(?:store|branch)', caseSensitive: false),
    RegExp(r'\d+%\s*off|\d+\s*rs\s*cashback', caseSensitive: false),
    RegExp(r'open\s*demat\s*account|trading\s*account', caseSensitive: false),
    RegExp(r'online\s*course|learning\s*platform', caseSensitive: false),
    RegExp(r'new\s*collection|latest\s*fashion', caseSensitive: false),
    RegExp(r'shop\s*now|explore\s*products', caseSensitive: false),
    RegExp(r'delivery\s*update|order\s*shipped|out\s*for\s*delivery', caseSensitive: false),
    RegExp(r'payment\s*failed.*(?:retry|try again)|transaction\s*declined', caseSensitive: false),
    RegExp(r'(?:.*)?rummy', caseSensitive: false),
    RegExp(r'(?:.*)?download', caseSensitive: false),
    RegExp(r'(?:.*)?register(?:.*)', caseSensitive: false),
  ];

  // --- Strong Transaction Indicators (confirm real money movement) ---
  static final List<RegExp> _strongTransactionIndicators = [
    RegExp(r'(?:a\/c|account|acct|khata).*?(?:debited|credited|has been|is|hua|kat gaya|jamma hua)', caseSensitive: false),
    RegExp(r'(?:debited|credited|cut|jamma).*?(?:from|to|se|ko)\s*(?:your|apka)?\s*(?:a\/c|account|khata)', caseSensitive: false),
    RegExp(r'account\s*(?:no|number|num)\s*X{2,}\d{4}', caseSensitive: false),
    RegExp(r'\b(?:savings|current|wallet)\s*a\/c\b', caseSensitive: false),
    RegExp(r'(?:ref|reference|txn|transaction)\s*(?:id|no|number|num|sandarbh|pehchan)\s*[:=]?\s*[A-Z0-9]{6,}', caseSensitive: false),
    RegExp(r'transaction.*(?:successful|completed|failed|initiated|safal|poora|asanfal)', caseSensitive: false),
    RegExp(r'(?:available|avbl|current|remaining|updated|shesh|baaki).*balance|(?:rupya|rs\.?|₹).*baaki', caseSensitive: false),
    RegExp(r'balance.*(?:is|:|hai)\s*(?:INR|Rs\.?|₹)?\s*\d{1,3}(?:,\d{3})*(?:\.\d{1,2})?', caseSensitive: false),
    RegExp(r'UPI\s*(?:ref|id|txn|sandarbh)\s*[:=]?\s*[0-9.]+|(?:from|to|se|ko)\s*UPI\s*(?:id|account|khata)', caseSensitive: false),
    RegExp(r'VPA:\s*[\w.-]+@[\w.-]+', caseSensitive: false),
    RegExp(r'card.*(?:ending|last|aakhiri)\s*\d{4}', caseSensitive: false),
    RegExp(r'card.*(?:xx|X{2,4})\d{4}', caseSensitive: false),
    RegExp(r'(?:credit|debit)\s*card.*(?:purchase|payment|transaction|kharid|bhugtan)', caseSensitive: false),
    RegExp(r'(?:on|dated|ko)\s*\d{1,2}[-/]\d{1,2}[-/]\d{2,4}', caseSensitive: false),
    RegExp(r'(?:at|time|samay)\s*\d{1,2}:\d{2}(?::\d{2})?\s*(?:AM|PM)?', caseSensitive: false),
    RegExp(r'(?:at|to|from|for|via|par|ko|se|ke liye)\s*[A-Z][A-Z0-9\s.,&/-]{2,}', caseSensitive: false),
    RegExp(r'(?:NEFT|RTGS|IMPS|UPI|POS|ATM|EMI|BHIM)', caseSensitive: false),
    RegExp(r'(?!.*(?:otp|code|pin|verification|gupt code))', caseSensitive: false),
  ];

  /// Extracts all numerical amounts from a message string.
  /// Returns a list of parsed double values.
  static List<double> extractAllAmounts(String message) {
    List<double> amounts = [];
    for (final pattern in _amountPatterns) {
      final matches = pattern.allMatches(message);
      for (final match in matches) {
        String? amountStr = match.group(1);
        if (amountStr != null) {
          amountStr = amountStr.replaceAll(',', '');
          double? amount = double.tryParse(amountStr);
          if (amount != null && amount > 0) {
            amounts.add(amount);
          }
        }
      }
    }
    return amounts.toSet().toList();
  }

  /// Extracts the most relevant source (bank, telecom, merchant) from the message or address.
  static String? extractSource(String message, String address) {
    String combinedText = '$address $message';
    for (final pattern in _sourcePatterns) {
      final match = pattern.firstMatch(combinedText);
      if (match != null) {
        return match.group(1)?.toUpperCase() ?? match.group(0)?.toUpperCase();
      }
    }
    return null;
  }

  /// Extracts a brief description for the transaction based on keywords.
  static String? extractDescription(String message, String type) {
    String lowerMessage = message.toLowerCase();

    if (type == 'debit') {
      if (lowerMessage.contains('recharge')) return 'Mobile Recharge/Plan Activation';
      if (lowerMessage.contains('bill paid') || lowerMessage.contains('utility') || lowerMessage.contains('bhugtan')) return 'Bill Payment';
      if (lowerMessage.contains('purchase') || lowerMessage.contains('spent') || lowerMessage.contains('paid') || lowerMessage.contains('kharid')) {
        final merchantMatch = RegExp(r'(?:for|at|to|par|ko|se)\s*([A-Z][A-Z0-9\s.&/-]{2,})', caseSensitive: false).firstMatch(message);
        if (merchantMatch != null) {
          return 'Purchase at ${merchantMatch.group(1)?.trim()}';
        }
        return 'General Purchase/Payment';
      }
      if (lowerMessage.contains('atm withdrawal') || lowerMessage.contains('nikala')) return 'ATM Withdrawal';
      if (lowerMessage.contains('pos transaction')) return 'POS Transaction';
      if (lowerMessage.contains('upi') || lowerMessage.contains('bhim')) return 'UPI Payment';
      if (lowerMessage.contains('emi')) return 'EMI Payment';
      if (lowerMessage.contains('online payment')) return 'Online Payment';
      if (lowerMessage.contains('transfer') || lowerMessage.contains('bheja')) return 'Fund Transfer';
      if (lowerMessage.contains('charged') || lowerMessage.contains('kat gaya')) return 'Service Charge/Fee';
    }
    else if (type == 'credit') {
      if (lowerMessage.contains('salary') || lowerMessage.contains('vetan')) return 'Salary Credit';
      if (lowerMessage.contains('refund') || lowerMessage.contains('wapas')) return 'Refund Received';
      if (lowerMessage.contains('winning') || lowerMessage.contains('jeet')) return 'Game/Contest Winnings';
      if (lowerMessage.contains('cashback') || lowerMessage.contains('chhoot')) return 'Cashback';
      if (lowerMessage.contains('bonus')) return 'Bonus Received';
      if (lowerMessage.contains('upi') || lowerMessage.contains('bhim')) return 'UPI Received';
      if (lowerMessage.contains('imps') || lowerMessage.contains('neft') || lowerMessage.contains('rtgs') || lowerMessage.contains('transfer')) return 'Bank Transfer Received';
      if (lowerMessage.contains('deposit') || lowerMessage.contains('jamma')) return 'Cash/Cheque Deposit';
    }

    return '$type Transaction';
  }

  /// Parses a single SMS message and returns a list of Transaction objects.
  static List<Transaction> parseTransaction(Map<String, dynamic> smsData) {
    try {
      final String message = smsData['body']?.toString() ?? '';
      final String address = smsData['address']?.toString() ?? '';
      int timestamp;
      if (smsData['date'] is int) {
        timestamp = smsData['date'];
      } else if (smsData['date'] is String) {
        timestamp = int.tryParse(smsData['date']) ?? DateTime.now().millisecondsSinceEpoch;
      } else {
        timestamp = DateTime.now().millisecondsSinceEpoch;
      }

      if (message.isEmpty) return [];

      print('\n📱 Analyzing: ${message.substring(0, min(120, message.length))}...');

      bool isOTP = _otpPatterns.any((pattern) => pattern.hasMatch(message));
      if (isOTP) {
        print('❌ Filtered: OTP message');
        return [];
      }

      bool hasStrongIndicators = _strongTransactionIndicators.any((pattern) => pattern.hasMatch(message));
      print('     ✨ Strong transaction indicators: $hasStrongIndicators');

      bool isPromotional = _promotionalPatterns.any((pattern) => pattern.hasMatch(message));
      print('     📢 Promotional patterns found: $isPromotional');

      if (isPromotional && !hasStrongIndicators) {
        print('❌ Filtered: Identified as purely promotional (no strong transaction indicators)');
        return [];
      }

      List<double> amounts = extractAllAmounts(message);
      print('     💰 Amounts found: $amounts');

      if (amounts.isEmpty && !hasStrongIndicators) {
        print('❌ No valid amounts found and no strong transaction indicators. Filtering.');
        return [];
      }

      if (amounts.isNotEmpty && amounts.every((a) => a < 1.0) && !hasStrongIndicators) {
          print('❌ Amounts are too small and no strong transaction indicators. Filtering.');
          return [];
      }

      bool isDebit = _debitPatterns.any((pattern) => pattern.hasMatch(message));
      bool isCredit = _creditPatterns.any((pattern) => pattern.hasMatch(message));

      print('     🔍 Debit patterns found: $isDebit');
      print('     🔍 Credit patterns found: $isCredit');

      if (!isDebit && !isCredit) {
        if (amounts.isNotEmpty && !hasStrongIndicators) {
          print('❌ Amounts found but no debit/credit patterns and no strong indicators. Filtering.');
          return [];
        }
        if (amounts.isEmpty && hasStrongIndicators) {
             print('❌ Strong indicators present, but no amounts and no debit/credit patterns. Filtering as not a transaction.');
             return [];
        }
      }

      List<Transaction> transactions = [];
      DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp);
      String? source = extractSource(message, address);

      if (isDebit && isCredit) {
        print('     📊 Both debit and credit patterns found. Attempting to parse dual transactions.');
        String lowerMessage = message.toLowerCase();

        if (lowerMessage.contains('recharge')) {
          amounts.sort((a, b) => b.compareTo(a));
          if (amounts.length >= 1) {
            transactions.add(Transaction(
              type: 'debit',
              amount: amounts[0],
              date: date,
              message: message,
              source: source?.toUpperCase() ?? extractSource(message, 'recharge')?.toUpperCase(),
              description: extractDescription(message, 'debit'),
            ));
          }
          if (amounts.length >= 2) {
            transactions.add(Transaction(
              type: 'credit',
              amount: amounts[1],
              date: date,
              message: message,
              source: source?.toUpperCase() ?? extractSource(message, 'winning')?.toUpperCase(),
              description: extractDescription(message, 'credit'),
            ));
          }
        } else {
          RegExp specificDebit = RegExp(r'(?:debited|paid|cut|kata).*?(?:INR|Rs\.?|₹)?\s*(\d{1,3}(?:,\d{3})*(?:\.\d{1,2})?)', caseSensitive: false);
          RegExp specificCredit = RegExp(r'(?:credited|received|prapt).*?(?:INR|Rs\.?|₹)?\s*(\d{1,3}(?:,\d{3})*(?:\.\d{1,2})?)', caseSensitive: false);

          double? debitAmount;
          double? creditAmount;

          var debitMatch = specificDebit.firstMatch(message);
          if (debitMatch != null) {
            debitAmount = double.tryParse(debitMatch.group(1)?.replaceAll(',', '') ?? '');
          }
          var creditMatch = specificCredit.firstMatch(message);
          if (creditMatch != null) {
            creditAmount = double.tryParse(creditMatch.group(1)?.replaceAll(',', '') ?? '');
          }

          if (debitAmount != null && debitAmount > 0) {
            transactions.add(Transaction(
              type: 'debit',
              amount: debitAmount,
              date: date,
              message: message,
              source: source?.toUpperCase(),
              description: extractDescription(message, 'debit'),
            ));
          }
          if (creditAmount != null && creditAmount > 0 && creditAmount != debitAmount) {
            transactions.add(Transaction(
              type: 'credit',
              amount: creditAmount,
              date: date,
              message: message,
              source: source?.toUpperCase(),
              description: extractDescription(message, 'credit'),
            ));
          }

          if (transactions.isEmpty && amounts.length >= 2) {
              amounts.sort((a, b) => b.compareTo(a));
              transactions.add(Transaction(
                type: 'debit',
                amount: amounts[0],
                date: date,
                message: message,
                source: source?.toUpperCase(),
                description: extractDescription(message, 'debit'),
              ));
              transactions.add(Transaction(
                type: 'credit',
                amount: amounts[1],
                date: date,
                message: message,
                source: source?.toUpperCase(),
                description: extractDescription(message, 'credit'),
              ));
          } else if (transactions.isEmpty && amounts.isNotEmpty) {
              if (message.toLowerCase().contains('debited') || message.toLowerCase().contains('paid')) {
                  transactions.add(Transaction(
                    type: 'debit',
                    amount: amounts[0],
                    date: date,
                    message: message,
                    source: source?.toUpperCase(),
                    description: extractDescription(message, 'debit'),
                  ));
              } else if (message.toLowerCase().contains('credited') || message.toLowerCase().contains('received')) {
                  transactions.add(Transaction(
                    type: 'credit',
                    amount: amounts[0],
                    date: date,
                    message: message,
                    source: source?.toUpperCase(),
                    description: extractDescription(message, 'credit'),
                  ));
              }
          }
        }
      }
      else if (isDebit) {
        for (double amount in amounts) {
          transactions.add(Transaction(
            type: 'debit',
            amount: amount,
            date: date,
            message: message,
            source: source?.toUpperCase(),
            description: extractDescription(message, 'debit'),
          ));
        }
      }
      else if (isCredit) {
        for (double amount in amounts) {
          transactions.add(Transaction(
            type: 'credit',
            amount: amount,
            date: date,
            message: message,
            source: source?.toUpperCase(),
            description: extractDescription(message, 'credit'),
          ));
        }
      }

      List<Transaction> validTransactions = [];
      for (Transaction transaction in transactions) {
        bool shouldKeep = transaction.amount > 0 &&
            (transaction.source != null || hasStrongIndicators || isDebit || isCredit);

        if (shouldKeep) {
          validTransactions.add(transaction);
          print('✅ Valid transaction: ${transaction.type.toUpperCase()} ₹${transaction.amount} from ${transaction.source ?? 'Unknown'} (Description: ${transaction.description ?? 'N/A'})');
        } else {
          print('⚠️ Filtered weak/miscellaneous transaction (no strong source/indicators): ${transaction.type.toUpperCase()} ₹${transaction.amount}');
        }
      }

      return validTransactions;
    } catch (e) {
      print('❌ Error parsing transaction: $e');
      return [];
    }
  }

  /// Parses a list of SMS messages and returns all detected transactions.
  static Future<List<Transaction>> parseAllMessages(List<Map<String, dynamic>> messages) async {
    List<Transaction> allTransactions = [];
    int totalMessages = messages.length;
    int messagesWithTransactions = 0;

    print('=== 🚀 Starting SMS Analysis ===');
    print('Total SMS messages to analyze: $totalMessages');

    for (int i = 0; i < messages.length; i++) {
      Map<String, dynamic> message = messages[i];
      try {
        print('\n--- 📝 Message ${i + 1}/${totalMessages} ---');
        final transactions = parseTransaction(message);
        if (transactions.isNotEmpty) {
          allTransactions.addAll(transactions);
          messagesWithTransactions++;
        }
      } catch (e) {
        print('❌ Error parsing message ${i + 1}: $e');
        continue;
      }
    }

    print('\n=== 📊 SMS Analysis Complete ===');
    print('- Total SMS messages: $totalMessages');
    print('- Messages with transactions: $messagesWithTransactions');
    print('- Total transactions found: ${allTransactions.length}');
    print('- Messages filtered out: ${totalMessages - messagesWithTransactions}');
    print('- Success rate: ${totalMessages > 0 ? ((messagesWithTransactions / totalMessages) * 100).toStringAsFixed(1) : '0.0'}%');

    int debits = allTransactions.where((t) => t.type == 'debit').length;
    int credits = allTransactions.where((t) => t.type == 'credit').length;
    double totalDebitAmount = allTransactions.where((t) => t.type == 'debit').fold(0.0, (sum, t) => sum + t.amount);
    double totalCreditAmount = allTransactions.where((t) => t.type == 'credit').fold(0.0, (sum, t) => sum + t.amount);

    print('- Debit transactions: $debits (₹${totalDebitAmount.toStringAsFixed(2)})');
    print('- Credit transactions: $credits (₹${totalCreditAmount.toStringAsFixed(2)})');

    Map<String, int> sourceCount = {};
    for (Transaction t in allTransactions) {
      String source = t.source ?? 'Unknown';
      sourceCount[source] = (sourceCount[source] ?? 0) + 1;
    }

    print('- Transactions by source:');
    if (sourceCount.isEmpty) {
      print('   • None');
    } else {
      sourceCount.forEach((source, count) {
        print('   • $source: $count transactions');
      });
    }

    return allTransactions;
  }
}

class HomePage extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;
  final ThemeMode currentThemeMode;
  final Function(Color) onSeedColorChanged; // Callback for seed color change
  final Color currentSeedColor; // Current seed color

  const HomePage({
    super.key,
    required this.onThemeChanged,
    required this.currentThemeMode,
    required this.onSeedColorChanged,
    required this.currentSeedColor,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  List<Transaction> transactions = [];
  bool isLoading = false;
  String selectedPeriod = 'This Month';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadTransactions();
    _tabController.addListener(() {
      if (_tabController.index == 1) {
        _loadTransactions();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Requests SMS permission, reads, parses, and saves transactions to the database.
  Future<void> _requestPermissionAndReadSMS() async {
    setState(() => isLoading = true);

    try {
      final status = await Permission.sms.request();
      if (status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reading and analyzing SMS messages...'),
              duration: Duration(seconds: 3),
              backgroundColor: Colors.blueAccent,
            ),
          );
        }
        final messages = await SMSReader.readSMS();
        print('Retrieved ${messages.length} SMS messages');

        final parsedTransactions = await TransactionParser.parseAllMessages(messages);

        await DatabaseHelper.clearAllTransactions(); // Clear existing to prevent duplicates
        for (final transaction in parsedTransactions) {
          try {
            await DatabaseHelper.insertTransaction(transaction);
          } catch (e) {
            print('Error inserting transaction: $e');
          }
        }

        await _loadTransactions(); // Reload transactions for current view

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Analyzed ${parsedTransactions.length} transactions. Total in DB: ${transactions.length}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('SMS permission denied. Cannot read messages.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error in _requestPermissionAndReadSMS: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  /// Loads transactions from the database based on the selected period.
  /// This now uses the DatabaseHelper's date filtering capability.
  Future<void> _loadTransactions() async {
    final now = DateTime.now();
    DateTime? startDate;
    DateTime? endDate = DateTime(now.year, now.month, now.day, 23, 59, 59, 999); // End of today

    switch (selectedPeriod) {
      case 'Today':
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case 'This Week':
        startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
        break;
      case 'This Month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'This Year':
        startDate = DateTime(now.year, 1, 1);
        break;
      default:
        // No specific date filter for "All Time" or unrecognized period
        startDate = null;
        endDate = null;
        break;
    }

    final fetchedTransactions = await DatabaseHelper.getTransactions(
      startDate: startDate,
      endDate: endDate,
    );
    print('DEBUG: _loadTransactions() loaded ${fetchedTransactions.length} transactions for period "$selectedPeriod" from DB.');
    if (mounted) {
      setState(() {
        transactions = fetchedTransactions;
      });
    }
  }

  /// Calculates total amount for a given transaction type for the currently loaded transactions.
  double _getTotalAmount(String type) {
    return transactions
        .where((t) => t.type == type)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalCredit = _getTotalAmount('credit');
    final totalDebit = _getTotalAmount('debit');
    final balance = totalCredit - totalDebit;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Knom - Know Your Money'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: isLoading ? null : _requestPermissionAndReadSMS,
            tooltip: 'Refresh & Analyze SMS',
            icon: isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.onPrimary),
                    ),
                  )
                : const Icon(Icons.sync),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.onPrimary,
          labelColor: theme.colorScheme.onPrimary,
          unselectedLabelColor: theme.colorScheme.onPrimary.withOpacity(0.7),
          indicatorWeight: 4,
          tabs: const [
            Tab(text: 'Dashboard', icon: Icon(Icons.dashboard)),
            Tab(text: 'Charts', icon: Icon(Icons.bar_chart)),
            Tab(text: 'Transactions', icon: Icon(Icons.list_alt)),
            Tab(text: 'Settings', icon: Icon(Icons.settings)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDashboard(theme, totalCredit, totalDebit, balance),
          _buildChartsTab(theme, transactions),
          _buildTransactionsTab(theme, transactions),
          _buildSettingsTab(theme),
        ],
      ),
    );
  }

  Widget _buildDashboard(ThemeData theme, double totalCredit, double totalDebit, double balance) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildPeriodSelector(theme),
          const SizedBox(height: 16),
          _buildSummaryCards(theme, totalCredit, totalDebit, balance),
          const SizedBox(height: 24),
          _buildQuickStats(theme),
          const SizedBox(height: 24),
          _buildRecentTransactionsSnippet(theme),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: ['Today', 'This Week', 'This Month', 'This Year']
            .map((period) => Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedPeriod = period;
                      });
                      _loadTransactions();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      decoration: BoxDecoration(
                        color: selectedPeriod == period
                            ? theme.colorScheme.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        period,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: selectedPeriod == period
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight: selectedPeriod == period
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildSummaryCards(ThemeData theme, double totalCredit, double totalDebit, double balance) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildThemedSummaryCard(
                theme,
                'Income',
                '₹${totalCredit.toStringAsFixed(2)}',
                Colors.green.shade600,
                Icons.arrow_circle_up,
                theme.colorScheme.secondaryContainer,
                theme.colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildThemedSummaryCard(
                theme,
                'Expenses',
                '₹${totalDebit.toStringAsFixed(2)}',
                Colors.red.shade600,
                Icons.arrow_circle_down,
                theme.colorScheme.errorContainer,
                theme.colorScheme.onErrorContainer,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildThemedSummaryCard(
          theme,
          'Net Balance',
          '₹${balance.toStringAsFixed(2)}',
          balance >= 0 ? Colors.green.shade600 : Colors.red.shade600,
          balance >= 0 ? Icons.account_balance_wallet : Icons.warning,
          balance >= 0 ? theme.colorScheme.primaryContainer : theme.colorScheme.errorContainer,
          balance >= 0 ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onErrorContainer,
        ),
      ],
    );
  }

  Widget _buildThemedSummaryCard(
      ThemeData theme, String title, String amount, Color iconColor, IconData icon, Color cardColor, Color textColor) {
    return Card(
      color: cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                amount,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(ThemeData theme) {
    final totalTransactions = transactions.length;
    final totalAmount = transactions.fold(0.0, (sum, t) => sum + t.amount);
    final avgTransaction = totalTransactions > 0 ? totalAmount / totalTransactions : 0.0;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overview for ${selectedPeriod}',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Divider(height: 24),
            _buildStatRow(theme, 'Total Transactions', '$totalTransactions', Icons.format_list_numbered),
            const SizedBox(height: 12),
            _buildStatRow(theme, 'Avg. Transaction Value', '₹${avgTransaction.toStringAsFixed(2)}', Icons.payments),
            const SizedBox(height: 12),
            _buildStatRow(theme, 'Total Volume', '₹${totalAmount.toStringAsFixed(2)}', Icons.toll),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(ThemeData theme, String title, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
        ),
      ],
    );
  }

  Widget _buildRecentTransactionsSnippet(ThemeData theme) {
    if (transactions.isEmpty) {
      return const SizedBox();
    }

    final recentTransactions = transactions.take(3).toList();

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Transactions',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Divider(height: 24),
            ...recentTransactions.map((transaction) {
              final isCredit = transaction.type == 'credit';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Icon(
                      isCredit ? Icons.add_circle : Icons.remove_circle,
                      color: isCredit ? Colors.green : Colors.red,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            transaction.description ?? 'Transaction',
                            style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${transaction.date.day}/${transaction.date.month} ${transaction.date.hour}:${transaction.date.minute.toString().padLeft(2, '0')}',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '₹${transaction.amount.toStringAsFixed(2)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isCredit ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            if (transactions.length > 3)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    _tabController.animateTo(2);
                  },
                  child: Text(
                    'View All (${transactions.length})',
                    style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartsTab(ThemeData theme, List<Transaction> filteredTransactions) {
    if (filteredTransactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              size: 80,
              color: theme.colorScheme.outline.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No transactions to display charts for this period.',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different period or refresh data.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildPieChart(theme, filteredTransactions),
          const SizedBox(height: 24),
          _buildBarChart(theme, filteredTransactions),
        ],
      ),
    );
  }

  Widget _buildPieChart(ThemeData theme, List<Transaction> filteredTransactions) {
    final totalCredit = filteredTransactions.where((t) => t.type == 'credit').fold(0.0, (sum, t) => sum + t.amount);
    final totalDebit = filteredTransactions.where((t) => t.type == 'debit').fold(0.0, (sum, t) => sum + t.amount);

    if (totalCredit == 0 && totalDebit == 0) return const SizedBox();

    List<PieChartSectionData> sections = [];
    if (totalCredit > 0) {
      sections.add(
        PieChartSectionData(
          value: totalCredit,
          title: '₹${totalCredit.toStringAsFixed(0)}',
          color: Colors.green.shade500,
          radius: 80,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          badgeWidget: Icon(Icons.arrow_upward, color: Colors.white, size: 20),
          badgePositionPercentageOffset: 1.05,
        ),
      );
    }
    if (totalDebit > 0) {
      sections.add(
        PieChartSectionData(
          value: totalDebit,
          title: '₹${totalDebit.toStringAsFixed(0)}',
          color: Colors.red.shade500,
          radius: 80,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          badgeWidget: Icon(Icons.arrow_downward, color: Colors.white, size: 20),
          badgePositionPercentageOffset: 1.05,
        ),
      );
    }

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Income vs Expenses',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 50,
                  sectionsSpace: 2,
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          return;
                        }
                        // Handle touch interaction if needed
                      });
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(Colors.green.shade500, 'Income'),
                const SizedBox(width: 20),
                _buildLegendItem(Colors.red.shade500, 'Expenses'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }

  Widget _buildBarChart(ThemeData theme, List<Transaction> filteredTransactions) {
    Map<String, double> dailyData = {};
    for (final transaction in filteredTransactions) {
      final dateKey = '${transaction.date.day}/${transaction.date.month}';
      dailyData[dateKey] = (dailyData[dateKey] ?? 0) + transaction.amount;
    }

    if (dailyData.isEmpty) return const SizedBox();

    final sortedEntries = dailyData.entries.toList()
      ..sort((a, b) {
        final now = DateTime.now();
        final aParts = a.key.split('/');
        final bParts = b.key.split('/');

        // Add current year for sorting purposes if month/day only
        DateTime aDate = DateTime(now.year, int.parse(aParts[1]), int.parse(aParts[0]));
        DateTime bDate = DateTime(now.year, int.parse(bParts[1]), int.parse(bParts[0]));

        return aDate.compareTo(bDate);
      });

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Daily Transaction Volume',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  barGroups: sortedEntries.asMap().entries.map((entry) {
                    final index = entry.key;
                    final data = entry.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: data.value,
                          color: theme.colorScheme.primary,
                          width: 18,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '₹${value.toInt()}',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < sortedEntries.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                sortedEntries[index].key,
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  alignment: BarChartAlignment.spaceEvenly,
                  maxY: dailyData.values.isEmpty ? 100 : dailyData.values.reduce(max) * 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsTab(ThemeData theme, List<Transaction> filteredTransactions) {
    if (filteredTransactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 80,
              color: theme.colorScheme.outline.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No transactions found for this period.',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the refresh button to analyze SMS messages.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredTransactions.length,
      itemBuilder: (context, index) {
        final transaction = filteredTransactions[index];
        final isCredit = transaction.type == 'credit';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: theme.colorScheme.surface,
          child: InkWell(
            onTap: () {
              _showTransactionDetails(context, transaction);
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isCredit
                              ? Colors.green.shade100
                              : Colors.red.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                          color: isCredit ? Colors.green.shade700 : Colors.red.shade700,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              transaction.description ?? 'General Transaction',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${transaction.date.day}/${transaction.date.month}/${transaction.date.year} ${transaction.date.hour}:${transaction.date.minute.toString().padLeft(2, '0')}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '₹${transaction.amount.toStringAsFixed(2)}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isCredit ? Colors.green.shade700 : Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                  if (transaction.source != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: Chip(
                          label: Text(
                            transaction.source!,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          backgroundColor: theme.colorScheme.primaryContainer,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showTransactionDetails(BuildContext context, Transaction transaction) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            transaction.type == 'credit' ? 'Income Details' : 'Expense Details',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: transaction.type == 'credit' ? Colors.green.shade700 : Colors.red.shade700,
            ),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                _buildDetailRow(theme, 'Amount', '₹${transaction.amount.toStringAsFixed(2)}', Colors.transparent),
                _buildDetailRow(theme, 'Type', transaction.type.toUpperCase(), Colors.transparent),
                _buildDetailRow(theme, 'Date', '${transaction.date.day}/${transaction.date.month}/${transaction.date.year}', Colors.transparent),
                _buildDetailRow(theme, 'Time', '${transaction.date.hour}:${transaction.date.minute.toString().padLeft(2, '0')}', Colors.transparent),
                if (transaction.source != null)
                  _buildDetailRow(theme, 'Source', transaction.source!, Colors.transparent),
                if (transaction.description != null)
                  _buildDetailRow(theme, 'Category', transaction.description!, Colors.transparent),
                const SizedBox(height: 16),
                Text('Original Message:', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(transaction.message, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close', style: TextStyle(color: theme.colorScheme.primary)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(ThemeData theme, String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(color: valueColor == Colors.transparent ? theme.colorScheme.onSurface : valueColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab(ThemeData theme) {
    // List of predefined colors for theme selection
    final List<Color> themeColors = [
      Colors.deepOrange,
      Colors.green,
      Colors.purple,
      Colors.teal,
      Colors.red,
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            elevation: 1,
            color: theme.colorScheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'App Theme',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const Divider(height: 24),
                  _buildThemeRadioListTile(theme, 'System Theme', Icons.brightness_auto, ThemeMode.system),
                  _buildThemeRadioListTile(theme, 'Light Theme', Icons.light_mode, ThemeMode.light),
                  _buildThemeRadioListTile(theme, 'Dark Theme', Icons.dark_mode, ThemeMode.dark),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 1,
            color: theme.colorScheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'App Accent Color',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const Divider(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: themeColors.map((color) {
                      return GestureDetector(
                        onTap: () {
                          widget.onSeedColorChanged(color);
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: widget.currentSeedColor == color
                                  ? theme.colorScheme.primary
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: widget.currentSeedColor == color
                              ? Icon(Icons.check, color: Colors.white)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 1,
            color: theme.colorScheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Data Management',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const Divider(height: 24),
                  ListTile(
                    leading: Icon(Icons.delete_forever, color: Colors.red.shade700),
                    title: Text('Clear All Data', style: theme.textTheme.titleMedium),
                    subtitle: Text('Remove all stored transactions from the app.', style: theme.textTheme.bodyMedium),
                    onTap: () => _showClearDataDialog(context),
                  ),
                  ListTile(
                    leading: Icon(Icons.info_outline, color: theme.colorScheme.primary),
                    title: Text('About Knom by devRanbir', style: theme.textTheme.titleMedium),
                    subtitle: Text('Learn more about this app.', style: theme.textTheme.bodyMedium),
                    onTap: () => _showAboutDialog(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeRadioListTile(ThemeData theme, String title, IconData icon, ThemeMode mode) {
    return RadioListTile<ThemeMode>(
      title: Text(title, style: theme.textTheme.titleMedium),
      secondary: Icon(icon, color: theme.colorScheme.primary),
      value: mode,
      groupValue: widget.currentThemeMode,
      onChanged: (ThemeMode? newMode) {
        if (newMode != null) {
          widget.onThemeChanged(newMode);
        }
      },
      activeColor: theme.colorScheme.primary,
      contentPadding: EdgeInsets.zero, // Remove default padding
    );
  }

  void _showClearDataDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Confirm Clear Data',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to clear all transaction data? This action cannot be undone.',
            style: theme.textTheme.bodyLarge,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
            ),
            FilledButton(
              onPressed: () async {
                await DatabaseHelper.clearAllTransactions();
                await _loadTransactions(); // Refresh the UI after clearing
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All transaction data cleared.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.of(context).pop();
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
              ),
              child: const Text('Clear Data'),
            ),
          ],
        );
      },
    );
  }

  void _showAboutDialog(BuildContext context) {
  final theme = Theme.of(context);

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          const SizedBox(width: 10),
          const Text('Knom - Know Your Money'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version 1.0.69',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'Knom is a smart expense tracker that analyzes your SMS messages to automatically categorize and track your financial transactions.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text('Features:', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            Text('• Automatic SMS parsing', style: theme.textTheme.bodyMedium),
            Text('• Transaction categorization', style: theme.textTheme.bodyMedium),
            Text('• Visual analytics (Charts)', style: theme.textTheme.bodyMedium),
            Text('• Multiple time period views', style: theme.textTheme.bodyMedium),
            Text('• Dark/Light Mode', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                '-By Yours DevRanbir',
                style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Close', style: TextStyle(color: theme.colorScheme.primary)),
        ),
      ],
    ),
  );
}

}