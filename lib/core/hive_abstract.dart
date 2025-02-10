import "package:hive_ce_flutter/hive_flutter.dart";

class HiveDatabaseAbstraction {
  late Box<dynamic> _box;
  late BoxCollection _collection;
  late CollectionBox<dynamic> _collectionBox;

  Future<void> selectCollection(
    String collectionKey,
    Set<String> boxNames,
  ) async {
    _collection = await BoxCollection.open(
      collectionKey,
      boxNames,
    );
  }

  Future<void> selectCollectionBox(String boxKey) async {
    _collectionBox = await _collection.openBox(boxKey);
  }

  Future<void> selectBox(String boxKey) async {
    _box = await Hive.openBox(boxKey);
  }

  Future<void> put(String boxKey, String themeKey, dynamic value) async {
    await _box.put(themeKey, value);
    await _box.close();
  }

  dynamic get(String key) {
    return _box.get(key);
  }

  Future<void> putCollectionBox(String key, dynamic value) async {
    await _collectionBox.put(key, value);
    _collection.close();
  }

  Future<dynamic> getCollectionBox(String key) async {
    return _collectionBox.get(key);
  }

  Future<void> initHiveDatabase() async {
    await Hive.initFlutter(
      "monodef",
    );
  }
}
