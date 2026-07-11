import 'package:flutter/material.dart';

import '../services/installed_apps_service.dart';
import '../theme/app_colors.dart';

/// A searchable, multi-select bottom sheet for choosing which apps to block.
///
/// Returns the updated list of selected app *names* (or null if dismissed).
/// Names are used rather than package identifiers so the selection stays
/// consistent with how the backend stores blocked apps and works across the
/// Android (real apps) and iOS (preset) sources.
Future<List<String>?> showAppPickerSheet(
  BuildContext context, {
  required List<String> selected,
  InstalledAppsService service = const InstalledAppsService(),
}) {
  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.getBackground(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _AppPickerSheet(
      initialSelected: selected,
      service: service,
    ),
  );
}

class _AppPickerSheet extends StatefulWidget {
  final List<String> initialSelected;
  final InstalledAppsService service;

  const _AppPickerSheet({
    required this.initialSelected,
    required this.service,
  });

  @override
  State<_AppPickerSheet> createState() => _AppPickerSheetState();
}

class _AppPickerSheetState extends State<_AppPickerSheet> {
  final _searchController = TextEditingController();
  late Set<String> _selected;
  List<SelectableApp> _apps = [];
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selected = {...widget.initialSelected};
    _load();
    _searchController.addListener(
      () => setState(() => _query = _searchController.text.trim()),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final apps = await widget.service.getSelectableApps();
    if (!mounted) return;

    // Preserve any already-selected names that aren't in the device/preset
    // list (e.g. custom entries added on another device) so they aren't lost.
    final known = apps.map((a) => a.name.toLowerCase()).toSet();
    final extras = _selected
        .where((name) => !known.contains(name.toLowerCase()))
        .map((name) => SelectableApp(name: name))
        .toList();

    setState(() {
      _apps = [...extras, ...apps];
      _loading = false;
    });
  }

  List<SelectableApp> get _filtered {
    if (_query.isEmpty) return _apps;
    final q = _query.toLowerCase();
    return _apps.where((a) => a.name.toLowerCase().contains(q)).toList();
  }

  void _toggle(String name) {
    setState(() {
      if (_selected.contains(name)) {
        _selected.remove(name);
      } else {
        _selected.add(name);
      }
    });
  }

  void _addCustom() {
    final name = _query.trim();
    if (name.isEmpty) return;
    setState(() {
      if (!_apps.any((a) => a.name.toLowerCase() == name.toLowerCase())) {
        _apps = [SelectableApp(name: name), ..._apps];
      }
      _selected.add(name);
      _searchController.clear();
      _query = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppColors.getTextPrimary(context);
    final filtered = _filtered;
    final canAddCustom = _query.isNotEmpty &&
        !_apps.any((a) => a.name.toLowerCase() == _query.toLowerCase());

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.getTextSecondary(context).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Text(
                      'Block Apps',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_selected.length} selected',
                      style: TextStyle(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search apps…',
                    hintStyle:
                        TextStyle(color: AppColors.getTextSecondary(context)),
                    prefixIcon:
                        const Icon(Icons.search, color: AppColors.primary),
                    filled: true,
                    fillColor: AppColors.getSurface(context),
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              if (canAddCustom)
                ListTile(
                  leading: const Icon(Icons.add_circle_outline,
                      color: AppColors.primary),
                  title: Text('Add "$_query"',
                      style: TextStyle(color: textPrimary)),
                  onTap: _addCustom,
                ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : filtered.isEmpty
                        ? Center(
                            child: Text(
                              'No apps found.',
                              style: TextStyle(
                                  color: AppColors.getTextSecondary(context)),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final app = filtered[index];
                              final checked = _selected.contains(app.name);
                              return CheckboxListTile(
                                value: checked,
                                activeColor: AppColors.primary,
                                controlAffinity:
                                    ListTileControlAffinity.trailing,
                                secondary: _appIcon(app),
                                title: Text(
                                  app.name,
                                  style: TextStyle(color: textPrimary),
                                ),
                                onChanged: (_) => _toggle(app.name),
                              );
                            },
                          ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () =>
                          Navigator.pop(context, _selected.toList()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Done',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _appIcon(SelectableApp app) {
    if (app.icon != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(app.icon!, width: 36, height: 36),
      );
    }
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        app.name.isNotEmpty ? app.name[0].toUpperCase() : '?',
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
