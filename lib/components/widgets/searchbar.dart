import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:sapers/main.dart';
import 'package:sapers/models/language_provider.dart';
import 'package:sapers/models/styles.dart';
import 'package:sapers/models/texts.dart';

class SearchBarCustom extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSearch;
  final Function(String) onModuleSelected;
  final List<String> modules;
  final String selectedModule;
  final String tag;
  final VoidCallback onDeleteTag;

  const SearchBarCustom({
    super.key,
    required this.controller,
    required this.tag,
    required this.onSearch,
    required this.onModuleSelected,
    required this.modules,
    required this.selectedModule,
    required this.onDeleteTag,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppStyles.borderRadiusValue),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: SizedBox(
          height:
              MediaQuery.of(context).size.height / 19, // Altura más compacta
          child: Row(
            children: [
              // Mostrar el TagBubble si hay un tag seleccionado
              if (tag.isNotEmpty && tag != "null")
                TagBubble(
                  tag: tag,
                  onDelete: onDeleteTag, // Función para eliminar el tag
                ),
              // Expande el TextField para ocupar el espacio restante
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                    hintText: Texts.translate(
                        'buscar', LanguageProvider().currentLanguage),
                    // Eliminar todos los bordes
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    isDense: true, // Reducir altura intern
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PopupMenuButton<String>(
                          icon: Stack(
                            children: [
                              const Icon(Icons.filter_list,
                                  size: 15, color: Colors.grey),
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
                          tooltip: Texts.translate('filtrarPorModulo',
                              LanguageProvider().currentLanguage),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                AppStyles.borderRadiusValue),
                          ),
                          elevation: 2,
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
                                      if (selectedModule == module)
                                        const Spacer(),
                                      if (selectedModule == module)
                                        Icon(
                                          Icons.check,
                                          color: Theme.of(context).primaryColor,
                                          size: AppStyles.fontSize,
                                        ),
                                    ],
                                  ),
                                )),
                          ],
                          onSelected: onModuleSelected,
                        ),
                        IconButton(
                          iconSize: 15.0,
                          icon: const Icon(Icons.search, color: Colors.grey),
                          onPressed: onSearch,
                        ),
                      ],
                    ),
                  ),
                  onSubmitted: (_) => onSearch(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget TagBubble mejorado
class TagBubble extends StatelessWidget {
  final String tag;
  final VoidCallback onDelete;

  const TagBubble({
    Key? key,
    required this.tag,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 6), // Padding ajustado
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: AppStyles.colorAvatarBorder.withOpacity(0.5), // Color de fondo
        borderRadius: BorderRadius.circular(20), // Bordes redondeados
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tag,
            style: const TextStyle(
              color: Colors.white, // Color del texto
              fontSize: 12, // Tamaño de fuente aumentado
              fontWeight: FontWeight.w500, // Peso de la fuente
            ),
          ),
          const SizedBox(width: 6), // Espacio entre el texto y el ícono
          GestureDetector(
            onTap: onDelete,
            child: const Icon(
              Icons.close,
              size: 16,
              color: Color.fromARGB(255, 255, 198, 113), // Color del ícono
            ),
          ),
        ],
      ),
    );
  }
}
