import 'package:flutter/widgets.dart';

/// Static option sets for onboarding. Mirrors `docs/design.md` §7 taxonomies.
/// Frontend-only placeholder data; real persistence arrives with Supabase.

String _img(String id) =>
    'https://images.unsplash.com/photo-$id?w=300&h=220&fit=crop&q=80';

class Aesthetic {
  const Aesthetic(this.name, this.image);
  final String name;
  final String image;
}

const aesthetics = <Aesthetic>[
  Aesthetic('Quiet Luxury', ''),
  Aesthetic('Off-Duty', ''),
  Aesthetic('Minimal Chic', ''),
  Aesthetic('Dark Academia', ''),
  Aesthetic('Romantic', ''),
  Aesthetic('Streetwear', ''),
];

final aestheticImages = <String, String>{
  'Quiet Luxury': _img('1534404483017-8743b4e935cd'),
  'Off-Duty': _img('1561398007-f3da3dc9d02f'),
  'Minimal Chic': _img('1589351189946-b8eb5e170ba6'),
  'Dark Academia': _img('1616847220575-31b062a4cd05'),
  'Romantic': _img('1547069553-12f23c839aaa'),
  'Streetwear': _img('1601324389523-cb9bd3853025'),
};

/// Body-type sets shown in the teaser (decoupled from gender identity).
enum BodyTypeSet { women, men, both }

/// Body silhouettes — standard fashion-industry names (Hourglass, Pear, …) with
/// a plain, non-prescriptive descriptor (`docs/brand.md` inclusivity ethos).
enum SilhouetteShape { hourglass, pear, rectangle, apple, invertedTriangle }

const silhouetteLabels = <SilhouetteShape, String>{
  SilhouetteShape.hourglass: 'Hourglass',
  SilhouetteShape.pear: 'Pear',
  SilhouetteShape.rectangle: 'Rectangle',
  SilhouetteShape.apple: 'Apple / Round',
  SilhouetteShape.invertedTriangle: 'Inverted Triangle',
};

const silhouetteDescriptors = <SilhouetteShape, String>{
  SilhouetteShape.hourglass: 'Balanced, defined waist',
  SilhouetteShape.pear: 'Fuller hips',
  SilhouetteShape.rectangle: 'Straight up and down',
  SilhouetteShape.apple: 'Fuller midsection',
  SilhouetteShape.invertedTriangle: 'Broader shoulders',
};

/// Skin undertone — the second axis of accurate color matching (depth is Monk).
enum Undertone { warm, cool, neutral }

const undertoneLabels = <Undertone, String>{
  Undertone.warm: 'Warm',
  Undertone.cool: 'Cool',
  Undertone.neutral: 'Neutral',
};

const undertoneHints = <Undertone, String>{
  Undertone.warm: 'Golden / peachy · gold jewelry suits you',
  Undertone.cool: 'Pink / bluish · silver jewelry suits you',
  Undertone.neutral: 'A balance of both',
};

/// Monk 10-tone skin scale (ordinal 1→10, light→deep).
const monkTones = <Color>[
  Color(0xFFF6EDE4),
  Color(0xFFF3E7DB),
  Color(0xFFF7EAD0),
  Color(0xFFEADABA),
  Color(0xFFD7BD96),
  Color(0xFFA07E56),
  Color(0xFF825C43),
  Color(0xFF604134),
  Color(0xFF3A312A),
  Color(0xFF292420),
];

class ColorOption {
  const ColorOption(this.name, this.swatch);
  final String name;
  final Color swatch;
}

const hairColors = <ColorOption>[
  ColorOption('Black', Color(0xFF1A1410)),
  ColorOption('Dark brown', Color(0xFF3A2418)),
  ColorOption('Brown', Color(0xFF5A3A24)),
  ColorOption('Light brown', Color(0xFF8A5A36)),
  ColorOption('Auburn', Color(0xFFB07A3C)),
  ColorOption('Red / ginger', Color(0xFFC4622A)),
  ColorOption('Blonde', Color(0xFFD8B46A)),
  ColorOption('Platinum', Color(0xFFE6DCC8)),
  ColorOption('Gray / silver', Color(0xFFB8B2A8)),
  ColorOption('Colored / dyed', Color(0xFF9C5BA0)),
];

const eyeColors = <ColorOption>[
  ColorOption('Dark brown', Color(0xFF3A2418)),
  ColorOption('Brown', Color(0xFF6B4A2A)),
  ColorOption('Hazel', Color(0xFF8A6A3A)),
  ColorOption('Amber', Color(0xFFB07A2A)),
  ColorOption('Blue', Color(0xFF6A8AA8)),
  ColorOption('Green', Color(0xFF6A7E52)),
  ColorOption('Gray', Color(0xFF8E8E86)),
];
