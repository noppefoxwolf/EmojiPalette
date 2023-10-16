/*
 EmojiParser.swift


 Created by Takuto Nakamura on 2023/09/10.

*/

import SwiftUI
import RegexBuilder

public final class EmojiParser {
    public static let shared = EmojiParser()

    private var _emojiSets = [EmojiSet]()

    public var emojiSets: [EmojiSet] {
        return _emojiSets
    }

    private init() {
        guard let path = Bundle.module.path(forResource: "14.0-emoji-test", ofType: "txt"),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let text = String(data: data, encoding: .utf8) else {
            fatalError("Could not get data from 14.0-emoji-test.txt")
        }
        let groups = Self.loadEmojiGroup(from: text)
        groups.forEach { group in
            guard let category = EmojiCategory(groupName: group.name) else {
                return
            }
            let emojis = group.subgroups.flatMap { $0.emojis }
            if _emojiSets.last?.category == category {
                _emojiSets[_emojiSets.count - 1].emojis += emojis
            } else {
                _emojiSets.append(EmojiSet(category: category, emojis: emojis))
            }
        }
    }
    
    static func newLoadEmojiGroup(from text: String) -> [EmojiGroup] {
        var groups = [EmojiGroup]()
        var subgroups = [EmojiSubGroup]()
        var emojis = [Emoji]()
        
        let groupRegex = Regex {
            "# group:"
            OneOrMore(.whitespace)
            Capture { OneOrMore(.anyNonNewline) }
        }
        let subgroupRegex = Regex {
            "# subgroup:"
            OneOrMore(.whitespace)
            Capture { OneOrMore(.anyNonNewline) }
        }
        let emojiRegex = Regex.emojiLine
        
        text.enumerateLines { line, stop in
            if let match = line.wholeMatch(of: groupRegex) {
                subgroups = []
                groups.append(EmojiGroup(name: String(match.output.1), subgroups: []))
                return
            }
            
            if let match = line.wholeMatch(of: subgroupRegex) {
                emojis = []
                subgroups.append(EmojiSubGroup(name: String(match.output.1), emojis: []))
                groups[groups.count - 1].subgroups = subgroups
                return
            }
            
            if let match = line.wholeMatch(of: emojiRegex) {
                let id = String(match.output.3)
                if match.output.4?.contains("skin tone") == true {
                    return
                }
                emojis.append(Emoji(id: id, character: String(match.output.2)))
                subgroups[subgroups.count - 1].emojis = emojis
                groups[groups.count - 1].subgroups = subgroups
                return
            }
        }
        return groups
    }

    static func loadEmojiGroup(from text: String) -> [EmojiGroup] {
        var groups = [EmojiGroup]()
        var subgroups = [EmojiSubGroup]()
        var emojis = [Emoji]()
        text.enumerateLines { line, stop in
            if line.contains("# group:"),
               let group = line.components(separatedBy: "# group:").last?.trimmingCharacters(in: .whitespaces) {
                subgroups = []
                groups.append(EmojiGroup(name: group, subgroups: []))
            }
            if line.contains("# subgroup:"),
               let subGroup = line.components(separatedBy: "# subgroup:").last?.trimmingCharacters(in: .whitespaces) {
                emojis = []
                subgroups.append(EmojiSubGroup(name: subGroup, emojis: []))
                groups[groups.count - 1].subgroups = subgroups
            }
            if line.contains(";") && !line.contains("Format:") {
                let separatedBySemicolon = line.split(separator: ";")
                if let separatedByHash = separatedBySemicolon.last?.split(separator: "#"),
                   let status = separatedByHash.first?.trimmingCharacters(in: .whitespaces),
                   let afterHash = separatedByHash.last?.trimmingCharacters(in: .whitespaces),
                   let emoji = afterHash.components(separatedBy: .whitespaces).first {
                    if status == "unqualified" || status == "minimally-qualified" {
                        return
                    }
                    if afterHash.contains(":") && afterHash.contains("skin tone") {
                        return
                    }
                    var array = afterHash.components(separatedBy: " ")
                    array.removeFirst()
                    array.removeFirst()
                    let id = array.map { $0.replacingOccurrences(of: ":", with: "") }.joined(separator: "-")
                    emojis.append(Emoji(id: id, character: emoji))
                    subgroups[subgroups.count - 1].emojis = emojis
                    groups[groups.count - 1].subgroups = subgroups
                }
            }
        }
        return groups
    }

    public func randomEmoji(categories: [EmojiCategory] = EmojiCategory.allCases) -> Emoji {
        let emojiSet = _emojiSets.filter { categories.contains($0.category) }.randomElement()
        guard let emoji = emojiSet?.emojis.randomElement() else {
            fatalError("Could not get random emoji")
        }
        return emoji
    }
}

extension Regex where Self.RegexOutput == Substring {
    static var codePoints: Regex {
        Regex {
            OneOrMore(.anyNonNewline)
        }
    }
    
    static var validEmojiStatus: Regex {
        Regex {
            ChoiceOf {
                "component"
                "fully-qualified"
            }
        }
    }
    
    /// 👋🏼 E1.0 waving hand: medium-light skin
    static var emojiName: Regex {
        Regex {
            Capture { // emoji
                One(.any)
            }
            ZeroOrMore(.whitespace)
            emojiNameVersion
            ZeroOrMore(.whitespace)
            Capture {
                OneOrMore(.reluctant) {
                    .anyNonNewline
                }
                Optionally {
                    emojiNameNote
                }
            }
        }
    }
    
    static var emojiNameVersion: Regex {
        Regex {
            OneOrMore {
                CharacterClass(
                    .anyOf("E."),
                    ("0"..."9")
                )
            }
        }
    }
    
    static func emojiNameNote(as reference: Reference<Substring>) -> Regex {
        Regex {
            ": "
            Capture(as: reference) {
                OneOrMore {
                    .anyNonNewline
                }
            }
        }
    }
    
    /// code points; status # emoji name
    static var emojiLine: Regex {
        Regex {
            codePoints
            OneOrMore(.whitespace)
            ";"
            OneOrMore(.whitespace)
            validEmojiStatus
            OneOrMore(.whitespace)
            "#"
            ZeroOrMore(.whitespace)
            emojiName
        }
        .matchingSemantics(.unicodeScalar)
    }
}
