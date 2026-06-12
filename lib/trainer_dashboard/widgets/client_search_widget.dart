import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/utils/text_controller_utils.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ClientSearchWidget extends StatefulWidget {
  const ClientSearchWidget({
    required this.allClients,
    required this.onSearchResultsChanged,
    super.key,
  });
  final List<Map<String, dynamic>> allClients;
  final void Function(List<Map<String, dynamic>>) onSearchResultsChanged;

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
  void didUpdateWidget(ClientSearchWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.allClients != widget.allClients) {
      _filteredClients = widget.allClients;
      _performSearch();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() {
    if (!_searchController.isSafe) return;
    final query = _searchController.safeText.trim().toLowerCase();

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: isDark ? 0.15 : 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.15)
                : AppTheme.goldColor.withValues(alpha: 0.04),
            blurRadius: 6.r,
            offset: Offset(0, 2.h),
            spreadRadius: 0,
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(
          color: context.textColor,
          fontSize: 14.sp,
          fontFamily: AppTheme.fontFamily,
        ),
        decoration: InputDecoration(
          hintText: 'جستجو در شاگردان...',
          hintStyle: TextStyle(
            color: context.textSecondary.withValues(alpha: 0.6),
            fontSize: 14.sp,
            fontFamily: AppTheme.fontFamily,
          ),
          prefixIcon: Icon(
            LucideIcons.search,
            color: AppTheme.goldColor.withValues(alpha: 0.7),
            size: 18.sp,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    LucideIcons.x,
                    color: context.textSecondary,
                    size: 16.sp,
                  ),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          filled: true,
          fillColor: isDark
              ? context.cardColor.withValues(alpha: 0.5)
              : context.cardColor,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(color: AppTheme.goldColor, width: 1.5),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 12.h,
          ),
        ),
      ),
    );
  }
}
