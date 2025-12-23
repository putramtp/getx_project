import 'package:flutter/material.dart';

class SearchBarWidget extends StatelessWidget {
  final bool isFocused;
  final bool isAscending;
  final TextEditingController searchController;
  final FocusNode focusNode;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onToggleSort;
  final VoidCallback? onOpenFilter;
  final String hintText;

  const SearchBarWidget({
    super.key,
    required this.isFocused,
    required this.isAscending,
    required this.searchController,
    required this.focusNode,
    required this.onSearchChanged,
    required this.onToggleSort,
    this.onOpenFilter,
    this.hintText = 'Search...',
  });

  @override
  Widget build(BuildContext context) {
    
    return LayoutBuilder(
      builder: (context , constraints) {
        final width = constraints.maxWidth;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            /// 🔍 Search Field
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                height: 50,
                child: Focus(
                  focusNode: focusNode,
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: hintText,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: isFocused
                          ? IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                searchController.clear();
                                FocusScope.of(context).unfocus();
                              },
                            )
                          : null,
                    ),
                    onChanged: onSearchChanged,
                  ),
                ),
              ),
            ),

            /// ✨ Sort & Filter Buttons
            if(width > 100) 
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SizeTransition(
                  sizeFactor: anim,
                  axis: Axis.horizontal,
                  child: child,
                ),
              ),
              child: !isFocused
                  ? Row(
                      key: const ValueKey('buttons'),
                      children: [
                        const SizedBox(width: 6),
                        IconButton.filledTonal(
                          tooltip: isAscending ? "Sort Z–A" : "Sort A–Z",
                          icon: Icon(
                            isAscending
                                ? Icons.sort_by_alpha_rounded
                                : Icons.arrow_upward_rounded,
                            color: Colors.blueGrey,
                          ),
                          onPressed: onToggleSort,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.all(6),
                          ),
                        ),
                        const SizedBox(width: 6),
                      (onOpenFilter != null) ? 
                        IconButton.filledTonal(
                          icon: const Icon(Icons.tune_rounded,color: Colors.blueGrey,),
                          tooltip: 'Filter',
                          onPressed: onOpenFilter,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.all(6),
                          ),
                        ) : const SizedBox.shrink() ,
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        );
      }
    );
  }
}
