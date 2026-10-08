import 'package:flutter/material.dart';

class NetImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BorderRadius? radius;
  final BoxFit fit;

  const NetImage({
    super.key,
    this.url,
    this.width,
    this.height,
    this.radius,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      child: Icon(Icons.home_work_outlined, color: Colors.grey.shade400),
    );
    final img = (url == null || url!.isEmpty)
        ? placeholder
        : Image.network(
            url!,
            width: width,
            height: height,
            fit: fit,
            loadingBuilder: (c, child, p) => p == null ? child : placeholder,
            errorBuilder: (_, _, _) => placeholder,
          );
    return radius == null ? img : ClipRRect(borderRadius: radius!, child: img);
  }
}