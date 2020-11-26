library list_data_cache_manager;

import 'dart:async';
import 'package:flutter/material.dart';

import 'custom_linked_list.dart';

typedef Widget ListWidgetBuilder<T>(ListCacheItem<T> cacheItem, BuildContext context);
const int ExtraExtent = 10;

enum ItemIndexDirection {
  ///获取更多数据，下标增长
  bigger,

  ///获取旧数据，下标减小
  smaller,
}

class ListCacheBuilder<T> extends StatefulWidget {
  final ListCacheItem<T> cacheItem;
  final ListWidgetBuilder<T> builder;

  const ListCacheBuilder({Key key, @required this.builder, @required this.cacheItem})
      : assert(builder != null && cacheItem != null),
        super(key: key);
  @override
  StatefulElement createElement() => ListCacheElement(this);
  @override
  _ListCacheBuilderState<T> createState() => _ListCacheBuilderState<T>();
}

class ListCacheElement extends StatefulElement {
  ListCacheElement(ListCacheBuilder widget) : super(widget);

  @override
  void mount(Element parent, newSlot) {
    super.mount(parent, newSlot);
    (widget as ListCacheBuilder).cacheItem._isInView = true;
    (widget as ListCacheBuilder).cacheItem.mount();
  }

  @override
  void unmount() {
    super.unmount();
    (widget as ListCacheBuilder).cacheItem._isInView = false;
    (widget as ListCacheBuilder).cacheItem._onDataSetCall = null;
  }
}

class _ListCacheBuilderState<T> extends State<ListCacheBuilder<T>> {
  @override
  void initState() {
    super.initState();
    if (widget.cacheItem != null) {
      widget.cacheItem._isInView = true;
    }
    setupRefresh();
  }

  void setupRefresh() {
    if (widget.cacheItem != null) {
      widget.cacheItem._onDataSetCall = (data) {
        setState(() {});
      };
    }
  }

  @override
  void didUpdateWidget(ListCacheBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cacheItem != null) {
      widget.cacheItem._isInView = true;
    }
    setupRefresh();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(widget.cacheItem, context);
  }
}

class ListCacheItem<T> extends LinkedListEntry<ListCacheItem> {
  ListCacheItem({@required this.index, @required T data, @required ListItemMountCallBack mountCall})
      : assert(mountCall != null),
        _data = data,
        _mountCall = mountCall;
  ListItemMountCallBack _mountCall;
  int index;
  T _data;
  T get data => _data;
  set data(T tmp) {
    if (_data != tmp) {
      _data = tmp;
      if (_onDataSetCall != null && _isInView) {
        _onDataSetCall(_data);
      }
    }
  }

  void mount() {
    if (_mountCall != null) {
      _mountCall.itemMount(index);
    }
  }

  ///是否正在视图中
  bool _isInView = false;

  ///可能由于加载数据慢问题造成一开始data为空，等有数据的时候，会触发onDataSetCall
  ValueChanged<T> _onDataSetCall;
}

class ListDataCacheManager<T> {
  ListDataCacheManager({
    this.suggestCacheNum = 100,
    this.dbLoadExtent = 20,
    this.networkLoadExtent = 25,
    this.dbLoadPageCount = 50,
    this.loadCacheData,
    this.requestNetworkData,
  })  : assert(dbLoadExtent > 0 && networkLoadExtent > 0 && dbLoadPageCount > 0),
        assert(suggestCacheNum > dbLoadExtent);

  ///设置缓存数量，实际缓存数量不一定是该数值
  ///建议设置为大于_dbLoadPageCount + 当前页面显示条数
  final int suggestCacheNum;

  ///还差几条数据滚到_cacheList尽头的时候进行数据库查询更多数据
  final int dbLoadExtent;

  ///还差几条数据滚到_cacheList尽头的时候进行网络请求获取更多数据
  final int networkLoadExtent;

  ///数据库查找数据，每次查询多少条出来
  final int dbLoadPageCount;

  Future<List<T>> Function(int startIndex, int endIndex) loadCacheData;
  void Function(int startIndex) requestNetworkData;

  ///内存中存储的数据
  CustomLinkedList<ListCacheItem> _cacheList = CustomLinkedList<ListCacheItem>();

  ListCacheItem get firstCacheItem => _cacheList.isEmpty ? null : _cacheList.first;
  ListCacheItem get lastCacheItem => _cacheList.isEmpty ? null : _cacheList.last;

  ///上一个返回的item
  ListCacheItem _lastItem;

  ///当前缓存，内存或者数据库存在的数据总数
  int _itemCount = 0;
  int get itemCount => _itemCount;

  ///item mount的时候回调
  ListItemMountCallBack _itemMountCallBack;

  ///用于区分数据库中数据
  String get type => '${this.hashCode.toString()}_$T';

  ///表识正在加载网络数据
  bool _isLoadingMoreNetworkData = false;
  bool get isLoadingNetworkData => _isLoadingMoreNetworkData;
  void enableNetworkLoading() {
    _isLoadingMoreNetworkData = false;
  }

  void unableNetworkLoading() {
    _isLoadingMoreNetworkData = true;
  }

  ///清空所有数据，包括数据库中数据
  void clear() {
    _itemMountCallBack?.close();
    _itemMountCallBack = ListItemMountCallBack(_checkIndex);
    _cacheList.clear();
    _itemCount = 0;
  }

  ///index自动递增
  void addAll(List<T> list) {
    list?.forEach((f) {
      _cacheList.add(ListCacheItem<T>(index: itemCount, data: f, mountCall: _itemMountCallBack));
      _itemCount++;
    });
    _clearNotInViewItemInCacheList(ItemIndexDirection.smaller);
  }

  ///获取index数据,一般只用于构建列表的时候获取数据，其他情况使用注意会造成缓存数据和显示数据不匹配问题
  ListCacheItem<T> dataAtIndex(int index) {
    assert(index < itemCount && index >= 0);
    if (index >= itemCount || index < 0) {
      return null;
    }
    _checkIndex(index);
    ListCacheItem<T> result = _findData(index);
    if (result != null) {
      _lastItem = result;
    }
    return result;
  }

  ///检查判断index，看是否需要请求网络数据或者从数据库加载数据
  void _checkIndex(int index) {
    if (index + dbLoadExtent >= _cacheList.last.index && _cacheList.last.index + 1 < itemCount) {
      ListCacheItem<T> lastItem = _cacheList.last;
      _addEmptyDataToCacheList(ItemIndexDirection.bigger, index);

      ///加载数据库中数据,加载当前_cacheList后面的数据
      if (_cacheList.last != lastItem && lastItem.next != null && _cacheList.last != null) {
        Timer.run(() {
          _loadDbData(
            startItem: lastItem.next,
            endItem: _cacheList.last,
            direction: ItemIndexDirection.bigger,
          );
        });
      }
    }
    if (index < _cacheList.first.index + dbLoadExtent && _cacheList.first.index > 0) {
      ListCacheItem<T> firstItem = _cacheList.first;
      _addEmptyDataToCacheList(ItemIndexDirection.smaller, index);

      ///加载数据库中数据，加载当前_cacheList前面的数据
      if (_cacheList.first != null && _cacheList.first != firstItem && firstItem.previous != null) {
        Timer.run(() {
          _loadDbData(
            startItem: _cacheList.first,
            endItem: firstItem.previous,
            direction: ItemIndexDirection.smaller,
          );
        });
      }
    }
    if (!_isLoadingMoreNetworkData && index + networkLoadExtent >= itemCount && requestNetworkData != null) {
      ///加载网络数据
      _isLoadingMoreNetworkData = true;
      Timer.run(() {
        requestNetworkData(itemCount);
      });
    }
  }

  ///向_cacheList中添加数据，如果下标index没超出范围，每次添加的数量为_dbLoadPageCount，
  void _addEmptyDataToCacheList(ItemIndexDirection direction, int currentIndex) {
    assert(direction != null);
    if (direction == ItemIndexDirection.bigger) {
      for (int index = 0; !(_cacheList.last.index > currentIndex + dbLoadExtent && index >= dbLoadPageCount) && _cacheList.last.index + 1 < itemCount; index++) {
        _cacheList.add(ListCacheItem<T>(data: null, index: _cacheList.last.index + 1, mountCall: _itemMountCallBack));
      }
    } else {
      for (int index = 0; !(_cacheList.first.index + dbLoadExtent < currentIndex && index >= dbLoadPageCount) && _cacheList.first.index > 0; index++) {
        _cacheList.addFirst(ListCacheItem<T>(data: null, index: _cacheList.first.index - 1, mountCall: _itemMountCallBack));
      }
    }
  }

  ///查找cacheList中数据，如果查处当前_cacheList缓存范围，则返回的
  ListCacheItem<T> _findData(int index) {
    assert(index != null && index >= 0);

    ///判断是否为_lastItem临近的数据
    if (_lastItem != null && _lastItem.list != null) {
      if (_lastItem.index >= index) {
        ListCacheItem<T> tmpItem = _lastItem;
        do {
          if (tmpItem.index == index) {
            break;
          }
          tmpItem = tmpItem.previous;
        } while (tmpItem != null);
        return tmpItem?.index == index ? tmpItem : null;
      } else {
        ListCacheItem<T> tmpItem = _lastItem.next;
        while (tmpItem != null) {
          if (tmpItem.index == index) {
            break;
          }
          tmpItem = tmpItem.next;
        }
        return tmpItem?.index == index ? tmpItem : null;
      }
    }
    //判断cacheList缓存中是否有该index数据
    else if (index >= _cacheList.first.index && index <= _cacheList.last.index) {
      if (index * 2 > (_cacheList.first.index + _cacheList.last.index)) {
        ///偏尾部
        ListCacheItem<T> tmpItem = _cacheList.last;
        do {
          if (tmpItem.index == index) {
            break;
          }
          tmpItem = tmpItem.previous;
        } while (tmpItem != null);
        return tmpItem?.index == index ? tmpItem : null;
      } else {
        ///偏头部
        return _cacheList.singleWhere((test) => test.index == index, orElse: () => null);
      }
    }
    return ListCacheItem(index: index, mountCall: _itemMountCallBack, data: null);
  }

  ///startItem是index小的，endItem是index大的
  void _loadDbData({@required ListCacheItem<T> startItem, @required ListCacheItem<T> endItem, @required ItemIndexDirection direction}) {
    assert(startItem != null && endItem != null);
    if (loadCacheData != null) {
      loadCacheData(startItem.index, endItem.index).then((tmpList) {
        bool isReversed = false;
        ListCacheItem<T> item;
        Iterable<T> iterable;
        if (startItem.list != null) {
          ///startItem还在_cacheList中
          iterable = tmpList;
          item = startItem;
        } else if (startItem.list == null && endItem.list != null) {
          ///startItem不在_cacheList中，endItem还在_cacheList中
          iterable = tmpList.reversed;
          item = endItem;
          isReversed = true;
        }

        if (item != null) {
          iterable?.firstWhere((f) {
            if (f != null) {
              item.data = f;
            }
            if (isReversed) {
              item = item.previous;
              if (item == null || item.list == null) {
                ///到头了或者item已经不在_cacheList中
                return true;
              }
            } else {
              item = item.next;
              if (item == null || item.list == null) {
                ///到头了或者item已经不在_cacheList中
                return true;
              }
            }

            return false;
          }, orElse: () => null);
        }

        ///清反方向的数据
        _clearNotInViewItemInCacheList(direction == ItemIndexDirection.bigger ? ItemIndexDirection.smaller : ItemIndexDirection.bigger);
      });
    }
  }

  ///清除不在视图中的数据
  void _clearNotInViewItemInCacheList(ItemIndexDirection direction) {
    assert(direction != null);
    if (_cacheList != null && _cacheList.isNotEmpty) {
      if (direction == ItemIndexDirection.smaller) {
        ///删下标小的那边
        ListCacheItem<T> tmpItem = _cacheList.first;
        ListCacheItem<T> toSetFirst = _cacheList.first;
        while (tmpItem._isInView != true && _cacheList.last.index - tmpItem.index >= suggestCacheNum) {
          if (tmpItem.index - _cacheList.first.index >= dbLoadExtent + ExtraExtent) {
            toSetFirst = toSetFirst.next;
          }
          tmpItem = tmpItem.next;
        }
        if (toSetFirst != _cacheList.first) {
          _cacheList.setFirst(toSetFirst);
        }
      } else if (direction == ItemIndexDirection.bigger) {
        ///删下标大的那边
        ListCacheItem<T> tmpItem = _cacheList.last;
        ListCacheItem<T> toSetLast = _cacheList.last;
        while (tmpItem._isInView != true && tmpItem.index - _cacheList.first.index >= suggestCacheNum) {
          if (_cacheList.last.index - tmpItem.index >= dbLoadExtent + ExtraExtent) {
            toSetLast = toSetLast.previous;
          }
          tmpItem = tmpItem.previous;
        }
        if (toSetLast != _cacheList.first) {
          _cacheList.setLast(toSetLast);
        }
      }
    }
  }
}

class ListItemMountCallBack {
  ValueChanged<int> _mount;
  bool _enable = true;

  ListItemMountCallBack(ValueChanged<int> mount) : _mount = mount;
  void itemMount(int index) {
    if (_enable && _mount != null) {
      _mount(index);
    }
  }

  ///关闭回调
  void close() {
    _enable = false;
    _mount = null;
  }
}
