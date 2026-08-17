import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/saved_item.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../services/share_intent_service.dart';
import '../services/update_service.dart';
import '../widgets/item_card.dart';
import '../widgets/item_sheet_helper.dart';
import '../widgets/update_dialog.dart';
import '../widgets/welcome_dialog.dart';
import 'account_screen.dart';
import 'category_management_screen.dart';
import 'settings_screen.dart';

enum SortOption { newest, oldest, nameAsc, nameDesc, platform }

String sortOptionLabel(SortOption option) {
  switch (option) {
    case SortOption.newest:
      return 'Più recenti';
    case SortOption.oldest:
      return 'Meno recenti';
    case SortOption.nameAsc:
      return 'Nome A-Z';
    case SortOption.nameDesc:
      return 'Nome Z-A';
    case SortOption.platform:
      return 'Piattaforma';
  }
}

String _displayName(SavedItem item) =>
    item.title.isNotEmpty ? item.title : item.url;

/// Filtra per categoria e testo di ricerca, poi ordina secondo [sortOption].
/// Funzione pura per poterla testare senza dover costruire un widget.
List<SavedItem> filterAndSortItems(
  List<SavedItem> items, {
  String? categoryId,
  String searchQuery = '',
  SortOption sortOption = SortOption.newest,
}) {
  var result = categoryId == null
      ? items
      : items.where((e) => e.categoryIds.contains(categoryId)).toList();

  final query = searchQuery.trim().toLowerCase();
  if (query.isNotEmpty) {
    result = result
        .where((e) =>
            e.title.toLowerCase().contains(query) ||
            e.note.toLowerCase().contains(query) ||
            e.url.toLowerCase().contains(query))
        .toList();
  }

  result = List.of(result);
  switch (sortOption) {
    case SortOption.newest:
      result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      break;
    case SortOption.oldest:
      result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      break;
    case SortOption.nameAsc:
      result.sort((a, b) => _displayName(a)
          .toLowerCase()
          .compareTo(_displayName(b).toLowerCase()));
      break;
    case SortOption.nameDesc:
      result.sort((a, b) => _displayName(b)
          .toLowerCase()
          .compareTo(_displayName(a).toLowerCase()));
      break;
    case SortOption.platform:
      result.sort((a, b) {
        final byPlatform = a.platform.index.compareTo(b.platform.index);
        return byPlatform != 0
            ? byPlatform
            : b.createdAt.compareTo(a.createdAt);
      });
      break;
  }
  return result;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _service = FirestoreService();
  String? _selectedCategoryId;
  bool _isSearching = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  SortOption _sortOption = SortOption.newest;

  @override
  void initState() {
    super.initState();
    ShareIntentService.instance.init(_onSharedUrl);
    _runStartupChecks();
  }

  Future<void> _runStartupChecks() async {
    await maybeShowWelcomeDialog(context);
    await _checkForUpdateSilently();
    await _maybeRequestNotificationPermission();
  }

  Future<void> _maybeRequestNotificationPermission() async {
    final notifications = NotificationService.instance;
    if (notifications.enabled && !notifications.permissionAlreadyAsked) {
      await notifications.requestPermissionIfNeeded();
    }
  }

  Future<void> _checkForUpdateSilently() async {
    final info = await UpdateService().checkForUpdate();
    if (info == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Nuova versione disponibile: ${info.version}'),
        action: SnackBarAction(
          label: 'Dettagli',
          onPressed: () => showUpdateDialog(context, info),
        ),
        duration: const Duration(seconds: 8),
      ),
    );
  }

  @override
  void dispose() {
    ShareIntentService.instance.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchQuery = '';
        _searchController.clear();
      }
    });
  }

  void _onSharedUrl(String url) {
    // Aspetta che l'albero dei widget sia pronto prima di aprire il foglio.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      openItemSheet(context, prefilledUrl: url);
    });
  }

  Widget _buildDrawer() {
    // Nota: non chiudiamo il drawer prima di navigare, così quando si torna
    // indietro dalla schermata aperta il drawer risulta ancora aperto.
    return Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            const DrawerHeader(
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  'Stashly',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Account'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AccountScreen()),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.label_outline),
              title: const Text('Gestisci categorie'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CategoryManagementScreen(),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Impostazioni'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Cerca nei salvati...',
                  border: InputBorder.none,
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              )
            : const Text('Stashly'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: _toggleSearch,
          ),
          PopupMenuButton<SortOption>(
            icon: const Icon(Icons.sort),
            tooltip: 'Ordina',
            initialValue: _sortOption,
            onSelected: (option) => setState(() => _sortOption = option),
            itemBuilder: (context) => SortOption.values
                .map(
                  (option) => PopupMenuItem(
                    value: option,
                    child: Text(sortOptionLabel(option)),
                  ),
                )
                .toList(),
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: StreamBuilder<List<Category>>(
        stream: _service.watchCategories(),
        builder: (context, categorySnapshot) {
          final categories = categorySnapshot.data ?? [];
          final categoryById = {for (final c in categories) c.id: c};

          return StreamBuilder<List<SavedItem>>(
            stream: _service.watchItems(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Ancora nessun salvato.\nUsa il pulsante + per aggiungere '
                      'il tuo primo link, oppure condividi direttamente da '
                      'Instagram, TikTok o Pinterest.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              final filtered = filterAndSortItems(
                items,
                categoryId: _selectedCategoryId,
                searchQuery: _searchQuery,
                sortOption: _sortOption,
              );

              return Column(
                children: [
                  SizedBox(
                    height: 48,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: const Text('Tutti'),
                            selected: _selectedCategoryId == null,
                            onSelected: (_) =>
                                setState(() => _selectedCategoryId = null),
                          ),
                        ),
                        ...categories.map(
                          (c) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ChoiceChip(
                              label: Text(c.name),
                              avatar: CircleAvatar(
                                backgroundColor: c.color,
                                radius: 6,
                              ),
                              selected: _selectedCategoryId == c.id,
                              onSelected: (_) =>
                                  setState(() => _selectedCategoryId = c.id),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(
                            child: Text('Nessun salvato corrisponde ai filtri.'),
                          )
                        : ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (context, index) => ItemCard(
                              item: filtered[index],
                              categoryById: categoryById,
                            ),
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => openItemSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
