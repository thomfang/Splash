/**
 *  Splash
 *  Copyright (c) John Sundell 2018
 *  MIT license - see LICENSE.md
 */

import Foundation
import XCTest
import Splash

// 回归: Tokenizer.Iterator.next() 旧实现用尾递归,遇到超长连续同类 run
// (长 token / 长空白)会递归到栈溢出崩溃。改写成循环后递归深度恒为 1。
final class LongInputTests: SyntaxHighlighterTestCase {
    private func reconstruct(_ components: [OutputBuilderMock.Component]) -> String {
        components.reduce(into: "") { result, component in
            switch component {
            case .token(let text, _):
                result += text
            case .plainText(let text):
                result += text
            case .whitespace(let text):
                result += text
            }
        }
    }

    func testLongContiguousTokenDoesNotOverflowStack() {
        let input = String(repeating: "a", count: 200_000)
        let components = highlighter.highlight(input)
        XCTAssertEqual(reconstruct(components), input)
    }

    // 纯空白输入下,Splash 既有行为会把首个空白字符同时计入 token 与 trailingWhitespace
    // (与本次去递归改动无关),故只断言"完整消费、未截断、未爆栈",不做逐字节等值。
    func testLongWhitespaceRunDoesNotOverflowStack() {
        let input = String(repeating: " ", count: 200_000)
        let components = highlighter.highlight(input)
        XCTAssertGreaterThanOrEqual(reconstruct(components).count, input.count)
    }

    func testLongNewlineRunDoesNotOverflowStack() {
        let input = String(repeating: "\n", count: 200_000)
        let components = highlighter.highlight(input)
        XCTAssertGreaterThanOrEqual(reconstruct(components).count, input.count)
    }

    func testLongMixedLineDoesNotOverflowStack() {
        // 模拟压缩单行 / 长 base64: 长 token run 后接分隔符再接长 run。
        let input = String(repeating: "x", count: 100_000)
            + "=" + String(repeating: "y", count: 100_000)
        let components = highlighter.highlight(input)
        XCTAssertEqual(reconstruct(components), input)
    }
}
