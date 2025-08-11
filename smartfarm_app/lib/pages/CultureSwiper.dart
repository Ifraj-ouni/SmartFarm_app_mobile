import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';

class CultureSwiper extends StatelessWidget {
  CultureSwiper({super.key});

  final List<String> images = [
    'images/olive.jpg',
    'images/lemon.jpg',
    'images/grapes.jpg',
    'images/tomato.jpg',
    'images/grenadine.jpg',
    'images/dattes.jpg',
    'images/orange.jpg',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: Swiper(
        itemBuilder: (BuildContext context, int index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12), // Arrondir les coins
            child: Image.asset(
              images[index],
              fit: BoxFit.cover,
              gaplessPlayback: true,
              cacheWidth: MediaQuery.of(context).size.width.toInt(), // Optimisation cache
            ),
          );
        },
        itemCount: images.length,
        pagination: const SwiperPagination(
          margin: EdgeInsets.all(5.0),
          builder: DotSwiperPaginationBuilder(
            color: Colors.grey,
            activeColor: Colors.white,
            size: 8.0,
            activeSize: 10.0,
          ),
        ),
        control: const SwiperControl(
          color: Colors.white,
        ),
        autoplay: true,
        autoplayDelay: 3000, // 3 secondes entre chaque slide
        duration: 500, // Durée de l'animation entre slides
        viewportFraction: 1, // Réduit légèrement la taille pour voir le suivant
        scale: 0.9, // Effet de zoom
      ),
    );
  }
}