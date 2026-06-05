import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/models/user_model.dart';
import '../data/repositories/user_repository.dart';
import 'app_avatar.dart';

/// Caption TextField ke neeche mention suggestions dikhata hai
/// jab user '@' type kare
class MentionAutocomplete extends StatefulWidget {
  const MentionAutocomplete({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.hintText,
    this.maxLines = 4,
    this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  @override
  State<MentionAutocomplete> createState() => _MentionAutocompleteState();
}

class _MentionAutocompleteState extends State<MentionAutocomplete> {
  final UserRepository _userRepo = Get.find<UserRepository>();

  List<UserModel> _suggestions = [];
  bool _showSuggestions = false;
  String _currentMentionQuery = '';
  int _mentionStart = -1;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _debounce?.cancel();
    super.dispose();
  }

  void _onTextChanged() {
    final text = widget.controller.text;
    final selection = widget.controller.selection;

    if (!selection.isValid || selection.start < 0) {
      _hideSuggestions();
      return;
    }

    final cursorPos = selection.start;
    final textBeforeCursor = text.substring(0, cursorPos);

    // '@' ke baad ka current word dhundo
    final atIndex = textBeforeCursor.lastIndexOf('@');

    if (atIndex < 0) {
      _hideSuggestions();
      return;
    }

    // '@' ke baad space hai toh mention khatam ho gayi
    final afterAt = textBeforeCursor.substring(atIndex + 1);
    if (afterAt.contains(' ') || afterAt.contains('\n')) {
      _hideSuggestions();
      return;
    }

    // '@' se pehle space ya line start hona chahiye
    final charBeforeAt = atIndex > 0 ? textBeforeCursor[atIndex - 1] : ' ';
    if (charBeforeAt != ' ' && charBeforeAt != '\n') {
      _hideSuggestions();
      return;
    }

    _mentionStart = atIndex;
    _currentMentionQuery = afterAt;

    // Debounce — har keystroke pe search mat karo
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (_currentMentionQuery.isNotEmpty) {
        _searchUsers(_currentMentionQuery);
      } else {
        _hideSuggestions();
      }
    });
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) return;
    try {
      final results = await _userRepo.searchUsers(
        query: query,
        limit: 5,
        offset: 0,
      );
      if (!mounted) return;
      setState(() {
        _suggestions = results;
        _showSuggestions = results.isNotEmpty;
      });
    } catch (_) {}
  }

  void _hideSuggestions() {
    if (!mounted) return;
    setState(() {
      _showSuggestions = false;
      _suggestions = [];
    });
  }

  void _insertMention(UserModel user) {
    final text = widget.controller.text;
    final cursorPos = widget.controller.selection.start;

    if (_mentionStart < 0 || _mentionStart >= text.length) {
      _hideSuggestions();
      return;
    }

    // '@query' replace karo '@username '
    final before = text.substring(0, _mentionStart);
    final after = text.substring(cursorPos);
    final inserted = '$before@${user.username} $after';

    final newCursorPos = _mentionStart + user.username.length + 2; // '@' + username + space

    widget.controller.value = TextEditingValue(
      text: inserted,
      selection: TextSelection.collapsed(offset: newCursorPos),
    );

    _hideSuggestions();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          maxLines: widget.maxLines,
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: widget.hintText,
            border: InputBorder.none,
            hintStyle: TextStyle(color: theme.hintColor),
          ),
          onChanged: widget.onChanged,
        ),

        // Mention suggestions dropdown
        if (_showSuggestions)
          Container(
            constraints: const BoxConstraints(maxHeight: 220),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                top: BorderSide(color: theme.dividerColor),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final user = _suggestions[index];
                return InkWell(
                  onTap: () => _insertMention(user),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        AppAvatar(
                          radius: 18,
                          avatarUrl: user.avatarUrl,
                          iconSize: 18,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '@${user.username}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            if (user.name.isNotEmpty)
                              Text(
                                user.name,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
