import 'feed_post.dart';

/// Placeholder feed content for the scaffold. Real data arrives when we wire the
/// `feed()` RPC (Supabase, pending go-ahead). Photos are Unsplash placeholders.
String _img(String id, {int w = 520, int h = 700}) =>
    'https://images.unsplash.com/photo-$id?w=$w&h=$h&fit=crop&q=80';

const _faces = 'fit=crop&crop=faces&q=80';
String _avatar(String id) =>
    'https://images.unsplash.com/photo-$id?w=140&h=140&$_faces';

final List<FeedPost> mockFeed = [
  FeedPost(
    id: '1',
    authorId: 'u1',
    authorName: 'Mara Liu',
    initials: 'ML',
    aesthetic: 'Quiet Luxury',
    height: "5'6\"",
    size: 'S',
    matchPct: 94,
    likes: '2.5k',
    imageUrl: _img('1534404483017-8743b4e935cd', h: 680),
  ),
  FeedPost(
    id: '2',
    authorId: 'u2',
    authorName: 'Ella James',
    initials: 'EJ',
    aesthetic: 'Off-Duty',
    height: "5'7\"",
    size: 'M',
    matchPct: 91,
    likes: '3.1k',
    imageUrl: _img('1561398007-f3da3dc9d02f', h: 720),
  ),
  FeedPost(
    id: '3',
    authorId: 'u3',
    authorName: 'Sofia Reyes',
    initials: 'SR',
    aesthetic: 'Romantic',
    height: "5'5\"",
    size: 'S',
    matchPct: 88,
    likes: '1.9k',
    imageUrl: _img('1547069553-12f23c839aaa', h: 760),
  ),
  FeedPost(
    id: '4',
    authorId: 'u4',
    authorName: 'Anya Park',
    initials: 'AP',
    aesthetic: 'Minimal Chic',
    height: "5'8\"",
    size: 'S',
    matchPct: 96,
    likes: '4.2k',
    imageUrl: _img('1589351189946-b8eb5e170ba6', h: 640),
  ),
  FeedPost(
    id: '5',
    authorId: 'u5',
    authorName: 'Nora Hale',
    initials: 'NH',
    aesthetic: 'Dark Academia',
    height: "5'6\"",
    size: 'S',
    matchPct: 92,
    likes: '3.0k',
    imageUrl: _img('1616847220575-31b062a4cd05', h: 760),
  ),
  FeedPost(
    id: '6',
    authorId: 'u6',
    authorName: 'Jules Khan',
    initials: 'JK',
    aesthetic: 'Soft Girl',
    height: "5'4\"",
    size: 'XS',
    matchPct: 89,
    likes: '1.6k',
    imageUrl: _img('1601324389523-cb9bd3853025', h: 700),
  ),
];

/// Recommended-people row: top similar authors (avatar + match%).
final List<({String id, String name, String avatar, int pct})> mockRecommended = [
  (id: 'u1', name: 'Mara', avatar: _avatar('1534404483017-8743b4e935cd'), pct: 94),
  (id: 'u2', name: 'Ella', avatar: _avatar('1561398007-f3da3dc9d02f'), pct: 91),
  (id: 'u3', name: 'Sofia', avatar: _avatar('1547069553-12f23c839aaa'), pct: 88),
  (id: 'u4', name: 'Anya', avatar: _avatar('1589351189946-b8eb5e170ba6'), pct: 96),
  (id: 'u6', name: 'Jules', avatar: _avatar('1647218947427-d783309440d2'), pct: 89),
];

const feedChips = ['For You', 'Most Similar', 'Trending', 'Your Aesthetic'];
