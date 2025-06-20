import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchForm extends StatefulWidget {
  final Function(String trainNumber, DateTime date) onSearch;
  final bool isLoading;
  final bool hasResults;

  const SearchForm({
    super.key,
    required this.onSearch,
    required this.isLoading,
    this.hasResults = false,
  });

  @override
  State<SearchForm> createState() => _SearchFormState();
}

class _SearchFormState extends State<SearchForm> {
  final TextEditingController _trainNumberController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  DateTime? _selectedDate = DateTime.now();
  bool _isExpanded = true;

  // === Lifecycle Methods ===
  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _updateDateDisplay(_selectedDate!);
  }

  @override
  void didUpdateWidget(SearchForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isExpanded) {
      _expandForm();
    }
  }

  @override
  void dispose() {
    _trainNumberController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  // === Preferences Management ===
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTrainNumber = prefs.getString('train_number');

    if (savedTrainNumber != null && savedTrainNumber.isNotEmpty) {
      _trainNumberController.text = savedTrainNumber;
    }
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('train_number', _trainNumberController.text);
  }

  // === UI Helper Methods ===
  void _updateDateDisplay(DateTime date) {
    _dateController.text = DateFormat('EEEE, MMMM d, yyyy').format(date);
  }

  void _expandForm() {
    setState(() {
      _isExpanded = true;
    });
  }

  void _collapseForm() {
    setState(() {
      _isExpanded = false;
    });
  }

  // === User Interaction Handlers ===
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _updateDateDisplay(picked);
      });
    }
  }

  void _handleSearch() async {
    if (_trainNumberController.text.isEmpty || _selectedDate == null) {
      return;
    }

    _collapseForm();
    await _savePreferences();
    widget.onSearch(_trainNumberController.text, _selectedDate!);
  }

  // === Widget Builders ===
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: _isExpanded ? _buildExpandedForm() : _buildCollapsedHeader(),
      ),
    );
  }

  Widget _buildCollapsedHeader() {
    return InkWell(
      onTap: _expandForm,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            // Train info
            const Icon(Icons.train, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _trainNumberController.text.isNotEmpty
                    ? 'Train ${_trainNumberController.text}'
                    : 'No train selected',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),

            // Date info
            if (_selectedDate != null) ...[
              const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                DateFormat('MMM d').format(_selectedDate!),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(width: 12),
            ],

            // Down arrow indicator
            const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedForm() {
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
          icon: const Icon(Icons.search),
          label: const Text('Search Train Status'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }
}
