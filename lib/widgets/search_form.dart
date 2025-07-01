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
  State<SearchForm> createState() => SearchFormState();
}

class SearchFormState extends State<SearchForm> {
  String? _selectedTrain;
  DateTime? _selectedDate = DateTime.now();
  bool _isExpanded = true;

  final TextEditingController _trainNumberController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  void _updateFields({String? trainNumber, DateTime? date, bool? expanded}) {
    setState(() {
      if (trainNumber != null) {
        _selectedTrain = trainNumber;
        _trainNumberController.text = trainNumber;
      }
      if (date != null) {
        _selectedDate = date;
        _dateController.text = DateFormat('EEEE, MMMM d, yyyy').format(date);
      }
      if (expanded != null) {
        _isExpanded = expanded;
      }
    });
  }

  void setFieldsAndSearch(String trainNumber, DateTime date) {
    _updateFields(trainNumber: trainNumber, date: date);
    _performSearch();
  }

  // === Lifecycle Methods ===
  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _updateFields(date: _selectedDate);
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
    if (savedTrainNumber?.isNotEmpty == true) {
      _updateFields(trainNumber: savedTrainNumber);
    }
  }

  Future<void> _savePreferences() async {
    if (_selectedTrain?.isNotEmpty == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('train_number', _selectedTrain!);
    }
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
      _updateFields(date: picked);
    }
  }

  Future<void> _performSearch() async {
    if (_selectedTrain?.isEmpty != false || _selectedDate == null) return;

    await _savePreferences();
    _updateFields(expanded: false);
    widget.onSearch(_selectedTrain!, _selectedDate!);
  }

  // === Widget Builders ===
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            _buildHeader(),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: double.infinity,
                child: _isExpanded
                    ? _buildFormFields()
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Row(
        children: [
          // Train info
          const Icon(Icons.train, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _isExpanded
                  ? 'Search Train'
                  : (_selectedTrain?.isNotEmpty == true
                        ? 'Train $_selectedTrain'
                        : 'No train selected'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),

          // Date info (only show when collapsed)
          if (!_isExpanded && _selectedDate != null) ...[
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

          // Refresh button (only show when collapsed and has data)
          if (!_isExpanded &&
              _selectedTrain?.isNotEmpty == true &&
              _selectedDate != null) ...[
            IconButton(
              onPressed: widget.isLoading ? null : _performSearch,
              icon: const Icon(Icons.refresh, size: 20),
              tooltip: 'Refresh train status',
            ),
          ],

          // Expand/Collapse arrow indicator
          IconButton(
            onPressed: () => _updateFields(expanded: !_isExpanded),
            icon: Icon(
              _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            ),
            tooltip: _isExpanded ? 'Collapse' : 'Expand',
          ),
        ],
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        // Train Number Input
        TextField(
          controller: _trainNumberController,
          onChanged: (value) => _updateFields(trainNumber: value),
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
          onPressed: widget.isLoading ? null : _performSearch,
          icon: const Icon(Icons.search),
          label: const Text('Search'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }
}
