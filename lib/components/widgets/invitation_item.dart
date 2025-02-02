import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sapers/components/widgets/mesmorphic_popup.dart';
import 'package:sapers/main.dart';
import 'package:sapers/models/firebase_service.dart';
import 'package:sapers/models/styles.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sapers/models/texts.dart';

class MessageItem extends StatefulWidget {
  final QueryDocumentSnapshot<Object?> message;
  final String formattedDate;

  const MessageItem({
    Key? key,
    required this.message,
    required this.formattedDate,
  }) : super(key: key);

  @override
  _MessageItemState createState() => _MessageItemState();
}

class _MessageItemState extends State<MessageItem> {
  late bool isToggled;

  @override
  void initState() {
    super.initState();
    // Inicializa el toggle con el valor de 'accepted' en el mensaje, o false si no existe.
    isToggled = widget.message['accepted'] ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Tooltip(
            message: isToggled
                ? Texts.translate('reject', globalLanguage)
                : Texts.translate('accept', globalLanguage),
            child: Focus(
              child: Switch(
                value: isToggled,
                onChanged: (bool value) async {
                  var currentUser = await FirebaseService().getUserInfoByEmail(
                      FirebaseAuth.instance.currentUser!.email!);

                  if (currentUser?.username != widget.message['to']) {
                  } else {
                    setState(() {
                      isToggled = value;
                    });
                    await FirebaseService().acceptPendingInvitation(
                        widget.message['invitationUid'], isToggled);
                  }
                },
                activeColor: AppStyles.colorAvatarBorder,
                inactiveThumbColor: AppStyles.scaffoldBackgroundColorDar,
                inactiveTrackColor: AppStyles.colorAvatarBorderLighter,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              onTap: () {
                showDialog(
                    context: context,
                    builder: (context) => MesomorphicPopup(
                          text: widget.message['message'],
                          onClose: () => Navigator.pop(context),
                        ));
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Remitente
                  Text(
                    widget.message['from'],
                    style: AppStyles().getTextStyle(
                      context,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Mensaje

                  Text(
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    softWrap: true,
                    widget.message['message'],
                    style: AppStyles().getTextStyle(
                      context,
                      fontSize: AppStyles.fontSize,
                      fontWeight: FontWeight.normal,
                    ),
                  ),

                  const SizedBox(height: 4),
                  // Timestamp formateado
                  Text(
                    widget.formattedDate,
                    style: AppStyles().getTextStyle(
                      context,
                      fontSize: 10,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Toggle Button
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
