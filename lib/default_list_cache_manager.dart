import 'dart:convert';

import 'database/database.dart';
import 'list_data_cache_manager.dart';

/**
 * suggestCacheNum：设置缓存数量，实际缓存数量不一定是该数值。ListDataCacheManager实际缓存的数据为suggestCacheNum + dbLoadExtent + ExtraExtent
 * dbLoadExtent：离链表_cacheList尽头还有多少条数据的时候开始加载数据库获取数据
 * networkLoadExtent：离最后一条数据还有多少条数据的时候开始进行网络请求获取更多数据。如当前总共有100条数据，如果设置networkLoadExtent为10的时候，那当第90条数据被用于构建UI的时候会调用requestNetworkData进行网络数据加载
 * dbLoadPageCount： 每次从数据库加载的数据数量
 * modelFromJson：json转数据模型T
 * modelToJson：模型T转json，以便于将json转string存储到数据库中
 */
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
    loadDBCacheData = loadDbData;
  }

  final T Function(Map<String, dynamic>) modelFromJson;
  final Map<String, dynamic> Function(T model) modelToJson;

  Future<List<T>> loadDbData(int startIndex, int endIndex) {
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
