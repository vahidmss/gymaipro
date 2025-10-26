import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ClientSearchWidget extends StatefulWidget {
  const ClientSearchWidget({
    required this.allClients,
    required this.onSearchResultsChanged,
    super.key,
  });
  final List<Map<String, dynamic>> allClients;
  final Function(List<Map<String, dynamic>>) onSearchResultsChanged;

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
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'جستجو در شاگردان...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
              prefixIcon: const Icon(
                LucideIcons.search,
                color: AppTheme.goldColor,
              ),
              filled: false,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(color: AppTheme.goldColor),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12.w,
                vertical: 10.h,
              ),
            ),
          ),
        ),
        if (_searchController.text.isNotEmpty)
          IconButton(
            icon: const Icon(LucideIcons.x, color: AppTheme.goldColor),
            onPressed: _searchController.clear,
          ),
      ],
    );
  }
}
