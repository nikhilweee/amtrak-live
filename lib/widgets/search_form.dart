import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchForm extends StatefulWidget {
  final Function(String trainNumber, DateTime date) onSearch;
  final bool isLoading;

  const SearchForm({
    super.key,
    required this.onSearch,
    required this.isLoading,
  });

  @override
  State<SearchForm> createState() => _SearchFormState();
}

class _SearchFormState extends State<SearchForm> {
  final TextEditingController _trainNumberController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  DateTime? _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTrainNumber = prefs.getString('train_number');

    if (savedTrainNumber != null && savedTrainNumber.isNotEmpty) {
      _trainNumberController.text = savedTrainNumber;
    }

    // Initialize date controller with today's date
    if (_selectedDate != null) {
      _dateController.text = DateFormat(
        'EEEE, MMMM d, yyyy',
      ).format(_selectedDate!);
    }
  }

  Future<void> _saveTrainNumber(String trainNumber) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('train_number', trainNumber);
  }

  @override
  void dispose() {
    _trainNumberController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('EEEE, MMMM d, yyyy').format(picked);
      });
    }
  }

  void _handleSearch() async {
    if (_trainNumberController.text.isEmpty || _selectedDate == null) {
      return;
    }

    // Save the train number for next time
    await _saveTrainNumber(_trainNumberController.text);

    widget.onSearch(_trainNumberController.text, _selectedDate!);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Train Number Input
        TextField(
          controller: _trainNumberController,
          decoration: const InputDecoration(
            labelText: 'Train Number',
            hintText: 'Enter train number (e.g., 91)',
            prefixIcon: Icon(Icons.train),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),

        // Date Picker
        TextField(
          controller: _dateController,
          readOnly: true,
          onTap: _selectDate,
          decoration: const InputDecoration(
            labelText: 'Departure Date',
            hintText: 'Select departure date',
            prefixIcon: Icon(Icons.calendar_today),
            suffixIcon: Icon(Icons.arrow_drop_down),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),

        // Search Button
        FilledButton.icon(
          onPressed: widget.isLoading ? null : _handleSearch,
          icon: widget.isLoading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.search),
          label: Text(
            widget.isLoading ? 'Searching...' : 'Search Train Status',
          ),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }
}
