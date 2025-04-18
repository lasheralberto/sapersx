import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sapers/components/widgets/add_review.dart';
import 'package:sapers/models/firebase_service.dart';
import 'package:sapers/models/language_provider.dart';
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 108.0),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildExperienceSection(context)),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          SliverToBoxAdapter(child: _buildReviewsSection(context)),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }

  Widget _buildExperienceSection(context) {
    return Card(
      color: Theme.of(context).cardColor,
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
                Text(
                  Texts.translate(
                      'experiencia', LanguageProvider().currentLanguage),
                  style: AppStyles().getTextStyle(context,
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
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
                  Texts.translate(
                      'reviews', LanguageProvider().currentLanguage),
                  style: AppStyles().getTextStyle(context,
                      fontSize: 16, fontWeight: FontWeight.bold),
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
              stream: FirebaseService().getReviews(profile.username),
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
                        Text(review['review'],
                            style: AppStyles().getTextStyle(context,
                                fontSize: AppStyles.fontSize,
                                fontWeight: FontWeight.normal)),
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
}
