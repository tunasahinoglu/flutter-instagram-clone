import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class LikeButton extends StatefulWidget {
  final bool isLiked;
  final void Function()? onTap;

  LikeButton({Key? key, required this.isLiked, required this.onTap})
      : super(key: key);

  @override
  _LikeButtonState createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );

    _animation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 2), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 2, end: 1.0), weight: 1),
    ]).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        !widget.isLiked
            ? await _audioPlayer.play(AssetSource('sounds/like.mp3'))
            : null;
        widget.onTap?.call();
        _animationController.forward(from: 0.0);
      },
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _animation.value,
            child: Icon(
              widget.isLiked ? Icons.favorite : Icons.favorite_border,
              color: widget.isLiked ? Colors.red : Colors.grey,
            ),
          );
        },
      ),
    );
  }
}
