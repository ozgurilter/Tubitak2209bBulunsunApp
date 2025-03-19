import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:scooter/preLogin/welcomeScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widget/introPageDesign.dart';

class IntroScreen extends StatefulWidget {
  @override
  _IntroScreenState createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;
  bool _isLastPage = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
      _isLastPage = page == 2;
    });
  }

  void _nextPage() {
    if (_isLastPage) {
      _finishIntro();
    } else {
      _controller.nextPage(
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    _controller.previousPage(
      duration: Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _finishIntro() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboardingComplete', true);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => WelcomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: PageView(
          controller: _controller,
          onPageChanged: _onPageChanged,
          children: [
            IntroPageDesign(
              primaryColor: Color(0xFF416FDF),
              secondaryColor: Color(0xFF2E5BBF),
              icon: FontAwesomeIcons.user,
              title: 'Hoş Geldiniz!',
              description: 'Scooterlar, hızlı ve çevre dostu ulaşım için mükemmel bir seçenektir.',
              currentPage: _currentPage,
              totalPages: 3,
              onNextPressed: _nextPage,
              onPreviousPressed: _previousPage,
              isLastPage: _isLastPage,
            ),
            IntroPageDesign(
              primaryColor: Color(0xFF34D399),
              secondaryColor: Color(0xFF059669),
              icon: FontAwesomeIcons.map,
              title: 'Keşfet!',
              description: 'Şehirdeki en iyi yerleri scooter ile keşfetmeye başlayın.',
              currentPage: _currentPage,
              totalPages: 3,
              onNextPressed: _nextPage,
              onPreviousPressed: _previousPage,
              isLastPage: _isLastPage,
            ),
            IntroPageDesign(
              primaryColor: Color(0xFFFB923C),
              secondaryColor: Color(0xFFF97316),
              icon: FontAwesomeIcons.mapMarkedAlt,
              title: 'Başlayalım!',
              description: 'Hızlı ve keyifli bir yolculuk için hemen scooter kiralayın!',
              currentPage: _currentPage,
              totalPages: 3,
              onNextPressed: _nextPage,
              onPreviousPressed: _previousPage,
              isLastPage: _isLastPage,
            ),
          ],
        ),
      ),
    );
  }
}