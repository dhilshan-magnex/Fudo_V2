import 'package:flutter/material.dart';

class HomeLayout extends StatelessWidget {
  const HomeLayout({
    super.key,
    required this.primaryContent,
    required this.portraitSideContent,
    required this.landscapeSideContent,
  });

  final Widget primaryContent;
  final Widget portraitSideContent;
  final Widget landscapeSideContent;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscape = constraints.maxWidth > constraints.maxHeight;
        final useTwoColumns = isLandscape && constraints.maxWidth >= 640;
        final contentPadding = EdgeInsets.all(useTwoColumns ? 20 : 16);

        return SingleChildScrollView(
          padding: contentPadding,
          child: useTwoColumns ? _landscapeLayout() : _portraitLayout(),
        );
      },
    );
  }

  Widget _portraitLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        primaryContent,
        const SizedBox(height: 20),
        portraitSideContent,
      ],
    );
  }

  Widget _landscapeLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: primaryContent),
        const SizedBox(width: 24),
        SizedBox(
          width: 336,
          child: Align(
            alignment: Alignment.topRight,
            child: landscapeSideContent,
          ),
        ),
      ],
    );
  }
}