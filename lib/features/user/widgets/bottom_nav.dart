import 'package:flutter/material.dart';

import 'package:ramhis_app/features/user/screens/account_screen.dart';
import 'package:ramhis_app/features/user/screens/chat_screen.dart';
import 'package:ramhis_app/features/user/screens/events_screen.dart';
import 'package:ramhis_app/features/user/screens/home_screen.dart';
class CustomNavBar extends StatelessWidget {
  final int currentIndex;

  const CustomNavBar({
    super.key,
    required this.currentIndex,
  });

  void _onItemTapped(BuildContext context, int index) {
    if (index == currentIndex) return;

    Widget page;
    switch (index) {
      case 0:
        page = const HomeWidget();
        break;
      case 1:
        page = const EventsWidget();
        break;
      case 2:
        page = const ChatCopyWidget();
        break;
      case 3:
        page = const AccountWidget();
        break;
      default:
        page = const HomeWidget();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF5D74DA),
          
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.18),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(
              context: context,
              index: 0,
              label: 'Home',
              icon: Icons.home_rounded,
            ),
            _navItem(
              context: context,
              index: 1,
              label: 'Event',
              icon: Icons.calendar_today_rounded,
            ),
            _navItem(
              context: context,
              index: 2,
              label: 'Chat',
              icon: Icons.chat_bubble_outline_rounded,
            ),
            _navItem(
              context: context,
              index: 3,
              label: 'Account',
              icon: Icons.person_outline_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem({
    required BuildContext context,
    required int index,
    required String label,
    required IconData icon,
  }) {
    final bool selected = currentIndex == index;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _onItemTapped(context, index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.white.withValues(alpha:0.16) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 23,
              color: selected ? Colors.white : const Color(0xFFEAF0FF),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? Colors.white : const Color(0xFFEAF0FF),
              ),
            ),
            const SizedBox(height: 5),
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              height: 3,
              width: selected ? 22 : 0,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}