import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../Screens/Home.dart';
import '../models/onboarding_info.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingController extends GetxController {
  var selectedPageIndex = 0.obs;
  bool get isLastPage => selectedPageIndex.value == onboardingPages.length - 1;
  var pageController = PageController();

  void forwardAction(BuildContext context) {
    if (isLastPage) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => HomeScreen()),  // Navigate to Home page
      );
    } else {
      pageController.nextPage(duration: 300.milliseconds, curve: Curves.ease);
    }
  }

  List<OnboardingInfo> onboardingPages = [
    OnboardingInfo('assets/Images/841083_688.jpg', 'Mountains Calling??',
        ''),
    OnboardingInfo('assets/Images/2.jpg', 'Community of Trekkers',
        'Connect to all the trekkers worldwide and share your story.'),
    OnboardingInfo('assets/Images/2151129766.jpg', 'Find Hill Stations',
        'Pack your bags and get ready to explore the nearby Hill Stations')
  ];
}
