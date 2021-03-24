//
//  Chooser.swift
//  chooser
//
//  Created by hideaki_tanabe on 2021/03/24.
//

import ArgumentParser
import Foundation

//see: https://stackoverflow.com/questions/24041554/how-can-i-output-to-stderr-with-swift
extension FileHandle : TextOutputStream {
  public func write(_ string: String) {
    guard let data = string.data(using: .utf8) else { return }
    self.write(data)
  }
}

enum Keys: Int {
    case enter = 10
    case space = 32
    case j = 106
    case k = 107
    case q = 113
}

struct Chooser: ParsableCommand {
    @Flag(help: "Include a counter with each repetition.")
    var includeCounter = false

    @Option(name: .shortAndLong, help: "The number of times to repeat 'phrase'.")
    var count: Int?

    @Argument(help: "The phrase to repeat.")
    var phrase: String

    fileprivate var currentIndex = 0
    fileprivate var displayedItems: [ListItem] = []
    fileprivate var items: [ListItem] = []
    fileprivate var maxDisplayingItems = 10

    // MARK: - fileprivate
    fileprivate func createList(rawItems: [String]) -> [ListItem] {
        var result: [ListItem] = []
        var index: Int = 0
        rawItems.forEach { (rawItem) in
            result.append(ListItem(text: rawItem, selected: false, index: index))
            index = index + 1
        }
        return result
    }

    fileprivate func getInput() -> String {
        let keyboard = FileHandle.standardInput
        let inputData = keyboard.availableData
        let inputString = String(data: inputData, encoding: String.Encoding.utf8)!
        return inputString.trimmingCharacters(in: CharacterSet.newlines)
    }

    fileprivate func getKeyPress () -> Int {
        var key: Int = 0
        var oldt: termios = termios()
        let file_no = STDIN_FILENO
        tcgetattr(file_no, &oldt)
        var newt = oldt
        newt.c_lflag = newt.c_lflag & ~UInt(ECHO | ICANON | IEXTEN)
        tcsetattr(file_no, TCSANOW, &newt)
        key = Int(getchar())
        tcsetattr(file_no, TCSANOW, &oldt)
        return key
    }

    func printItems(items: [ListItem], maxDisplayingItems: Int, position: Int, selected: Int, lastDisplayedItems: [ListItem]) -> [ListItem] {
        var standardError = FileHandle.standardError
        if lastDisplayedItems.count > 0 {
            // clear display buffer
            let blankLine = String(repeating: " ", count: 80)
            let heading = "\u{001B}[\(maxDisplayingItems)A"
            print(heading, terminator: "", to: &standardError)
            for _ in 0..<maxDisplayingItems {
                print("\(blankLine)\n", terminator: "", to: &standardError)
            }
            print(heading, terminator: "", to: &standardError)
        }

        let displayFrom = position
        let displayTo = min(displayFrom + maxDisplayingItems, items.count)
        var displayingItems: [ListItem] = []

        if lastDisplayedItems.count == 0 {
            displayingItems = Array(items[displayFrom..<displayTo])
        } else if lastDisplayedItems.contains(where: { (item) -> Bool in
            return item.index == position
        }) {
            displayingItems = lastDisplayedItems
        } else {
            if let lastDisplayedFirstItem = lastDisplayedItems.first {
                if position < lastDisplayedFirstItem.index {
                    let displayFrom = lastDisplayedFirstItem.index - 1
                    let displayTo = min(displayFrom + maxDisplayingItems, items.count)
                    displayingItems = Array(items[displayFrom..<displayTo])
                } else {
                    let displayFrom = lastDisplayedFirstItem.index + 1
                    let displayTo = min(displayFrom + maxDisplayingItems, items.count)
                    displayingItems = Array(items[displayFrom..<displayTo])
                }
            }
        }

        for index in 0..<displayingItems.count {
            let item = displayingItems[index]
            var prefix = "( )"
            if item.index == position {
                prefix = "(o)"
            }
            var standardError = FileHandle.standardError
            print("  \(prefix) \(item.text)\n", terminator: "", to: &standardError)
        }
        return displayingItems
    }

    fileprivate func readInput() -> [ListItem] {
        let rawItems = getInput().split(separator: "\n").map { (substring) -> String in
            return substring.description
        }
        let items = createList(rawItems: rawItems)
        return items
    }

    fileprivate mutating func cursorUp() {
        if currentIndex > 0 {
            currentIndex = currentIndex - 1
        }
    }

    fileprivate mutating func cursorDown() {
        if (currentIndex < items.count - 1) {
            currentIndex = currentIndex + 1
        }
    }

    fileprivate mutating func waitKeyPress() {
        let c = getKeyPress()
        if (c != -1) {
            if (c == Keys.enter.rawValue) {
                let selectedItem = items[currentIndex]
                print(selectedItem.text)
                Chooser.exit()
            }

            if (c == Keys.q.rawValue) {
                Chooser.exit()
            }

            if (c == Keys.space.rawValue) {
                //
            }

            if (c == Keys.k.rawValue) {
                cursorUp()
            } else if (c == Keys.j.rawValue) {
                cursorDown()
            }

            // back
            displayedItems = printItems(items: items, maxDisplayingItems: maxDisplayingItems, position: currentIndex, selected: currentIndex, lastDisplayedItems: displayedItems)
            fflush(stderr)
        }
    }

    mutating func run() throws {
        items = readInput()
        maxDisplayingItems = min(items.count, 10)

        let _ = freopen("/dev/tty", "r", stdin)

        // start
        displayedItems = printItems(items: items, maxDisplayingItems: maxDisplayingItems, position: currentIndex, selected: currentIndex, lastDisplayedItems: displayedItems)
        while (true) {
            waitKeyPress()
        }

        /*
        let repeatCount = count ?? .max
        for i in 1...repeatCount {
            if includeCounter {
                print("\(i): \(phrase)")
            } else {
                print(phrase)
            }
        }
 */
    }
}
