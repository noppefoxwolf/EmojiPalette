import XCTest
@testable import EmojiPalette
import RegexBuilder

class EmojiParserTests: XCTestCase {
    var text: String!
    
    override func setUp() async throws {
        guard let path = Bundle.module.path(forResource: "14.0-emoji-test", ofType: "txt"),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let text = String(data: data, encoding: .utf8) else {
            fatalError("Could not get data from 14.0-emoji-test.txt")
        }
        self.text = text
    }
    
    func testParse() async throws {
        measure {
            _ = EmojiParser.loadEmojiGroup(from: text)
        }
    }
    
    func testParse2() async throws {
        measure {
            _ = EmojiParser.newLoadEmojiGroup(from: text)
        }
    }
    
    func testEqual() async throws {
        let emojiGroups1 = EmojiParser.loadEmojiGroup(from: text)
        let emojiGroups2 = EmojiParser.newLoadEmojiGroup(from: text)
        XCTAssertEqual(emojiGroups1.count, emojiGroups2.count)
        for i in 0..<emojiGroups1.count {
            let emojiGroup1 = emojiGroups1[i]
            let emojiGroup2 = emojiGroups2[i]
            XCTAssertEqual(emojiGroup1.name, emojiGroup2.name)
            XCTAssertEqual(emojiGroup1.subgroups.count, emojiGroup2.subgroups.count)
            for i in 0..<emojiGroup1.subgroups.count {
                let emojiSubgroup1 = emojiGroup1.subgroups[i]
                let emojiSubgroup2 = emojiGroup2.subgroups[i]
                XCTAssertEqual(emojiSubgroup1.name, emojiSubgroup2.name)
                XCTAssertEqual(emojiSubgroup1.emojis.count, emojiSubgroup2.emojis.count)
                for i in 0..<emojiSubgroup1.emojis.count {
                    let emoji1 = emojiSubgroup1.emojis[i]
                    let emoji2 = emojiSubgroup2.emojis[i]
                    XCTAssertEqual(emoji1.id, emoji2.id)
                    XCTAssertEqual(emoji1.character, emoji2.character)
                }
            }
        }
    }
    
    func testParse3() {
        let text = "263A FE0F                                              ; fully-qualified     # ☺️ E0.6 smiling face"
        
        let emojiRegex = Regex {
            Capture { OneOrMore(.anyNonNewline) }
            OneOrMore(.whitespace)
            ";"
            OneOrMore(.whitespace)
            ChoiceOf {
                "component"
                "fully-qualified"
            }
            OneOrMore(.whitespace)
            "#"
            ZeroOrMore(.whitespace)
            One(.any)
            ZeroOrMore(.whitespace)
            OneOrMore {
                .any
            }
            
        }.matchingSemantics(.unicodeScalar)
        
        let match = text.wholeMatch(of: emojiRegex)!
//        print(match.output.1)
//        print(match.output.2)
//        print(match.output.3)
//        print(match.output.4)
    }
}

