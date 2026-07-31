import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Global, reusable agent-selection dropdown.
///
/// Drop this into ANY screen that needs to pick an agent — Cash Handover,
/// Collections, Loans, Route Map, Customer assignment, etc. — without
/// duplicating the dropdown UI code in every screen.
///
/// It's generic over [T] so it works with whatever "agent option" model
/// each feature already has (e.g. `HandoverAgentOption`, `CollectionAgent`,
/// `RouteAgent`...). You just tell it how to read an id/label/active flag
/// from your model via [idOf] / [labelOf] / [isActiveOf]. No shared base
/// class required, so it won't force you to refactor existing models.
///
/// Example usage (Cash Handover screen):
/// ```dart
/// AgentDropdown<HandoverAgentOption>(
///   items: widget.agents,
///   idOf: (a) => a.id,
///   labelOf: (a) => a.name,
///   isActiveOf: (a) => a.active,
///   value: _selectedAgent,
///   enabled: widget.canChooseAgent,
///   onChanged: (v) => setState(() => _selectedAgent = v),
///   validator: (v) => v == null ? 'Select an agent' : null,
/// )
/// ```
class AgentDropdown<T> extends StatelessWidget {
  const AgentDropdown({
    super.key,
    required this.items,
    required this.idOf,
    required this.labelOf,
    this.isActiveOf,
    this.value,
    this.onChanged,
    this.label = 'AGENT',
    this.hintText = 'Select an agent',
    this.enabled = true,
    this.validator,
    this.showRequiredMark = true,
  });

  /// The full list of selectable agents.
  final List<T> items;

  /// Returns a stable unique id for an item (used for equality/lookup).
  final String Function(T item) idOf;

  /// Returns the display label for an item.
  final String Function(T item) labelOf;

  /// Optional: returns whether the agent is currently active. Inactive
  /// agents are still selectable but shown in muted text.
  final bool Function(T item)? isActiveOf;

  /// Currently selected item. Must be an item present in [items]
  /// (by reference/equality), or null.
  final T? value;

  final ValueChanged<T?>? onChanged;

  /// Field label shown above the dropdown (e.g. "AGENT").
  final String label;

  final String hintText;

  /// When false, the dropdown is rendered read-only (matches the existing
  /// "canChooseAgent" pattern used across FinCollect screens).
  final bool enabled;

  final String? Function(T? value)? validator;

  /// Appends a "*" to [label] to indicate a required field.
  final bool showRequiredMark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          showRequiredMark ? '$label *' : label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.kTextMuted,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          initialValue: value,
          isExpanded: true, // critical for small screens: prevents overflow
          decoration: InputDecoration(isDense: true, hintText: hintText),
          onChanged: enabled ? onChanged : null,
          validator: validator,
          items: items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(
                    labelOf(item),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: (isActiveOf?.call(item) ?? true)
                          ? AppColors.kTextDark
                          : AppColors.kTextMuted,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}