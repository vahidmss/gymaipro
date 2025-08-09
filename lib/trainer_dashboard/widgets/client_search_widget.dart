import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ClientSearchWidget extends StatefulWidget {
  final List<Map<String, dynamic>> allClients;
  final Function(List<Map<String, dynamic>>) onSearchResultsChanged;

  const ClientSearchWidget({
    Key? key,
    required this.allClients,
    required this.onSearchResultsChanged,
  }) : super(key: key);

  @override
  State<ClientSearchWidget> createState() => _ClientSearchWidgetState();
}

class _ClientSearchWidgetState extends State<ClientSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredClients = [];

  @override
  void initState() {
    super.initState();
    _filteredClients = widget.allClients;
    _searchController.addListener(_performSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() {
    final query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      setState(() {
        _filteredClients = widget.allClients;
      });
    } else {
      setState(() {
        _filteredClients = widget.allClients.where((client) {
          final clientProfile = client['client'] as Map<String, dynamic>?;
          if (clientProfile == null) return false;

          final username =
              (clientProfile['username'] as String?)?.toLowerCase() ?? '';
          final firstName =
              (clientProfile['first_name'] as String?)?.toLowerCase() ?? '';
          final lastName =
              (clientProfile['last_name'] as String?)?.toLowerCase() ?? '';
          final bio = (clientProfile['bio'] as String?)?.toLowerCase() ?? '';

          return username.contains(query) ||
              firstName.contains(query) ||
              lastName.contains(query) ||
              bio.contains(query);
        }).toList();
      });
    }

    widget.onSearchResultsChanged(_filteredClients);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'جستجو در شاگردان...',
                hintStyle: TextStyle(color: Colors.amber),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                prefixIcon: Icon(LucideIcons.search, color: Colors.amber),
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(LucideIcons.x, color: Colors.amber),
              onPressed: () {
                _searchController.clear();
              },
            ),
        ],
      ),
    );
  }
}
