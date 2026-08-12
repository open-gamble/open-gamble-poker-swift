public func findIndexAdjacent<T>(_ array: [T], _ predicate: (T, T) -> Bool) -> Int {
    if array.isEmpty {
        return -1
    }
    var first = array[0]
    for index in 1..<array.count {
        let second = array[index]
        if predicate(first, second) {
            return index - 1
        }
        first = second
    }
    return -1
}

public func nextOrWrap<T>(_ array: [T?], _ currentIndex: Int) -> Int {
    var index = currentIndex
    repeat {
        index += 1
        if index == array.count {
            index = 0
        }
    } while array[index] == nil
    return index
}

public func rotate<T>(_ array: inout [T], _ count: Int) {
    precondition(!array.isEmpty, "Cannot rotate an empty array")
    let offset = ((count % array.count) + array.count) % array.count
    array.append(contentsOf: array.prefix(offset))
    array.removeFirst(offset)
}

public func unique<T: Equatable>(_ array: [T]) -> [T] {
    unique(array, { $0 != $1 })
}

public func unique<T>(_ array: [T], _ predicate: (T, T) -> Bool) -> [T] {
    if array.isEmpty {
        return array
    }
    return array[1...].reduce([array[0]]) { acc, item in
        var acc = acc
        if predicate(acc[acc.count - 1], item) {
            acc.append(item)
        }
        return acc
    }
}

public func findMax<T>(_ array: [T], _ compare: (T, T) -> Int) -> T {
    precondition(!array.isEmpty)
    return array.sorted { compare($0, $1) < 0 }[0]
}