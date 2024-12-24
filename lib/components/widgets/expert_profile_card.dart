import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sapers/components/widgets/add_review.dart';
import 'package:sapers/main.dart';
import 'package:sapers/models/firebase_service.dart';
import 'package:sapers/models/styles.dart';
import 'package:sapers/models/texts.dart';
import 'package:sapers/models/user.dart';

class SAPExpertProfile extends StatelessWidget {
  final UserInfoPopUp profile;

  const SAPExpertProfile({
    required this.profile,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildExperienceSection(context),
            const SizedBox(height: 16),
            _buildReviewsSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildExperienceSection(context) {
    return Card(
      color: AppStyles().getCardColor(context),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppStyles.borderRadiusValue),
        side: BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(Texts.translate('experiencia', globalLanguage),
                    style: AppStyles().getTextStyle(context)),
              ],
            ),
            const SizedBox(height: 16),
            if (profile.experience != null)
              Text(
                profile.experience!,
                style: AppStyles().getTextStyle(context),
              )
          ],
        ),
      ),
    );
  }

  void _showAddReviewDialog(BuildContext context, String username) async {
    final result = await showDialog(
      context: context,
      builder: (context) => AddReviewDialog(username: username),
    );

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reseña añadida con éxito')),
      );
    } else if (result == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al añadir la reseña')),
      );
    }
  }

  Widget _buildReviewsSection(BuildContext context) {
    return Card(
      color: AppStyles().getCardColor(context),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppStyles.borderRadiusValue),
        side: BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  Texts.translate('reviews', globalLanguage),
                  style: AppStyles().getTextStyle(context),
                ),
                IconButton(
                    onPressed: () {
                      _showAddReviewDialog(context, profile.username);
                    },
                    icon: const Icon(Icons.add))
              ],
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseService().getReviews(profile
                  .username), // Aquí estamos usando el stream directo de Firestore
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No reviews yet',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  );
                }

                final reviews =
                    snapshot.data?.docs.first['reviews'] as List? ?? [];

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: reviews.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 32, thickness: 0.5),
                  itemBuilder: (context, index) {
                    final review = reviews[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: List.generate(
                            5,
                            (starIndex) => Icon(
                              starIndex < int.parse(review['rating'].toString())
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.amber,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          review['review'],
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            )
          ],
        ),
      ),
    );
  }
}
