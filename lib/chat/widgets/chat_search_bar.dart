import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_theme.dart';

class ChatSearchBar extends StatefulWidget {
  final Function(String) onSearch;
  final String? hintText;

  const ChatSearchBar({
    Key? key,
    required this.onSearch,
    this.hintText,
  }) : super(key: key);

  @override
  State<ChatSearchBar> createState() => _ChatSearchBarState();
}

class _ChatSearchBarState extends State<ChatSearchBar> {
  final TextEditingController _controller = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: TextField(
        controller: _controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: widget.hintText ?? 'جستجو در گفتگوها...',
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            LucideIcons.search,
            color: Colors.white.withValues(alpha: 0.7),
            size: 20,
          ),
          suffixIcon: _isSearching
              ? IconButton(
                  icon: const Icon(
                    LucideIcons.x,
                    color: Colors.white70,
                    size: 20,
                  ),
                  onPressed: () {
                    _controller.clear();
                    setState(() => _isSearching = false);
                    widget.onSearch('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: (value) {
          setState(() => _isSearching = value.isNotEmpty);
          widget.onSearch(value);
        },
        onSubmitted: (value) {
          widget.onSearch(value);
        },
      ),
    );
  }
}
