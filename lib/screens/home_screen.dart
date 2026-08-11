import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/saved_item.dart';
import '../services/firestore_service.dart';
import '../services/share_intent_service.dart';
import '../services/update_service.dart';
import '../widgets/item_card.dart';
import '../widgets/item_sheet_helper.dart';
import '../widgets/update_dialog.dart';
import '../widgets/welcome_dialog.dart';
import 'account_screen.dart';
import 'category_management_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _service = FirestoreService();
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    ShareIntentService.instance.init(_onSharedUrl);
    _runStartupChecks();
  }

  Future<void> _runStartupChecks() async {
    await maybeShowWelcomeDialog(context);
    await _checkForUpdateSilently();
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
    super.dispose();
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
      appBar: AppBar(title: const Text('Stashly')),
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

              final filtered = _selectedCategoryId == null
                  ? items
                  : items
                      .where((e) => e.categoryIds.contains(_selectedCategoryId))
                      .toList();

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
                    child: ListView.builder(
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
