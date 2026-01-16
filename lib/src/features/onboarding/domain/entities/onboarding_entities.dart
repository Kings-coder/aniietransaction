import 'package:equatable/equatable.dart';

class OnBoardingPageContent extends Equatable {
  const OnBoardingPageContent({
    required this.image,
    required this.title,
    required this.subtitle,
  });

  const OnBoardingPageContent.first()
      : this(
          image: 'assets/images/on_boarding_1.png',
          title: 'Explore \nTrendy Fashion',
          subtitle:
              'Explore the latest trends in the world of fashion \nyou never have to miss a beat.',
        );

  const OnBoardingPageContent.second()
      : this(
          image: 'assets/images/on_boarding_2.png',
          title: 'Select \nYour Style',
          subtitle:
              'From our huge collection of Hauls, Lookbook, \nDIY and GRWM, you can choose the best for you',
        );

  const OnBoardingPageContent.third()
      : this(
          image: 'assets/images/on_boarding_3.png',
          title: 'Express \nYour Essence',
          subtitle:
              'Let your style speak volumes, craft your \nfashion identity with finesse.',
        );

  const OnBoardingPageContent.fourth()
      : this(
          image: 'assets/images/on_boarding_4.png',
          title: 'Own \nYour Originality',
          subtitle:
              'Be a trendsetter, not a follower, infuse your \nlook with timeless elegance',
        );

  const OnBoardingPageContent.last()
      : this(
          image: 'assets/images/on_boarding_5.png',
          title: 'Finesse \nYour Fashion',
          subtitle:
              'Perfect the art of dressing with flair, wear \nyour personality with pride.',
        );

  final String image;
  final String title;
  final String subtitle;

  @override
  List<Object?> get props => [image, title, subtitle];
}
