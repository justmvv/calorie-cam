import 'package:flutter/material.dart';

import '../data/dish_catalog.dart';
import '../services.dart';
import 'format.dart';

/// Pick a dish from the catalog by name.
Future<Dish?> showDishSearch(BuildContext context) => showModalBottomSheet<Dish>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (context) => const _DishSearchSheet(),
);

class _DishSearchSheet extends StatefulWidget {
  const _DishSearchSheet();

  @override
  State<_DishSearchSheet> createState() => _DishSearchSheetState();
}

class _DishSearchSheetState extends State<_DishSearchSheet> {
  var _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final results = services.catalog.search(_query);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.85,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                autofocus: true,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: l10n.dishSearchHint,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            Expanded(
              child: results.isEmpty
                  ? Center(child: Text(l10n.nothingFound))
                  : ListView.builder(
                      itemCount: results.length,
                      itemBuilder: (context, i) {
                        final d = results[i];
                        return ListTile(
                          title: Text(l10n.dishName(d)),
                          subtitle: Text('${l10n.category(d.category)} · ${l10n.per100g(l10n.kcal(d.kcal))}'),
                          onTap: () => Navigator.pop(context, d),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
