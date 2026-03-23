import 'dart:convert';
import 'package:http/http.dart' as http;

/// Spotify search via the PWA's API proxy.
/// Uses client credentials flow (no user auth needed for search).
class SpotifyService {
  static const _base = 'https://smarthome-eight-livid.vercel.app/api/spotify';

  /// Search Spotify for tracks, albums, artists, playlists
  static Future<SpotifyResults> search(String query) async {
    if (query.trim().isEmpty) return SpotifyResults.empty();
    final resp = await http.get(
      Uri.parse('$_base?q=${Uri.encodeComponent(query.trim())}'),
    ).timeout(const Duration(seconds: 10));
    if (resp.statusCode != 200) throw Exception('Spotify search failed: ${resp.statusCode}');
    final d = json.decode(resp.body);
    return SpotifyResults.fromJson(d);
  }

  /// Get artist details + top tracks + albums
  static Future<SpotifyResults> getArtist(String artistId) async {
    final resp = await http.get(Uri.parse('$_base?artist_id=$artistId')).timeout(const Duration(seconds: 10));
    if (resp.statusCode != 200) throw Exception('Spotify artist failed: ${resp.statusCode}');
    return SpotifyResults.fromJson(json.decode(resp.body));
  }

  /// Get album tracks
  static Future<SpotifyResults> getAlbum(String albumId) async {
    final resp = await http.get(Uri.parse('$_base?album_id=$albumId')).timeout(const Duration(seconds: 10));
    if (resp.statusCode != 200) throw Exception('Spotify album failed: ${resp.statusCode}');
    return SpotifyResults.fromJson(json.decode(resp.body));
  }
}

class SpotifyResults {
  final List<SpotifyTrack> tracks;
  final List<SpotifyAlbum> albums;
  final List<SpotifyArtist> artists;
  final List<SpotifyPlaylist> playlists;
  final SpotifyArtistInfo? artistInfo;
  final SpotifyAlbumInfo? albumInfo;

  SpotifyResults({required this.tracks, required this.albums, required this.artists, required this.playlists, this.artistInfo, this.albumInfo});

  factory SpotifyResults.empty() => SpotifyResults(tracks: [], albums: [], artists: [], playlists: []);

  factory SpotifyResults.fromJson(Map<String, dynamic> j) => SpotifyResults(
    tracks: (j['tracks'] as List? ?? []).map((t) => SpotifyTrack.fromJson(t)).toList(),
    albums: (j['albums'] as List? ?? []).map((a) => SpotifyAlbum.fromJson(a)).toList(),
    artists: (j['artists'] as List? ?? []).map((a) => SpotifyArtist.fromJson(a)).toList(),
    playlists: (j['playlists'] as List? ?? []).map((p) => SpotifyPlaylist.fromJson(p)).toList(),
    artistInfo: j['artistInfo'] != null ? SpotifyArtistInfo.fromJson(j['artistInfo']) : null,
    albumInfo: j['albumInfo'] != null ? SpotifyAlbumInfo.fromJson(j['albumInfo']) : null,
  );
}

class SpotifyTrack {
  final String id, uri, name;
  final String? artist, album, art;
  final int? duration;

  SpotifyTrack({required this.id, required this.uri, required this.name, this.artist, this.album, this.art, this.duration});

  factory SpotifyTrack.fromJson(Map<String, dynamic> j) => SpotifyTrack(
    id: j['id'] ?? '', uri: j['uri'] ?? '', name: j['name'] ?? '',
    artist: j['artist'], album: j['album'], art: j['art'], duration: j['duration'],
  );

  String get durationStr {
    if (duration == null) return '';
    final m = duration! ~/ 60000;
    final s = (duration! % 60000) ~/ 1000;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

class SpotifyAlbum {
  final String id, uri, name;
  final String? artist, art, year, type;

  SpotifyAlbum({required this.id, required this.uri, required this.name, this.artist, this.art, this.year, this.type});

  factory SpotifyAlbum.fromJson(Map<String, dynamic> j) => SpotifyAlbum(
    id: j['id'] ?? '', uri: j['uri'] ?? '', name: j['name'] ?? '',
    artist: j['artist'], art: j['art'], year: j['year'], type: j['type'],
  );
}

class SpotifyArtist {
  final String id, uri, name;
  final String? art;
  final List<String> genres;
  final int? followers;

  SpotifyArtist({required this.id, required this.uri, required this.name, this.art, this.genres = const [], this.followers});

  factory SpotifyArtist.fromJson(Map<String, dynamic> j) => SpotifyArtist(
    id: j['id'] ?? '', uri: j['uri'] ?? '', name: j['name'] ?? '',
    art: j['art'], genres: List<String>.from(j['genres'] ?? []), followers: j['followers'],
  );
}

class SpotifyPlaylist {
  final String id, uri, name;
  final String? owner, art;
  final int? totalTracks;

  SpotifyPlaylist({required this.id, required this.uri, required this.name, this.owner, this.art, this.totalTracks});

  factory SpotifyPlaylist.fromJson(Map<String, dynamic> j) => SpotifyPlaylist(
    id: j['id'] ?? '', uri: j['uri'] ?? '', name: j['name'] ?? '',
    owner: j['owner'], art: j['art'], totalTracks: j['tracks'],
  );
}

class SpotifyArtistInfo {
  final String id, uri, name;
  final String? art;
  final List<String> genres;
  final int? followers;

  SpotifyArtistInfo({required this.id, required this.uri, required this.name, this.art, this.genres = const [], this.followers});

  factory SpotifyArtistInfo.fromJson(Map<String, dynamic> j) => SpotifyArtistInfo(
    id: j['id'] ?? '', uri: j['uri'] ?? '', name: j['name'] ?? '',
    art: j['art'], genres: List<String>.from(j['genres'] ?? []), followers: j['followers'],
  );
}

class SpotifyAlbumInfo {
  final String id, uri, name;
  final String? artist, art, year;
  final int? total;

  SpotifyAlbumInfo({required this.id, required this.uri, required this.name, this.artist, this.art, this.year, this.total});

  factory SpotifyAlbumInfo.fromJson(Map<String, dynamic> j) => SpotifyAlbumInfo(
    id: j['id'] ?? '', uri: j['uri'] ?? '', name: j['name'] ?? '',
    artist: j['artist'], art: j['art'], year: j['year'], total: j['total'],
  );
}
