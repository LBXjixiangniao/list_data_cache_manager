# list_data_cache_manager
dart pub: https://pub.dev/packages/list_data_cache_manager
* 列表数据缓存
* 列表数据预加载

## 主要原理
![原理图](./read_me_image/list_data_cache.png?raw=true "原理图")



* 红色部分为存储在内存中的数据
* 绿色表示App正在使用的数据（包括屏幕上显示的和列表预加载的）
* 缓存使用链表管理，以利于添加和删除数据

## 用法
如果自己实现数据的存储和加载，则使用ListDataCacheManager类。DefaultListCacheManager已经实现了使用moor进行数据本地存储。

##### 创建管理类
* 创建，使用的时候将ListItemInfoModel替换为自己定义的数据模型类
```
///初始化缓存管理控件，设置模型转换方法
    _dataCacheManager = DefaultListCacheManager<ListItemInfoModel>(
      modelFromJson: (json) => ListItemInfoModel.fromJson(json),
      modelToJson: (model) => model.toJson(),
      requestNetworkData: (int startIndex) {
        ///加载网络数据
        
      },
    );
```

* 添加数据,list是ListItemInfoModel的数组
```
  _dataCacheManager.addAll(list);
```
* 清除数据，会清除内存和数据库中的数据。ListDataCacheManager类的clear方法只会清除缓存内存中数据，需手动管理本地数据。
```
  _dataCacheManager.clear();
```
* 使用数据构建列表
```
ListView.separated(
                  itemCount: _dataCacheManager.itemCount,
                  itemBuilder: (_, index) {
                    ListCacheItem<ListItemInfoModel> item = _dataCacheManager.dataAtIndex(index);
                    return ListCacheBuilder<ListItemInfoModel>(
                      builder: (cacheItem, _) {
                        ListItemInfoModel info = cacheItem?.data;
                        return Container(
                          height: 40,
                          alignment: Alignment.center,
                          child: Text('${info?.value}'),
                          // child:Text('hello'),
                        );
                      },
                      cacheItem: item,
                    );
                  },
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                  ),
                ),
```

* 网络加载管理
> * isLoadingNetworkData：是否正在加载网络数据，如果为true则正在加载网络数据，列表滚动到底部不会再调用requestNetworkData。如果为false，则列表滚动到底部会调用requestNetworkData通知获取网络数据。
> * enableNetworkLoading：所以获取网络数据成功后，如果还希望触发requestNetworkData回调方法，则需要调用`_dataCacheManager.enableNetworkLoading();`以允许继续触发requestNetworkData回调。如果没有更多数据了，则可调用`_dataCacheManager.unableNetworkLoading();`以确保不会再触发requestNetworkData回调。