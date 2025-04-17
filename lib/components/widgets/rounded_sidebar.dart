import 'package:flutter/material.dart';

class RoundedSidebar extends StatefulWidget {
  final List<IconData> icons;
  final List<VoidCallback> actions;

  const RoundedSidebar({
    Key? key,
    required this.icons,
    required this.actions,
  }) : super(key: key);

  @override
  State<RoundedSidebar> createState() => _RoundedSidebarState();
}

class _RoundedSidebarState extends State<RoundedSidebar> {
  bool _isSidebarVisible = false;

  void _toggleSidebar() {
    setState(() {
      _isSidebarVisible = !_isSidebarVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Sidebar
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          left: _isSidebarVisible ? 0 : -80,
          top: 0,
          bottom: 0,
          child: Container(
            width: 80,
            decoration: BoxDecoration(
              color: Colors.blueAccent,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.icons.length, (index) {
                return IconButton(
                  icon: Icon(
                    widget.icons[index],
                    color: Colors.white,
                  ),
                  onPressed: widget.actions[index],
                );
              }),
            ),
          ),
        ),
        // Burger Button
        Positioned(
          left: _isSidebarVisible ? 80 : 10,
          top: 20,
          child: GestureDetector(
            onTap: _toggleSidebar,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
              child: Icon(
                _isSidebarVisible ? Icons.close : Icons.menu,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
