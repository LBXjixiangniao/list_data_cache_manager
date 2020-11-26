import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import 'main.dart';
import 'model/list_model.dart';

class CommonListDataPage extends StatefulWidget {
  @override
  _CommonListDataPageState createState() => _CommonListDataPageState();
}

class _CommonListDataPageState extends State<CommonListDataPage> {
  List<ListItemInfoModel> _dataList = [];
  RefreshController _refreshController = RefreshController(initialRefresh: true);
  StreamController<int> _streamController = StreamController<int>();

  @override
  void initState() {
    super.initState();
    _streamController.add(0);
  }

  void getData(int startIndex) {
    // Future.delayed(Duration(seconds: 1), () {
      if (_refreshController.isRefresh) {
        _refreshController.refreshCompleted();
      }
      if (_refreshController.isLoading) {
        _refreshController.loadComplete();
      }

      ///判断是否下拉刷新
      if (startIndex == 0) {
        _dataList.clear();

        ///清除nodata，以便可以继续上拉加载更多
        _refreshController.loadComplete();
      }

      List.generate(PageCount, (index) => _dataList.add(ListItemInfoModel(value: index + startIndex)));

      setState(() {});
    // });
  }

  @override
  void dispose() {
    _streamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('列表数据管理'),
      ),
      body: Column(
        children: [
          Container(
            height: 40,
            width: BoxConstraints.expand().maxWidth,
            color: Colors.red,
            alignment: Alignment.center,
            child: StreamBuilder(
              stream: _streamController.stream,
              builder: (_, __) => Text('缓存总数${_dataList?.length ?? 0}'),
            ),
          ),
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                // print(notification);
                _streamController.add(0);
                return true;
              },
              child: SmartRefresher(
                // header: defaultRefreshHeader(),
                // footer: defaultRefreshFooter(),
                enablePullUp: _dataList.isNotEmpty,
                controller: _refreshController,
                onRefresh: () {
                  getData(0);
                },
                onLoading: () {
                  getData(_dataList.length);
                },
                child: ListView.separated(
                  itemCount: _dataList.length,
                  itemBuilder: (_, index) {
                    ListItemInfoModel info = _dataList[index];
                    return Container(
                      height: 40,
                      alignment: Alignment.center,
                      child: Text('${info?.value}'),
                    );
                  },
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
