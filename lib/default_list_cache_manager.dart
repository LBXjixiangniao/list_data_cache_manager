import 'dart:convert';

import 'database/database.dart';
import 'list_data_cache_manager.dart';


class DefaultListCacheManager<T> extends ListDataCacheManager<T> {
  DefaultListCacheManager({
    int suggestCacheNum = 100,
    int dbLoadExtent = 20,
    int networkLoadExtent = 25,
    int dbLoadPageCount = 50,
    this.modelFromJson,
    this.modelToJson,
    void Function(int startIndex) requestNetworkData,
  })  : assert(modelFromJson != null && modelToJson != null),
        super(
          suggestCacheNum: suggestCacheNum,
          dbLoadExtent: dbLoadExtent,
          networkLoadExtent: networkLoadExtent,
          dbLoadPageCount: dbLoadPageCount,
          requestNetworkData: requestNetworkData,
        ) {
    loadCacheData = loadDbCacheData;
  }

  final T Function(Map<String, dynamic>) modelFromJson;
  final Map<String, dynamic> Function(T model) modelToJson;

  Future<List<T>> loadDbCacheData(int startIndex, int endIndex) {
    return LbxDatabase()
        .cacheDBItemsDao
        .selecteDataFromIndexInOrder(
          startIndex: startIndex,
          count: endIndex - startIndex + 1,
          type: type,
        )
        .then((value) {
      return value
          .map(
            (e) => modelFromJson(
              jsonDecode(e.content),
            ),
          )
          .toList();
    });
  }

  @override
  void addAll(List<T> list) {
    int startIndex = itemCount;
    List<CacheDBItem> tmpList = list
        .map(
          (e) => CacheDBItem(
            content: jsonEncode(modelToJson(e)),
            type: type,
            index: startIndex++,
          ),
        )
        .toList();
    LbxDatabase().cacheDBItemsDao.insertList(
          tmpList,
        );
    super.addAll(list);
  }

  @override
  void clear() {
    LbxDatabase().cacheDBItemsDao.deleteAllForType();
    super.clear();
  }
}
