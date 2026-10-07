import 'package:flutter/material.dart';

import '../data/db.dart';
import '../data/dish_catalog.dart';
import '../services.dart';
import 'format.dart';

/// What the user picked in [showDishSearch].
sealed class FoodChoice {}

final class CatalogChoice extends FoodChoice {
  CatalogChoice(this.dish);
  final Dish dish;
}

final class ProductChoice extends FoodChoice {
  ProductChoice(this.product);
  final Product product;
}

final class SetChoice extends FoodChoice {
  SetChoice(this.set);
  final MealSet set;
}

/// "Enter calories manually": the caller asks for the numbers.
final class ManualChoice extends FoodChoice {}

/// Pick a dish from the catalog, one of the user's products or sets, or choose to type
/// calories in by hand.
Future<FoodChoice?> showDishSearch(BuildContext context) => showModalBottomSheet<FoodChoice>(
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

  bool _matches(String name) => DishCatalog.matchesQuery(name, _query);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final results = services.catalog.search(_query);
    final textTheme = Theme.of(context).textTheme;
    Widget header(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(text, style: textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.primary)),
    );
    Widget deletable(Key key, Future<void> Function() delete, Widget child) => Dismissible(
      key: key,
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Theme.of(context).colorScheme.errorContainer,
        child: Icon(Icons.delete_outline, semanticLabel: l10n.deleteItem),
      ),
      onDismissed: (_) => delete(),
      child: child,
    );

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
              child: StreamBuilder<List<MealSet>>(
                stream: services.db.watchSets(),
                builder: (context, setsSnap) => StreamBuilder<List<Product>>(
                  stream: services.db.watchProducts(),
                  builder: (context, productsSnap) {
                    final sets = (setsSnap.data ?? const <MealSet>[]).where((s) => _matches(s.name)).toList();
                    final products = (productsSnap.data ?? const <Product>[]).where((p) => _matches(p.name)).toList();
                    return ListView(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.edit_note),
                          title: Text(l10n.enterManually),
                          subtitle: Text(l10n.enterManuallyHint),
                          onTap: () => Navigator.pop(context, ManualChoice()),
                        ),
                        if (sets.isNotEmpty) header(l10n.mySets),
                        for (final s in sets)
                          deletable(
                            ValueKey('set-${s.uuid}'),
                            () => services.db.deleteSet(s),
                            ListTile(
                              leading: const Icon(Icons.bookmark_outline),
                              title: Text(s.name),
                              subtitle: Text(_setSummary(l10n, s)),
                              onTap: () => Navigator.pop(context, SetChoice(s)),
                            ),
                          ),
                        if (products.isNotEmpty) header(l10n.myProducts),
                        for (final p in products)
                          deletable(
                            ValueKey('product-${p.uuid}'),
                            () => services.db.deleteProduct(p),
                            ListTile(
                              leading: const Icon(Icons.inventory_2_outlined),
                              title: Text(p.name),
                              subtitle: Text(l10n.per100g(l10n.kcal(p.kcal))),
                              onTap: () => Navigator.pop(context, ProductChoice(p)),
                            ),
                          ),
                        if (sets.isNotEmpty || products.isNotEmpty) header(l10n.catalogSection),
                        if (results.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Center(child: Text(l10n.nothingFound)),
                          ),
                        for (final d in results)
                          ListTile(
                            title: Text(l10n.dishName(d)),
                            subtitle: Text('${l10n.category(d.category)} · ${l10n.per100g(l10n.kcal(d.kcal))}'),
                            onTap: () => Navigator.pop(context, CatalogChoice(d)),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _setSummary(AppLocalizations l10n, MealSet s) {
    final items = SetItem.listFromJson(s.items);
    final kcal = items.fold(0.0, (a, i) => a + i.per100.kcal * i.grams / 100);
    final names = items.map(
      (i) => switch (services.catalog.byId(i.dishId)) {
        final dish? => l10n.dishName(dish),
        null => i.name,
      },
    );
    return '${l10n.kcal(kcal)} · ${names.join(', ')}';
  }
}
