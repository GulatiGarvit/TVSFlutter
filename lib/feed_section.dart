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
      padding: EdgeInsets.only(
        right: widget.pagePadding,
        top: widget.pagePadding,
        bottom: widget.pagePadding,
      ),
      child: Column(
        children: [
          // -------------------------
          // PINNED FEED (LARGE TILE)
          // -------------------------
          Flexible(
            flex: 2,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: Container(
                // Keep the layout size determined by the Flexible parent
                key: ValueKey(_pinnedFeedIndex),
                width: double.infinity,
                // Do not hard-clip the pinned area — allow child to overflow while interacting.
                // We still show rounded corners by using decoration, but avoid Clip.hardEdge.
                clipBehavior: Clip.none,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: _buildPinnedChild(
                  context,
                  widget.feeds[_pinnedFeedIndex],
                ),
              ),
            ),
          ),

          SizedBox(height: widget.pagePadding),

          // -------------------------
          // ROW OF SMALL FEEDS BELOW
          // -------------------------
          Flexible(
            flex: 1,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final totalWidth = constraints.maxWidth;
                final totalSpacing =
                    (otherFeedIndices.length - 1) * widget.pagePadding;
                // Prevent division by zero
                final safeCount =
                    otherFeedIndices.isEmpty ? 1 : otherFeedIndices.length;
                final itemWidth = (totalWidth - totalSpacing) / safeCount;

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
                      child: Container(
                        width: itemWidth,
                        clipBehavior: Clip.hardEdge,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(4),
                        ),

                        // Keep the small feeds non-interactive (original behavior)
                        child: IgnorePointer(
                          ignoring: true,
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

  /// Builds the pinned child. We align the child top-left so that map widgets
  /// which rely on intrinsic sizes can behave correctly. Non-map children
  /// will continue to layout normally.
  Widget _buildPinnedChild(BuildContext context, Widget child) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Container(
        color: Colors.black, // Background color for letterboxing
        child: Center(child: child),
      ),
    );
  }
}
