//
//  LanguageConfig.swift
//  CHIPcade
//
//  Created by Markus Moenig on 29/10/24.
//

import Foundation
import RegexBuilder
import LanguageSupport
//chipcadeReservedIds
//chipcadeReservedOperators
private let chipcadeReservedIds = ["u", "s", "f"]
  //["..", ":", "::", "=", "\\", "|", "<-", "->", "@", "~", "=>"]

// Generate ChipCade reserved identifiers from InstructionType
private var chipcadeReservedOperators: [String] {
    return InstructionType.allCases.map { $0.rawValue.uppercased() }
}

extension LanguageConfiguration {

  /// Language configuration for Haskell (including GHC extensions)
  ///
  public static func build_chipcade(_ languageService: LanguageService? = nil) -> LanguageConfiguration {
    let numberRegex = Regex {
      optNegation
      ChoiceOf {
        Regex{ /0[bB]/; binaryLit }
        Regex{ /0[oO]/; octalLit }
        Regex{ /0[xX]/; hexalLit }
        Regex{ /0[xX]/; hexalLit; "."; hexalLit; Optionally{ hexponentLit } }
        Regex{ decimalLit; "."; decimalLit; Optionally{ exponentLit } }
        Regex{ decimalLit; exponentLit }
        decimalLit
      }
    }
    let identifierRegex = Regex {
      identifierHeadCharacters
      ZeroOrMore {
        CharacterClass(identifierCharacters, .anyOf("'"))
      }
    }
    let symbolCharacter = CharacterClass(.anyOf("!#$%&⋆+./<=>?@\\^|-~:"),
                                         operatorHeadCharacters.subtracting(.anyOf("/=-+!*%<>&|^~?"))),
                                         // This is for the Unicode symbols, but the Haskell spec actually specifies "any Unicode symbol or punctuation".
        operatorRegex   = Regex {
          symbolCharacter
          ZeroOrMore { symbolCharacter }
        }
    return LanguageConfiguration(name: "Haskell",
                                 supportsSquareBrackets: false,
                                 supportsCurlyBrackets: false,
                                 stringRegex: /\"(?:\\\"|[^\"])*+\"/,///^(?:[A-Za-z_][A-Za-z0-9_]*)+:/,
                                 characterRegex: /'(?:\\'|[^']|\\[^']*+)'/,
                                 numberRegex: numberRegex,
                                 singleLineComment: "#",
                                 nestedComment: (open: "{-", close: "-}"),
                                 identifierRegex: identifierRegex,
                                 operatorRegex: operatorRegex,
                                 reservedIdentifiers: chipcadeReservedIds,
                                 reservedOperators: chipcadeReservedOperators,
                                 languageService: languageService)
  }
}
