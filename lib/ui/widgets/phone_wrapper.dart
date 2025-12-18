import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Wrapper widget that constrains content to phone-like dimensions
/// and displays a phone frame mockup when running on web
class PhoneWrapper extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const PhoneWrapper({
    super.key,
    required this.child,
    this.maxWidth = 390,
  });

  @override
  Widget build(BuildContext context) {
    // On mobile devices, just return the child directly
    if (!kIsWeb) {
      return child;
    }

    // On web, wrap in a phone mockup frame
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate phone height based on available space
        final availableHeight = constraints.maxHeight;
        final phoneHeight = (availableHeight * 0.85).clamp(500.0, 844.0);
        final phoneWidth = (phoneHeight * 0.46).clamp(280.0, maxWidth);
        
        return Container(
          color: const Color(0xFF1a1a2e), // Dark background for web
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // App title above phone
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Text(
                        'Coordinate',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    
                    // Phone frame
                    Container(
                      width: phoneWidth + 20,
                      height: phoneHeight,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2d2d3a),
                        borderRadius: BorderRadius.circular(44),
                        border: Border.all(
                          color: const Color(0xFF3d3d4a),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            blurRadius: 60,
                            spreadRadius: -10,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Top notch area
                          Container(
                            height: 32,
                            padding: const EdgeInsets.only(top: 8),
                            child: Center(
                              child: Container(
                                width: 100,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1a1a24),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF2a2a3a),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      width: 40,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2a2a3a),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          
                          // Phone screen content
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 10),
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                color: AppTheme.background,
                                borderRadius: BorderRadius.circular(34),
                              ),
                              child: child,
                            ),
                          ),
                          
                          // Bottom home indicator
                          Container(
                            height: 28,
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Center(
                              child: Container(
                                width: 120,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4a4a5a),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Instructions below phone
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        'Pull down to refresh • Swipe trips to delete',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
