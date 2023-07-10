// Copyright (c) 2023 Sendbird, Inc. All rights reserved.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sendbird_chat_sdk/sendbird_chat_sdk.dart';
import 'package:sendbird_chat_sample/component/widgets.dart';
import 'dart:developer';

class FeedChannelListPage extends StatefulWidget {
  const FeedChannelListPage({Key? key}) : super(key: key);

  @override
  State<FeedChannelListPage> createState() => FeedChannelListPageState();
}

class FeedChannelListPageState extends State<FeedChannelListPage> {
  late FeedChannelListQuery channelQuery;
  final notificationInfo = SendbirdChat.getAppInfo()?.notificationInfo;
  String? templateListToken;

  String title = 'Feed Channels';
  bool hasNext = false;
  List<FeedChannel> channelList = [];

  @override
  void initState() {
    super.initState();
    channelQuery = FeedChannelListQuery()
      ..includeEmpty = true
      ..limit = 20;
    channelQuery.next().then((channels) {
      inspect(channels);
      setState(() {
        channelList = channels;
        title = channelList.isEmpty
          ? 'Feed Channels'
          : 'Feed Channels (${channelList.length})';
        hasNext = channelQuery.hasNext;
      });
      SendbirdChat.addChannelHandler('MyFeedChannelHandler', MyFeedChannelHandler(this));
      _refresh();
    });

    SendbirdChat.getNotificationTemplateListByToken( NotificationTemplateListParams()).then((templateList) {
      templateListToken = templateList.token;
      inspect(templateList);
    });

  }

  @override
  void dispose() {
    super.dispose();
  }

  void _initChannelList() async {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Widgets.pageTitle(title),
      ),
      body: Column(
        children: [
          Expanded(
              child: channelList.isNotEmpty ? _list() : Container()),
          hasNext ? _moreButton() : Container(),
        ],
      ),
    );
  }

  Widget _list() {
    return ListView.builder(
      itemCount: channelList.length,
      itemBuilder: (BuildContext context, int index) {
        final feedChannel = channelList[index];

        return GestureDetector(
          child: Column(
            children: [
              ListTile(
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        feedChannel.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: Text(feedChannel.groupChannel.unreadMessageCount.toString()),
                      ),
                    ),
                  ],
                ),
                subtitle: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Container(),
                    ),
                    Container(
                      margin: const EdgeInsets.only(left: 16),
                      alignment: Alignment.centerRight,
                    ),
                  ],
                ),
                onTap: () {
                  Get.toNamed('/group_channel/${feedChannel.channelUrl}')
                      ?.then((_) => _refresh());
                },
              ),
              const Divider(height: 1),
            ],
          ),
        );
      },
    );
  }

  Widget _moreButton() {
    return Container(
      width: double.maxFinite,
      height: 32.0,
      color: Colors.purple[200],
      child: IconButton(
        icon: const Icon(Icons.expand_more, size: 16.0),
        color: Colors.white,
        onPressed: () {
          if (channelQuery.hasNext && !channelQuery.isLoading) {
            channelQuery.next();
          }
        },
      ),
    );
  }

  void _refresh() {
    setState(() {
      // channelList = channelQuery.channels;

      title = channelList.isEmpty
          ? 'Feed Channels'
          : 'Feed Channels (${channelList.length})';
      hasNext = channelQuery.hasNext;
    });
  }
}

class MyFeedChannelHandler extends FeedChannelHandler {
  final FeedChannelListPageState state;

  MyFeedChannelHandler(this.state);

  @override
  void onChannelChanged(BaseChannel channel) {
    state._refresh();
  }

  @override
  void onMessageReceived(BaseChannel channel, BaseMessage message) {
    inspect(message);
    state._refresh();
  }
}

