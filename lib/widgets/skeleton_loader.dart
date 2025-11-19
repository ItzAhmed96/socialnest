import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonLoader extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final EdgeInsets margin;

  const SkeletonLoader({
    super.key,
    this.width = double.infinity,
    this.height = 20,
    this.borderRadius = 8,
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Shimmer.fromColors(
          baseColor: Colors.white.withOpacity(0.1),
          highlightColor: Colors.white.withOpacity(0.2),
          child: Container(
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class PostSkeleton extends StatelessWidget {
  const PostSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Header skeleton
          Row(
            children: [
              const SkeletonLoader(width: 40, height: 40, borderRadius: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SkeletonLoader(height: 16, margin: EdgeInsets.only(bottom: 6)),
                    const SkeletonLoader(height: 12, width: 100),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Content skeleton
          const SkeletonLoader(height: 16, margin: EdgeInsets.only(bottom: 8)),
          const SkeletonLoader(height: 16, margin: EdgeInsets.only(bottom: 8)),
          const SkeletonLoader(height: 16, width: 200),
          const SizedBox(height: 16),
          // Image skeleton
          const SkeletonLoader(height: 200, borderRadius: 12),
          const SizedBox(height: 16),
          // Actions skeleton
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildActionSkeleton(),
              _buildActionSkeleton(),
              _buildActionSkeleton(),
              _buildActionSkeleton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionSkeleton() {
    return const Row(
      children: [
        SkeletonLoader(width: 20, height: 20, borderRadius: 10),
        SizedBox(width: 6),
        SkeletonLoader(width: 40, height: 16),
      ],
    );
  }
}

class StorySkeleton extends StatelessWidget {
  const StorySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          const SizedBox(height: 8),
          const SkeletonLoader(width: 70, height: 12),
        ],
      ),
    );
  }
}