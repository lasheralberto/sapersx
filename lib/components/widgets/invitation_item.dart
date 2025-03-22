import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sapers/components/widgets/mesmorphic_popup.dart';
import 'package:sapers/components/widgets/profile_avatar.dart';
import 'package:sapers/main.dart';
import 'package:sapers/models/auth_provider.dart';
import 'package:sapers/models/firebase_service.dart';
import 'package:sapers/models/language_provider.dart';
import 'package:sapers/models/styles.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sapers/models/texts.dart';
import 'package:sapers/models/utils_sapers.dart';

class InvitationItem extends StatefulWidget {
  final QueryDocumentSnapshot<Object?> message;
  final String formattedDate;

  const InvitationItem({
    super.key,
    required this.message,
    required this.formattedDate,
  });

  @override
  _InvitationItemState createState() => _InvitationItemState();
}

class _InvitationItemState extends State<InvitationItem> {
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
                ? Texts.translate('reject', LanguageProvider().currentLanguage)
                : Texts.translate('accept', LanguageProvider().currentLanguage),
            child: Focus(
              child: Switch(
                value: isToggled,
                onChanged: (bool value) async {
                  var currentUser =
                      Provider.of<AuthProviderSapers>(context, listen: false)
                          .userInfo;

                  if (currentUser?.username != widget.message['to']) {
                  } else {
                    setState(() {
                      isToggled = value;
                    });

                    if (isToggled == false) {
                      FirebaseService().removePendingInvitation(
                          widget.message['invitationUid'], isToggled);
                      await FirebaseService().removeUserFromProject(
                          currentUser!.username,
                          widget.message['invitationUid']);
                      return;
                    }

                    bool isAccepted = await FirebaseService()
                        .acceptPendingInvitation(
                            widget.message['invitationUid'],
                            isToggled,
                            widget.message['to']);

                    if (isAccepted) {
                      await FirebaseService().addUserToProject(
                          currentUser!.username,
                          widget.message['invitationUid'],
                          currentUser);
                      return;
                    }
                  }
                },
                activeColor: AppStyles.colorAvatarBorder,
                inactiveThumbColor: AppStyles.scaffoldBackgroundColorBright,
                inactiveTrackColor: AppStyles.colorAvatarBorderLighter,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              onTap: () {
                UtilsSapers().showTextPopup(context, widget.message['message']);
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Remitente
                  ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.message['projectName'] ?? '',
                          style: AppStyles().getTextStyle(
                            context,
                            fontWeight: FontWeight.bold,
                            fontSize: AppStyles.fontSizeLarge,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.message['message'] ?? '',
                          style: AppStyles().getTextStyle(
                            context,
                            fontSize: AppStyles.fontSize,
                            fontWeight: FontWeight.normal,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                widget.message['from'] ?? '',
                                style: AppStyles().getTextStyle(
                                  context,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).hintColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            Text(
                              widget.formattedDate,
                              style: AppStyles().getTextStyle(
                                context,
                                fontSize: 12,
                                fontWeight: FontWeight.w300,
                                color: Theme.of(context).hintColor,
                              ),
                            ),
                          ],
                        ),
                      ],
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
