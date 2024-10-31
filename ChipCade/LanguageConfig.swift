//
//  LanguageConfig.swift
//  CHIPcade
//
//  Created by Markus Moenig on 29/10/24.
//

import Foundation
import RegexBuilder
import LanguageSupport

private let haskellReservedOperators =
  ["..", ":", "::", "=", "\\", "|", "<-", "->", "@", "~", "=>"]

// Generate ChipCade reserved identifiers from InstructionType
private var chipcadeReservedIds: [String] {
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
                                 stringRegex: /\"(?:\\\"|[^\"])*+\"/,
                                 characterRegex: /'(?:\\'|[^']|\\[^']*+)'/,
                                 numberRegex: numberRegex,
                                 singleLineComment: "#",
                                 nestedComment: (open: "{-", close: "-}"),
                                 identifierRegex: identifierRegex,
                                 operatorRegex: operatorRegex,
                                 reservedIdentifiers: chipcadeReservedIds,
                                 reservedOperators: haskellReservedOperators,
                                 languageService: languageService)
  }
}
