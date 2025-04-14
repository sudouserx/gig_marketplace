import 'package:flutter/material.dart';

class RatingWidget extends StatelessWidget {
  final double rating;
  final double size;
  final Function(double)? onRatingChanged;

  const RatingWidget({
    Key? key,
    required this.rating,
    this.size = 24,
    this.onRatingChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (index) {
        return GestureDetector(
          onTap: onRatingChanged != null ? () => onRatingChanged!(index + 1) : null,
          child: Icon(
            index < rating ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: size,
          ),
        );
      }),
    );
  }
}