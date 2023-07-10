// Copyright (c) 2023 Sendbird, Inc. All rights reserved.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:sendbird_chat_sdk/sendbird_chat_sdk.dart';
import 'package:sendbird_chat_sample/component/widgets.dart';
import 'dart:developer';

class FeedChannelPage extends StatefulWidget {
  const FeedChannelPage({Key? key}) : super(key: key);

  @override
  State<FeedChannelPage> createState() => FeedChannelPageState();
}

class FeedChannelPageState extends State<FeedChannelPage> {
  final channelUrl = Get.parameters['channel_url']!;
  
  final itemScrollController = ItemScrollController();
  final textEditingController = TextEditingController();
  NotificationCollection? collection;

  String title = '';
  bool hasPrevious = false;
  bool hasNext = false;
  List<BaseMessage> messageList = [];

  @override
  void initState() {
    super.initState();
    _initializeNotificationCollection();
  }

  void _initializeNotificationCollection() {
    FeedChannel.getChannel(channelUrl).then((channel) {
      collection = NotificationCollection(
        channel: channel,
        params: MessageListParams()
        ..previousResultSize = 5
        handler: MyNotificationCollectionHandler(this),
      )..initialize();

      setState(() {
        title = '${channel.name} (${messageList.length})';
      });
    });
  }

  void _disposeNotificationCollection() {
    collection?.dispose();
  }

  @override
  void dispose() {
    _disposeNotificationCollection();
    textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Widgets.pageTitle(title, maxLines: 2),
      ),
      body: Column(
        children: [
          hasPrevious ? _previousButton() : Container(),
          Expanded(
            child: (collection != null && collection!.messageList.isNotEmpty)
                ? _list()
                : Container(),
          ),
          hasNext ? _nextButton() : Container(),
          _messageSender(),
        ],
      ),
    );
  }

  Widget _previousButton() {
    return Container(
      width: double.maxFinite,
      height: 32.0,
      color: Colors.purple[200],
      child: IconButton(
        icon: const Icon(Icons.expand_less, size: 16.0),
        color: Colors.white,
        onPressed: () async {
          if (collection != null) {
            if (collection!.params.reverse) {
              if (collection!.hasNext && !collection!.isLoading) {
                await collection!.loadNext();
              }
            } else {
              if (collection!.hasPrevious && !collection!.isLoading) {
                await collection!.loadPrevious();
              }
            }
          }

          setState(() {
            if (collection != null) {
              hasPrevious = collection!.hasPrevious;
              hasNext = collection!.hasNext;
            }
          });
        },
      ),
    );
  }

  Widget _list() {
    return ScrollablePositionedList.builder(
      physics: const ClampingScrollPhysics(),
      initialScrollIndex: (collection != null && collection!.params.reverse)
          ? 0
          : messageList.length - 1,
      itemScrollController: itemScrollController,
      itemCount: messageList.length,
      itemBuilder: (BuildContext context, int index) {
        BaseMessage message = messageList[index];
        String subDataString = message.extendedMessage['sub_data'];
        Map<String, dynamic> subData = json.decode(subDataString);

        return GestureDetector(
          child: Column(
            children: [
              ListTile(
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                              message.message,
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
                subtitle: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    
                    Container(
                      margin: const EdgeInsets.only(left: 16),
                      alignment: Alignment.centerRight,
                      child: Text(
                        DateTime.fromMillisecondsSinceEpoch(message.createdAt)
                            .toString(),
                        style: const TextStyle(fontSize: 12.0),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
            ],
          ),
        );
      },
    );
  }

  Widget _nextButton() {
    return Container(
      width: double.maxFinite,
      height: 32.0,
      color: Colors.purple[200],
      child: IconButton(
        icon: const Icon(Icons.expand_more, size: 16.0),
        color: Colors.white,
        onPressed: () async {
          if (collection != null) {
            if (collection!.params.reverse) {
              if (collection!.hasPrevious && !collection!.isLoading) {
                await collection!.loadPrevious();
              }
            } else {
              if (collection!.hasNext && !collection!.isLoading) {
                await collection!.loadNext();
              }
            }
          }

          setState(() {
            if (collection != null) {
              hasPrevious = collection!.hasPrevious;
              hasNext = collection!.hasNext;
            }
          });
        },
      ),
    );
  }

  Widget _messageSender() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: Widgets.textField(textEditingController, 'Message'),
          ),
          const SizedBox(width: 8.0),
          ElevatedButton(
            onPressed: () {
              if (textEditingController.value.text.isEmpty) {
                return;
              }

              collection?.channel.sendUserMessage(
                UserMessageCreateParams(
                  message: textEditingController.value.text,
                ),
                handler: (UserMessage message, SendbirdException? e) {
                  if (e != null) throw Exception(e.toString());
                },
              );

              textEditingController.clear();
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _refresh({bool markAsRead = false}) {
    if (markAsRead) {
      collection?.channel?.markAsRead(); 
    }

    setState(() {
      if (collection != null) {
        messageList = collection!.messageList;
        title = '${collection!.channel.name} (${messageList.length})';
        hasPrevious = collection!.params.reverse
            ? collection!.hasNext
            : collection!.hasPrevious;
        hasNext = collection!.params.reverse
            ? collection!.hasPrevious
            : collection!.hasNext;
      }
    });
  }

  void _scrollToAddedMessages(CollectionEventSource eventSource) async {
    if (collection == null || collection!.messageList.length <= 1) return;

    final reverse = collection!.params.reverse;
    final previous = eventSource == CollectionEventSource.messageLoadPrevious;

    final int index;
    if ((reverse && previous) || (!reverse && !previous)) {
      index = collection!.messageList.length - 1;
    } else {
      index = 0;
    }

    while (!itemScrollController.isAttached) {
      await Future.delayed(const Duration(milliseconds: 1));
    }

    itemScrollController.scrollTo(
      index: index,
      duration: const Duration(milliseconds: 200),
      curve: Curves.fastOutSlowIn,
    );
  }
}

class MyNotificationCollectionHandler extends NotificationCollectionHandler {
  final FeedChannelPageState _state;

  MyNotificationCollectionHandler(this._state);

  @override
  void onMessagesAdded(NotificationContext context, FeedChannel channel,
      List<BaseMessage> messages) async {

    _state._refresh(markAsRead: true);

    if (context.collectionEventSource !=
        CollectionEventSource.messageInitialize) {
      Future.delayed(
        const Duration(milliseconds: 100),
        () => _state._scrollToAddedMessages(context.collectionEventSource),
      );
    }
  }

  @override
  void onMessagesUpdated(NotificationContext context, FeedChannel channel,
      List<BaseMessage> messages) {
    _state._refresh();
  }

  @override
  void onMessagesDeleted(NotificationContext context, FeedChannel channel,
      List<BaseMessage> messages) {
    _state._refresh();
  }

  @override
  void onChannelUpdated(FeedChannelContext context, FeedChannel channel) {
    _state._refresh();
  }

  void onChannelDeleted(FeedChannelContext context, String channel) {
    _state._refresh();
  }

  @override
  void onHugeGapDetected() {
    _state._disposeNotificationCollection();
    _state._initializeNotificationCollection();
  }
}
