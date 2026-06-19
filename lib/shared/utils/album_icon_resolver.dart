import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

/// Maps album titles to Lucide icons via bilingual keyword contains-match.
abstract final class AlbumIconResolver {
  static IconData resolve(String albumName) {
    final normalized = albumName.toLowerCase();
    for (final rule in _rules) {
      if (rule.keywords.any(normalized.contains)) {
        return rule.icon;
      }
    }
    return LucideIcons.image;
  }

  static const _rules = <_AlbumIconRule>[
    _AlbumIconRule(
      ['截图', 'screenshot', 'screen shot'],
      LucideIcons.monitor_smartphone,
    ),
    _AlbumIconRule(
      ['自拍', 'selfie', 'portrait', '人像'],
      LucideIcons.user,
    ),
    _AlbumIconRule(
      ['视频', 'video', 'movie', '影片'],
      LucideIcons.video,
    ),
    _AlbumIconRule(
      ['收藏', 'favorite', 'favourite', '喜欢', '最爱'],
      LucideIcons.star,
    ),
    _AlbumIconRule(
      ['旅行', '旅游', 'trip', 'travel', 'vacation', '假日'],
      LucideIcons.plane,
    ),
    _AlbumIconRule(
      ['宠物', '猫', '狗', 'pet', 'cat', 'dog', 'puppy', 'kitten'],
      LucideIcons.dog,
    ),
    _AlbumIconRule(
      ['美食', '吃', '餐', 'food', 'dining', 'restaurant', 'cook'],
      LucideIcons.utensils,
    ),
    _AlbumIconRule(
      ['工作', '文档', '办公', 'work', 'document', 'doc'],
      LucideIcons.folder,
    ),
    _AlbumIconRule(
      ['最近', 'recents', 'recent', '相机', 'camera roll', 'camera'],
      LucideIcons.camera,
    ),
    _AlbumIconRule(
      ['家庭', '家人', 'family', 'baby', '宝宝', '孩子'],
      LucideIcons.heart,
    ),
    _AlbumIconRule(
      ['全景', 'panorama'],
      LucideIcons.image,
    ),
    _AlbumIconRule(
      ['实况', 'live photo', 'live'],
      LucideIcons.smartphone,
    ),
  ];
}

class _AlbumIconRule {
  const _AlbumIconRule(this.keywords, this.icon);

  final List<String> keywords;
  final IconData icon;
}
