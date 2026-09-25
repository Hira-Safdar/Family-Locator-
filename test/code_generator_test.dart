import 'package:flutter_test/flutter_test.dart'; // Flutter ki test library
import 'package:familylocator/core/utils/code_generator.dart'; // apni class import

void main() { // test ka entry point
  group('CodeGenerator', () { // related tests ka group
    test('generates 6-character codes', () { // test 1: length check
      final code = CodeGenerator.generate();
      expect(code.length, 6); // pass if length 6
    });

    test('generates different codes on repeated calls', () { // test 2: codes repeat na hon
      final a = CodeGenerator.generate();
      final b = CodeGenerator.generate();
      expect(a, isNot(equals(b))); // a != b
    });

    test('uses only unambiguous characters', () { // test 3: sirf safe chars
      final code = CodeGenerator.generate();
      // regex: A-H, J-N, P-Z aur 2-9 ka combination, exactly 6
      expect(code, matches(RegExp(r'^[A-HJ-NP-Z2-9]{6}$')));
    });
  });
}