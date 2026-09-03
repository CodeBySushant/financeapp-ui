import '../../../core/models/json.dart';
import '../../../core/network/api_client.dart';
import '../domain/category.dart';

class CategoriesRepository {
  CategoriesRepository({ApiClient? client})
      : _api = client ?? ApiClient.instance;

  final ApiClient _api;

  Future<List<Category>> list() async {
    final json = await _api.get<Map<String, dynamic>>('/api/categories');
    return J.items(json).map(Category.fromJson).toList(growable: false);
  }

  Future<void> create({required String name, required CategoryKind kind}) =>
      _api.post<Map<String, dynamic>>('/api/categories', body: {
        'name': name,
        'kind': kind.wire,
      });
}
