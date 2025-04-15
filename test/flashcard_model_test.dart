import 'package:flutter_test/flutter_test.dart';
import 'package:projet/models/flashcard.dart';

void main() {
  group('Flashcard Model Tests', () {
    test('Flashcard creation with all parameters', () {
      final flashcard = Flashcard(
        id: 1,
        front: 'Front text',
        back: 'Back text',
        isKnown: true,
        category: 'Test Category',
        audioPath: '/path/to/audio.mp3',
      );
      
      expect(flashcard.id, 1);
      expect(flashcard.front, 'Front text');
      expect(flashcard.back, 'Back text');
      expect(flashcard.isKnown, true);
      expect(flashcard.category, 'Test Category');
      expect(flashcard.audioPath, '/path/to/audio.mp3');
    });
    
    test('Flashcard to Map conversion', () {
      final flashcard = Flashcard(
        id: 1,
        front: 'Front text',
        back: 'Back text',
        isKnown: true,
        category: 'Test Category',
        audioPath: '/path/to/audio.mp3',
      );
      
      final map = flashcard.toMap();
      
      expect(map['id'], 1);
      expect(map['front'], 'Front text');
      expect(map['back'], 'Back text');
      expect(map['is_known'], 1);  // true est converti en 1
      expect(map['category'], 'Test Category');
      expect(map['audio_path'], '/path/to/audio.mp3');
    });
    
    test('Flashcard from Map conversion', () {
      final map = {
        'id': 1,
        'front': 'Front text',
        'back': 'Back text',
        'is_known': 1,
        'category': 'Test Category',
        'audio_path': '/path/to/audio.mp3',
      };
      
      final flashcard = Flashcard.fromMap(map);
      
      expect(flashcard.id, 1);
      expect(flashcard.front, 'Front text');
      expect(flashcard.back, 'Back text');
      expect(flashcard.isKnown, true);  // 1 est converti en true
      expect(flashcard.category, 'Test Category');
      expect(flashcard.audioPath, '/path/to/audio.mp3');
    });
  });
}
