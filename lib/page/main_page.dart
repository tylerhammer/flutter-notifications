// Copyright (c) 2023 Sendbird, Inc. All rights reserved.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sendbird_chat_sample/component/widgets.dart';
import 'package:sendbird_chat_sdk/sendbird_chat_sdk.dart';
import 'dart:developer';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  String staticTitle = 'Feed Channel';

  @override
  void initState() {
    super.initState();
    SendbirdChat.addUserEventHandler('UNIQUE_HANDLER_ID', MyUserEventHandler(this));
    SendbirdChat.getTotalUnreadMessageCountWithFeedChannel().then((data) => {
      if (data.totalCountForFeedChannels > 0) {
        setState(() {
          staticTitle = 'Feed Channel (${data.totalCountForFeedChannels})';
        })
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Widgets.pageTitle('Main'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              Get.toNamed('/user');
            },
          ),
        ],
      ),
      body: _mainBox(),
    );
  }

  Widget _mainBox() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          ElevatedButton(
            onPressed: () async {
              Get.toNamed('/feed_channel/list');
            },
            child: const Text('Feed Channel List'),
          ),
          const SizedBox(height: 16.0),
          ElevatedButton(
            onPressed: () async {
              Get.toNamed('/feed_channel/notification_6060_feed');
            },
            child: Text(staticTitle),
          ),
        ],
      ),
    );
  }
}

class MyUserEventHandler extends UserEventHandler {
  final _MainPageState state;

  MyUserEventHandler(this.state);

  @override
  void onFriendsDiscovered(List<User> friends) {}

  @override 
  void onTotalUnreadMessageCountChanged(UnreadMessageCount unreadMessageCount) {
    state.setState(() {
      state.staticTitle = 'Feed Channel (${unreadMessageCount.totalCountForFeedChannels})';
    });
  }
}