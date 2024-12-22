import 'package:flutter/material.dart';
import 'package:sapers/main.dart';
import 'package:sapers/models/styles.dart';
import 'package:sapers/models/texts.dart';

class SearchBarCustom extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSearch;
  final Function(String) onModuleSelected;
  final List<String> modules;
  final String selectedModule;
 
  const SearchBarCustom({
    Key? key,
    required this.controller,
    required this.onSearch,
    required this.onModuleSelected,
    required this.modules,
    required this.selectedModule,
 
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SizedBox(
          height: MediaQuery.of(context).size.height / 13,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                hintText: Texts.translate('buscar', globalLanguage),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppStyles.borderRadiusValue),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                //  prefixIcon: IconButton(
                //   icon: const Icon(Icons.chat_bubble_outline), // Icono de burbujas
                //   onPressed: onBubbleIconPressed, // Acción al presionar el icono
                // ),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PopupMenuButton<String>(
                      icon: Stack(
                        children: [
                          const Icon(Icons.filter_list, size: 20),
                          if (selectedModule.isNotEmpty)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 8,
                                  minHeight: 8,
                                ),
                              ),
                            ),
                        ],
                      ),
                      tooltip:
                          Texts.translate('filtrarPorModulo', globalLanguage),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppStyles.borderRadiusValue),
                      ),
                      elevation: 4,
                      itemBuilder: (context) => [
                        const PopupMenuItem<String>(
                          value: '',
                          child: Text('Todos los módulos'),
                        ),
                        ...modules.map((module) => PopupMenuItem<String>(
                              value: module,
                              child: Row(
                                children: [
                                  Text(module),
                                  if (selectedModule == module) const Spacer(),
                                  if (selectedModule == module)
                                    Icon(
                                      Icons.check,
                                      color: Theme.of(context).primaryColor,
                                      size: 18,
                                    ),
                                ],
                              ),
                            )),
                      ],
                      onSelected: onModuleSelected,
                    ),
                    IconButton(
                      iconSize: 20.0,
                      icon: const Icon(Icons.search),
                      onPressed: onSearch,
                    ),
                  ],
                ),
              ),
              onSubmitted: (_) => onSearch(),
            ),
          ),
        ),
      ),
    );
  }
}
