import 'package:flutter/material.dart';
import 'package:tvs/video_feed.dart';

class FeedSection extends StatefulWidget {
  final List<Widget> feeds;
  final double pagePadding = 8;

  const FeedSection({super.key, required this.feeds});

  @override
  State<FeedSection> createState() => _FeedSectionState();
}

class _FeedSectionState extends State<FeedSection> {
  int _pinnedFeedIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Make a list of all feed indices except the pinned one
    final otherFeedIndices =
        List<int>.generate(
          widget.feeds.length,
          (i) => i,
        ).where((i) => i != _pinnedFeedIndex).toList();

    return Padding(
      padding: EdgeInsets.all(widget.pagePadding),
      child: Column(
        children: [
          // Pinned feed at the top
          Flexible(
            flex: 2,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: SizedBox(
                key: ValueKey(_pinnedFeedIndex),
                width: double.infinity,
                child: widget.feeds[_pinnedFeedIndex],
              ),
            ),
          ),

          SizedBox(height: widget.pagePadding),

          // Non-pinned feeds below
          Flexible(
            flex: 1,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final totalWidth = constraints.maxWidth;
                final totalSpacing =
                    (otherFeedIndices.length - 1) * widget.pagePadding;
                final itemWidth =
                    (totalWidth - totalSpacing) / otherFeedIndices.length;

                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: otherFeedIndices.length,
                  separatorBuilder:
                      (context, index) => SizedBox(width: widget.pagePadding),
                  itemBuilder: (context, index) {
                    final actualIndex = otherFeedIndices[index];

                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        setState(() {
                          _pinnedFeedIndex = actualIndex;
                        });
                      },
                      child: SizedBox(
                        width: itemWidth,
                        height: 80,
                        child: IgnorePointer(
                          // Ignore interactions on small feeds
                          child: widget.feeds[actualIndex],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
