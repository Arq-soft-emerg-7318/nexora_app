import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/community_service.dart';
import '../models/community.dart';
import '../services/auth_notifier.dart';

class TrendsScreen extends StatefulWidget {
  const TrendsScreen({Key? key}) : super(key: key);

  @override
  State<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends State<TrendsScreen> {
  final CommunityService _communityService = CommunityService();
  List<Community> _communities = [];
  bool _loading = true;
  final Set<int> _myCommunityIds = {};

  @override
  void initState() {
    super.initState();
    _loadCommunities();
  }

  Future<void> _loadCommunities() async {
    setState(() => _loading = true);
    try {
      final auth = Provider.of<AuthNotifier>(context, listen: false);
      final token = auth.token;
      final fetched = await _communityService.fetchAll(token: token);
      List<Community> mine = [];
      try {
        mine = await _communityService.fetchMine(token: token);
      } catch (_) {
        // ignore: could not fetch user's communities
      }
      setState(() {
        _communities = fetched;
        _myCommunityIds.clear();
        _myCommunityIds.addAll(mine.map((c) => c.id));
      });
    } catch (e) {
      // ignore
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showCreateCommunitySheet(BuildContext ctx) async {
    final nameCtl = TextEditingController();
    final descCtl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet<bool>(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: StatefulBuilder(builder: (context, setState) {
            bool loading = false;
            String? error;

            Future<void> submit() async {
              if (!formKey.currentState!.validate()) return;
              setState(() {
                loading = true;
                error = null;
              });
              final auth = Provider.of<AuthNotifier>(ctx, listen: false);
              final token = auth.token;
              try {
                final ok = await _communityService.createCommunity(nameCtl.text.trim(), descCtl.text.trim(), token: token);
                if (ok) {
                  Navigator.of(context).pop(true);
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Comunidad creada')));
                  await _loadCommunities();
                } else {
                  setState(() {
                    error = 'No se pudo crear la comunidad';
                  });
                }
              } catch (e) {
                setState(() {
                  error = 'Error: ${e.toString()}';
                });
              } finally {
                if (mounted) setState(() => loading = false);
              }
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Crear comunidad', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(onPressed: () => Navigator.of(context).pop(false), icon: const Icon(Icons.close)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Form(
                    key: formKey,
                    child: Column(children: [
                      TextFormField(
                        controller: nameCtl,
                        decoration: const InputDecoration(labelText: 'Nombre de comunidad', border: OutlineInputBorder()),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingrese un nombre' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descCtl,
                        decoration: const InputDecoration(labelText: 'Descripción (opcional)', border: OutlineInputBorder()),
                        maxLines: 3,
                      ),
                      if (error != null) ...[
                        const SizedBox(height: 8),
                        Text(error!, style: const TextStyle(color: Colors.red)),
                      ],
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: loading ? null : submit,
                            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                            child: loading ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Crear comunidad'),
                          ),
                        ),
                      ])
                    ]),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          }),
        );
      },
    );
  }

  Future<void> _joinCommunity(int id) async {
    final auth = Provider.of<AuthNotifier>(context, listen: false);
    final token = auth.token;
    try {
      final ok = await _communityService.joinCommunity(id, token: token);
      if (ok) {
        // update local membership state immediately
        setState(() => _myCommunityIds.add(id));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Te uniste a la comunidad')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo unir')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo unir')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateCommunitySheet(context),
        icon: const Icon(Icons.group_add),
        label: const Text('Crear comunidad'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFB4D7F7),
              Color(0xFFFFFFFF),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(
                          Icons.group,
                          color: Colors.white,
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Comunidades',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Explora y únete a comunidades relevantes',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.95),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: RefreshIndicator(
                    onRefresh: _loadCommunities,
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : _communities.isEmpty
                            ? ListView(
                                padding: const EdgeInsets.all(24),
                                children: const [
                                  Center(child: Text('No hay comunidades', style: TextStyle(color: Colors.grey))),
                                ],
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _communities.length,
                                itemBuilder: (context, index) {
                                  final c = _communities[index];
                                  final joined = _myCommunityIds.contains(c.id);
                                  return Card(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    margin: const EdgeInsets.symmetric(vertical: 8),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: c.description != null ? Text(c.description!) : null,
                                      trailing: joined
                                          ? OutlinedButton(
                                              onPressed: null,
                                              child: const Text('Unido'),
                                            )
                                          : ElevatedButton(
                                              onPressed: () => _joinCommunity(c.id),
                                              child: const Text('Unirse'),
                                            ),
                                    ),
                                  );
                                },
                              ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}