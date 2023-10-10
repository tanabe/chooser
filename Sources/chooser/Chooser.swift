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
    case escapeCode = 27
    case arrowUp = 65
    case arrowDown = 66
    case arrowCode = 91
    case j = 106
    case k = 107
    case q = 113
}

struct Chooser: ParsableCommand {
    @Option(help: "The number of lines.")
    var n: Int?

    @Flag(help: "Enable multiple selection.")
    var multiple = false

    fileprivate var currentIndex = 0
    fileprivate var displayedItems: [ListItem] = []
    fileprivate var items: [ListItem] = []

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

    private func getPressedKeyCode () -> Int {
        var oldt: termios = termios()
        let descriptor = STDIN_FILENO
        tcgetattr(descriptor, &oldt)
        var newt = oldt
        newt.c_lflag = newt.c_lflag & ~UInt(ECHO | ICANON | IEXTEN)
        tcsetattr(descriptor, TCSANOW, &newt)
        let key = Int(getchar())
        tcsetattr(descriptor, TCSANOW, &oldt)
        return key
    }

    func printItems(items: [ListItem], maxDisplayingItems: Int, position: Int, lastDisplayedItems: [ListItem]) -> [ListItem] {
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

        var nextDisplayingItems: [ListItem] = []

        if lastDisplayedItems.count == 0 {
            nextDisplayingItems = Array(items[displayFrom..<displayTo])
        } else if lastDisplayedItems.contains(where: { (item) -> Bool in
            return item.index == position
        }) {
            nextDisplayingItems = lastDisplayedItems
        } else {
            if let lastDisplayedFirstItem = lastDisplayedItems.first {
                if position < lastDisplayedFirstItem.index {
                    let displayFrom = lastDisplayedFirstItem.index - 1
                    let displayTo = min(displayFrom + maxDisplayingItems, items.count)
                    nextDisplayingItems = Array(items[displayFrom..<displayTo])
                } else {
                    let displayFrom = lastDisplayedFirstItem.index + 1
                    let displayTo = min(displayFrom + maxDisplayingItems, items.count)
                    nextDisplayingItems = Array(items[displayFrom..<displayTo])
                }
            }
        }

        for index in 0..<nextDisplayingItems.count {
            let item = nextDisplayingItems[index]
            var cursor = " "
            if item.index == currentIndex {
                cursor = ">"
            }

            var prefix = "( )"
            if item.selected {
                prefix = "(o)"
            }

            var standardError = FileHandle.standardError
            print("\(cursor) \(prefix) \(item.text)\n", terminator: "", to: &standardError)
        }
        return nextDisplayingItems
    }

    fileprivate func readInput() -> [ListItem] {
        let rawItems = getInput().split(separator: "\n").map { (substring) -> String in
            return substring.description
        }
        let items = createList(rawItems: rawItems)
        return items
    }

    fileprivate func cursorUp(index: Int) -> Int {
        if index > 0 {
            return index - 1
        }
        return index
    }

    fileprivate mutating func cursorDown(index: Int, listSize: Int) -> Int {
        if (index < listSize - 1) {
            return index + 1
        }
        return index
    }

    fileprivate mutating func waitKeyPress(maxDisplayingItems: Int) {
        let key = getPressedKeyCode()
        if (key != -1) {
            if (key == Keys.enter.rawValue) {
                let selectedItems = items.filter { (item) -> Bool in
                    item.selected
                }.map { (item) -> String in
                    return item.text
                }

                print(selectedItems.joined(separator: "\n"))
                Chooser.exit()
            }

            if (key == Keys.q.rawValue) {
                Chooser.exit()
            }

            if (key == Keys.space.rawValue) {
                items[currentIndex].selected.toggle()
            }

            // arrows keys are a little complex
            // for example, arrow up key is consist of three codes 27 91 65
            if (key == Keys.escapeCode.rawValue) {
                if (getPressedKeyCode() == Keys.arrowCode.rawValue) {
                    let arrowKeyCode = getPressedKeyCode()
                    if (arrowKeyCode == Keys.arrowUp.rawValue) {
                        currentIndex = cursorUp(index: currentIndex)
                    } else if (arrowKeyCode == Keys.arrowDown.rawValue) {
                        currentIndex = cursorDown(index: currentIndex, listSize: items.count)
                    }
                }
            }

            if (key == Keys.k.rawValue) {
                currentIndex = cursorUp(index: currentIndex)
            } else if (key == Keys.j.rawValue) {
                currentIndex = cursorDown(index: currentIndex, listSize: items.count)
            }

            if (multiple) {
                for index in 0..<displayedItems.count {
                    let displayedItem = displayedItems[index]
                    let displayedItemIndex = displayedItem.index
                    displayedItems[index].selected = false
                    if let _ = items.first(where: { (item) -> Bool in
                        return item.selected && item.index == displayedItemIndex
                    }) {
                        displayedItems[index].selected = true
                    }
                }
            } else {
                for index in 0..<items.count {
                    items[index].selected = false
                }
                items[currentIndex].selected = true

                // A little tricky
                for index in 0..<displayedItems.count {
                    let displayedItem = displayedItems[index]
                    let displayedItemIndex = displayedItem.index
                    displayedItems[index].selected = false
                    if let _ = items.first(where: { (item) -> Bool in
                        return item.selected && item.index == displayedItemIndex
                    }) {
                        displayedItems[index].selected = true
                    }
                }
            }

            // display
            displayedItems = printItems(items: items, maxDisplayingItems: maxDisplayingItems, position: currentIndex, lastDisplayedItems: displayedItems)
            fflush(stderr)
        }
    }

    mutating func run() throws {
        items = readInput()
        if (items.count == 0) {
            print("No inputs")
            Chooser.exit()
        }

        var maxDisplayingItems = 10
        if let n = n {
            maxDisplayingItems = min(items.count, n)
        } else {
            maxDisplayingItems = min(items.count, 10)
        }

        let _ = freopen("/dev/tty", "r", stdin)

        if !multiple {
            items[currentIndex].selected = true
        }

        displayedItems = printItems(items: items, maxDisplayingItems: maxDisplayingItems, position: currentIndex, lastDisplayedItems: displayedItems)
        while (true) {
            waitKeyPress(maxDisplayingItems: maxDisplayingItems)
        }
    }
}
