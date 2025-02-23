import 'package:flutter/material.dart';
import 'package:sapers/models/styles.dart';

class SnackBarCustom{
  void showSuccessSnackBar(context, projectId) {
  const double initialOpacity = 0.0;
  const double finalOpacity = 1.0;
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
      padding: const EdgeInsets.all(0),
      content: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.fastEaseInToSlowEaseOut,
        height: 48,
        decoration: BoxDecoration(
          color: AppStyles().getProjectCardColor(projectId),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedOpacity(
              opacity: finalOpacity,
              duration: const Duration(milliseconds: 300),
              child: const Padding(
                padding: EdgeInsets.only(left: 16.0, right: 8.0),
                child: Icon(Icons.check_circle_rounded, 
                  color: Colors.white,
                  size: 20),
              ),
            ),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: initialOpacity, end: finalOpacity),
              duration: const Duration(milliseconds: 500),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: child,
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Text('Archivos subidos exitosamente!',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}