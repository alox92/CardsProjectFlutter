import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart'; // Ajout pour génération robuste d'UUIDs

@immutable
class Flashcard {
  /// ID auto-incrémenté local.
  final int? id;
  /// Identifiant unique global pour la synchronisation.
  final String? uuid;
  /// Texte affiché sur le recto de la carte.
  final String front;
  /// Texte affiché sur le verso de la carte.
  final String back;
  /// Indique si la carte est connue.
  final bool isKnown;
  /// Catégorie de la carte.
  final String? category;
  /// Chemin vers le fichier audio associé à la carte.
  final String? audioPath;
  /// Timestamp (millisecondes depuis epoch) pour la synchronisation.
  final int? lastModified;
  /// Indique si la carte est supprimée (soft delete).
  final bool isDeleted;
  /// Nombre de révisions de cette carte
  final int reviewCount;
  /// Dernière date de révision (timestamp)
  final int? lastReviewed;
  /// Score de difficulté (0-100, plus le score est élevé, plus la carte est difficile)
  final int difficultyScore;
  /// Données personnalisées (stockées en JSON)
  final Map<String, dynamic>? customData;

  const Flashcard({
    this.id,
    this.uuid,
    required this.front,
    required this.back,
    this.isKnown = false,
    this.category,
    this.audioPath,
    this.lastModified,
    this.isDeleted = false,
    this.reviewCount = 0,
    this.lastReviewed,
    this.difficultyScore = 50, // Difficulté moyenne par défaut
    this.customData,
  });

  /// Liste des champs supportés (utile pour CSV/JSON).
  static const List<String> fields = [
    'id', 'uuid', 'front', 'back', 'is_known', 'category', 
    'audio_path', 'last_modified', 'is_deleted',
    'review_count', 'last_reviewed', 'difficulty_score', 'custom_data'
  ];

  /// Retourne true si la carte est vide (recto ou verso vide).
  bool get isEmpty => front.trim().isEmpty || back.trim().isEmpty;

  /// Retourne true si la carte est valide (recto et verso non vides).
  bool get isValid => front.trim().isNotEmpty && back.trim().isNotEmpty;

  /// Indique si la carte a un fichier audio associé valide
  bool get hasAudio => audioPath != null && audioPath!.trim().isNotEmpty;

  /// Indique si cette carte a été révisée au moins une fois
  bool get hasBeenReviewed => reviewCount > 0;
  
  /// Retourne le nombre de jours depuis la dernière révision
  int? get daysSinceLastReview {
    if (lastReviewed == null) return null;
    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = now - lastReviewed!;
    return (diff / (1000 * 60 * 60 * 24)).floor();
  }
  
  /// Retourne true si la carte est due pour révision (non révisée depuis plus de X jours)
  bool isDueForReview(int daysThreshold) {
    final days = daysSinceLastReview;
    return days == null || days >= daysThreshold;
  }

  /// Génère un nouvel UUID RFC4122 v4 (standard).
  static String generateUuid() {
    try {
      return const Uuid().v4();
    } catch (e) {
      // Fallback en cas d'erreur
      return '${DateTime.now().millisecondsSinceEpoch}_${UniqueKey().toString().replaceAll('#', '')}';
    }
  }

  /// Compare deux cartes sans tenir compte de l'ID local.
  bool contentEquals(Flashcard other) {
    return uuid == other.uuid &&
        front == other.front &&
        back == other.back &&
        isKnown == other.isKnown &&
        category == other.category &&
        audioPath == other.audioPath &&
        lastModified == other.lastModified &&
        isDeleted == other.isDeleted &&
        reviewCount == other.reviewCount &&
        lastReviewed == other.lastReviewed &&
        difficultyScore == other.difficultyScore;
  }

  /// Crée une copie de la carte avec des champs modifiés.
  Flashcard copyWith({
    int? id,
    String? uuid,
    String? front,
    String? back,
    bool? isKnown,
    String? category,
    String? audioPath,
    int? lastModified,
    bool? isDeleted,
    int? reviewCount,
    int? lastReviewed,
    int? difficultyScore,
    Map<String, dynamic>? customData,
  }) {
    return Flashcard(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      front: front ?? this.front,
      back: back ?? this.back,
      isKnown: isKnown ?? this.isKnown,
      category: category ?? this.category,
      audioPath: audioPath ?? this.audioPath,
      lastModified: lastModified ?? this.lastModified,
      isDeleted: isDeleted ?? this.isDeleted,
      reviewCount: reviewCount ?? this.reviewCount,
      lastReviewed: lastReviewed ?? this.lastReviewed,
      difficultyScore: difficultyScore ?? this.difficultyScore,
      customData: customData ?? this.customData,
    );
  }

  /// Crée une carte avec des statistiques de révision mises à jour
  Flashcard withReviewStats({
    required bool correct, 
    int? newDifficultyScore,
    bool markAsKnown = false,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    
    // Calculer le nouveau score de difficulté si non fourni
    final calculatedDifficultyScore = newDifficultyScore ?? _calculateNewDifficultyScore(correct);
    
    return copyWith(
      reviewCount: reviewCount + 1,
      lastReviewed: now,
      difficultyScore: calculatedDifficultyScore,
      isKnown: markAsKnown ? true : isKnown,
      lastModified: now,
    );
  }
  
  /// Calcule un nouveau score de difficulté en fonction de la réponse
  int _calculateNewDifficultyScore(bool correct) {
    // Algorithme simple: augmenter ou diminuer le score de difficulté
    // On pourrait implémenter un algorithme plus sophistiqué comme SM-2 ici
    final int change = correct ? -5 : 10; // Les réponses incorrectes ont plus d'impact
    return (difficultyScore + change).clamp(0, 100);
  }

  /// Convertit la carte en map pour la base de données.
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = {
      'id': id,
      'uuid': uuid,
      'front': front,
      'back': back,
      'is_known': isKnown ? 1 : 0,
      'category': category,
      'audio_path': audioPath,
      'last_modified': lastModified ?? DateTime.now().millisecondsSinceEpoch,
      'is_deleted': isDeleted ? 1 : 0,
      'review_count': reviewCount,
      'last_reviewed': lastReviewed,
      'difficulty_score': difficultyScore,
    };
    
    // Ajouter les données personnalisées si présentes
    if (customData != null && customData!.isNotEmpty) {
      map['custom_data'] = jsonEncode(customData);
    }
    
    return map;
  }

  /// Sérialise la carte en JSON (pour la synchro réseau).
  Map<String, dynamic> toJson() => toMap();

  /// Crée une carte à partir d'une map de la base de données.
  factory Flashcard.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic>? parsedCustomData;
    
    // Parser les données personnalisées si présentes
    if (map['custom_data'] != null && map['custom_data'] is String) {
      try {
        parsedCustomData = jsonDecode(map['custom_data']) as Map<String, dynamic>;
      } catch (e) {
        // Ignorer les erreurs de parsing
      }
    }
    
    return Flashcard(
      id: map['id'],
      uuid: map['uuid'],
      front: map['front'] ?? '',
      back: map['back'] ?? '',
      isKnown: _parseBool(map['is_known']),
      category: map['category'],
      audioPath: map['audio_path'],
      lastModified: map['last_modified'],
      isDeleted: _parseBool(map['is_deleted']),
      reviewCount: map['review_count'] is int ? map['review_count'] : 0,
      lastReviewed: map['last_reviewed'],
      difficultyScore: map['difficulty_score'] is int ? map['difficulty_score'] : 50,
      customData: parsedCustomData,
    );
  }

  /// Désérialise une carte depuis un JSON.
  static Flashcard fromJson(Map<String, dynamic> json) => Flashcard.fromMap(json);

  /// Parser multi-format pour les valeurs booléennes
  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return false;
  }

  /// Affichage compact pour debug/log.
  String toShortString() =>
      '[$uuid] "$front" / "$back" (${isKnown ? "✓" : "✗"})'
      '${category != null ? " [$category]" : ""}'
      '${isDeleted ? " (deleted)" : ""}'
      ' - ${reviewCount}x';

  /// Retourne une version abrégée de la carte pour l'affichage dans les listes ou logs.
  String get summary =>
      '[${uuid?.substring(0, 8) ?? "no-uuid"}] "${front.length > 20 ? front.substring(0, 20) + "…" : front}"'
      ' / "${back.length > 20 ? back.substring(0, 20) + "…" : back}"'
      '${category != null && category!.isNotEmpty ? " [$category]" : ""}'
      '${isKnown ? " ✓" : ""}'
      '${isDeleted ? " (deleted)" : ""}'
      ' - Rev: $reviewCount';

  /// Retourne une version multi-ligne détaillée pour debug.
  String debugString() => '''
Flashcard(
  id: $id,
  uuid: $uuid,
  front: "$front",
  back: "$back",
  isKnown: $isKnown,
  category: $category,
  audioPath: $audioPath,
  lastModified: $lastModified,
  isDeleted: $isDeleted,
  reviewCount: $reviewCount,
  lastReviewed: ${lastReviewed != null ? DateTime.fromMillisecondsSinceEpoch(lastReviewed!).toIso8601String() : 'null'},
  difficultyScore: $difficultyScore
)''';

  /// Convertit une liste de cartes au format CSV
  static String toCsv(List<Flashcard> cards) {
    final StringBuffer buffer = StringBuffer();
    
    // Écrire l'en-tête
    buffer.writeln('front,back,category,is_known,review_count,difficulty_score');
    
    // Écrire les données
    for (final card in cards) {
      buffer.writeln([
        _escapeCsvField(card.front),
        _escapeCsvField(card.back),
        _escapeCsvField(card.category ?? ''),
        card.isKnown ? '1' : '0',
        card.reviewCount.toString(),
        card.difficultyScore.toString(),
      ].join(','));
    }
    
    return buffer.toString();
  }
  
  /// Échappe un champ pour le format CSV
  static String _escapeCsvField(String field) {
    if (field.contains('"') || field.contains(',') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }
  
  /// Parse un CSV pour créer des cartes
  static List<Flashcard> fromCsv(String csv) {
    final List<Flashcard> cards = [];
    final List<String> lines = LineSplitter.split(csv).toList();
    
    if (lines.isEmpty) return cards;
    
    // Ignorer l'en-tête
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      
      // Parser la ligne CSV (gère les champs entre guillemets)
      final fields = _parseCsvLine(line);
      
      if (fields.length >= 2) {
        cards.add(Flashcard(
          uuid: generateUuid(),
          front: fields[0],
          back: fields[1],
          category: fields.length > 2 ? fields[2] : null,
          isKnown: fields.length > 3 ? _parseBool(fields[3]) : false,
          reviewCount: fields.length > 4 ? int.tryParse(fields[4]) ?? 0 : 0,
          difficultyScore: fields.length > 5 ? int.tryParse(fields[5]) ?? 50 : 50,
          lastModified: DateTime.now().millisecondsSinceEpoch,
        ));
      }
    }
    
    return cards;
  }
  
  /// Parse une ligne CSV (gestion des guillemets)
  static List<String> _parseCsvLine(String line) {
    List<String> fields = [];
    bool inQuotes = false;
    StringBuffer field = StringBuffer();
    
    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      
      if (char == '"') {
        if (i + 1 < line.length && line[i + 1] == '"') {
          // Double guillemet = échappement
          field.write('"');
          i++; // Sauter le prochain guillemet
        } else {
          // Basculer l'état des guillemets
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        // Fin du champ
        fields.add(field.toString());
        field = StringBuffer();
      } else {
        field.write(char);
      }
    }
    
    // Ajouter le dernier champ
    fields.add(field.toString());
    
    return fields;
  }

  /// Valide une liste de cartes (retourne la liste des cartes invalides).
  static List<Flashcard> findInvalids(Iterable<Flashcard> cards) =>
      cards.where((c) => !c.isValid).toList();

  /// Trier des cartes par difficulté (du plus difficile au plus facile)
  static List<Flashcard> sortByDifficulty(List<Flashcard> cards, {bool descending = true}) {
    final sortedCards = List<Flashcard>.from(cards);
    if (descending) {
      sortedCards.sort((a, b) => b.difficultyScore.compareTo(a.difficultyScore));
    } else {
      sortedCards.sort((a, b) => a.difficultyScore.compareTo(b.difficultyScore));
    }
    return sortedCards;
  }
  
  /// Trier des cartes par date de dernière révision
  static List<Flashcard> sortByLastReviewed(List<Flashcard> cards, {bool oldest = true}) {
    final sortedCards = List<Flashcard>.from(cards);
    sortedCards.sort((a, b) {
      // Mettre les cartes jamais révisées au début
      if (a.lastReviewed == null) return oldest ? -1 : 1;
      if (b.lastReviewed == null) return oldest ? 1 : -1;
      
      // Trier par date
      return oldest 
          ? a.lastReviewed!.compareTo(b.lastReviewed!) 
          : b.lastReviewed!.compareTo(a.lastReviewed!);
    });
    return sortedCards;
  }
  
  /// Trier des cartes par catégorie
  static List<Flashcard> sortByCategory(List<Flashcard> cards) {
    final sortedCards = List<Flashcard>.from(cards);
    sortedCards.sort((a, b) {
      final categoryA = a.category?.toLowerCase() ?? '';
      final categoryB = b.category?.toLowerCase() ?? '';
      return categoryA.compareTo(categoryB);
    });
    return sortedCards;
  }

  /// Retourne une version JSON compacte (pour logs ou API).
  @override
  String toString() => toJson().toString();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Flashcard &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          uuid == other.uuid &&
          front == other.front &&
          back == other.back &&
          isKnown == other.isKnown &&
          category == other.category &&
          audioPath == other.audioPath &&
          lastModified == other.lastModified &&
          isDeleted == other.isDeleted &&
          reviewCount == other.reviewCount &&
          lastReviewed == other.lastReviewed &&
          difficultyScore == other.difficultyScore;

  @override
  int get hashCode =>
      id.hashCode ^
      uuid.hashCode ^
      front.hashCode ^
      back.hashCode ^
      isKnown.hashCode ^
      category.hashCode ^
      audioPath.hashCode ^
      lastModified.hashCode ^
      isDeleted.hashCode ^
      reviewCount.hashCode ^
      lastReviewed.hashCode ^
      difficultyScore.hashCode;

  int? get modifiedAt => lastModified;
}