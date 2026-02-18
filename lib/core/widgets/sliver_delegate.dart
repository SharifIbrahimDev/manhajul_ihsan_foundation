import 'package:flutter/material.dart';

class SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  SliverAppBarDelegate(this._tabBar);

  final Widget _tabBar;

  @override
  double get minExtent => _tabBar is PreferredSizeWidget 
      ? (_tabBar as PreferredSizeWidget).preferredSize.height 
      : 80.0;
  @override
  double get maxExtent => _tabBar is PreferredSizeWidget 
      ? (_tabBar as PreferredSizeWidget).preferredSize.height 
      : 80.0;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
