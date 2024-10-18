import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; // สำหรับการจัดการรูปแบบวันที่

void main() {
  runApp(const ExpenseTrackerApp());
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'แอปแสดงรายจ่าย',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: GoogleFonts.promptTextTheme(),
      ),
      home: const ExpenseListScreen(),
    );
  }
}

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  _ExpenseListScreenState createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  List<Map<String, dynamic>> expenses = [];
  bool isLoading = true; // สถานะการโหลดข้อมูล

  @override
  void initState() {
    super.initState();
    loadExpenses();
  }

  // ดึงข้อมูลรายการจ่ายจาก SharedPreferences
  Future<void> loadExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final String? expensesJson = prefs.getString('expenses');
    if (expensesJson != null) {
      final List<dynamic> data = json.decode(expensesJson);
      setState(() {
        expenses = data.map((e) => e as Map<String, dynamic>).toList();
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  // ลบรายการจาก SharedPreferences
  Future<void> deleteExpense(int index) async {
    setState(() {
      expenses.removeAt(index); // ลบรายการจาก List
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('expenses', json.encode(expenses));
  }

  // ฟังก์ชันจัดรูปแบบวันที่
  String formatDate(String date) {
    final DateTime parsedDate = DateTime.parse(date);
    return DateFormat('dd/MM/yyyy').format(parsedDate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('แสดงรายจ่าย'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AddExpenseScreen()),
              ).then((_) => loadExpenses()); // โหลดข้อมูลใหม่หลังเพิ่ม
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : expenses.isEmpty
              ? const Center(child: Text('ไม่มีข้อมูลค่าใช้จ่าย'))
              : ListView.builder(
                  itemCount: expenses.length,
                  itemBuilder: (context, index) {
                    return Card(
                      child: ListTile(
                        leading: Image.asset('assets/image/money.png'),
                        title: Text(expenses[index]['title']),
                        subtitle: Text(
                            '฿${expenses[index]['amount']} ในวันที่ ${formatDate(expenses[index]['date'])}'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ExpenseDetailScreen(expense: expenses[index]),
                            ),
                          );
                        },
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => deleteExpense(index),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  _AddExpenseScreenState createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  // บันทึกรายการจ่ายลงใน SharedPreferences
  Future<void> _saveExpense() async {
    final String title = _titleController.text;
    final double amount = double.tryParse(_amountController.text) ?? 0.0;

    if (title.isEmpty || amount <= 0 || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบถ้วน')),
      );
      return;
    }

    final expense = {
      "title": title,
      "amount": amount,
      "date": _selectedDate!.toIso8601String(),
    };

    final prefs = await SharedPreferences.getInstance();
    final String? expensesJson = prefs.getString('expenses');
    List<dynamic> expenses = [];

    if (expensesJson != null) {
      expenses = json.decode(expensesJson);
    }

    expenses.add(expense);
    await prefs.setString('expenses', json.encode(expenses));

    // กลับไปยังหน้าก่อนหน้า
    // ignore: use_build_context_synchronously
    Navigator.pop(context);
  }

  // ฟังก์ชันเลือกวันที่
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // รีเซ็ตค่า
  void _resetFields() {
    setState(() {
      _titleController.clear();
      _amountController.clear();
      _selectedDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('เพิ่มรายการจ่าย'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration:
                  const InputDecoration(labelText: 'ชื่อรายการค่าใช้จ่าย'),
            ),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'จำนวนเงิน'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(_selectedDate == null
                    ? 'คุณยังไม่ได้เลือกวันที่'
                    : 'เลือกวันที่: ${DateFormat('dd/MM/yyyy').format(_selectedDate!)}'),
                TextButton(
                  onPressed: () => _selectDate(context),
                  child: const Text('เลือกวันที่'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _saveExpense,
                  child: const Text('เพิ่มรายการ'),
                ),
                OutlinedButton(
                  onPressed: _resetFields,
                  child: const Text('รีเซ็ต'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<TextEditingController>(
        '_titleController', _titleController));
  }
}

class ExpenseDetailScreen extends StatelessWidget {
  final Map<String, dynamic> expense;

  const ExpenseDetailScreen({super.key, required this.expense});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายละเอียดการจ่าย'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              expense['title'],
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Amount: ฿${expense['amount']}'),
            Text(
                'Date: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(expense['date']))}'),
          ],
        ),
      ),
    );
  }
}
