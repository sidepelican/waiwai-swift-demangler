public func demangle(name: String) -> String {
    return name
}

class Parser {
    private let name: [Character]
    private var index: Int
    
    var remains: [Character] { return Array(name[index...]) }
    var remainsString: String { return String(remains) }

    init(name: String) {
        self.name = name.map { $0 }
        self.index = 0
    }
    
    func parseInt() -> Int? {
        let remains = self.remains
        
        if let i = toInt(remains) {
            self.index = name.endIndex
            return i
        }
        let decimalDigits = "0123456789"
        guard let index = remains.firstIndex(where: { c in !decimalDigits.contains(c) }) else {
            return nil
        }
        guard let int = toInt(remains.prefix(upTo: index)) else {
            return nil
        }
        self.index = self.name.index(self.index, offsetBy: int / 10 + 1)
        return int
    }
}

func isSwiftSymbol(name: String) -> Bool {
    return name.hasPrefix("$S")
}

func isFunctionEntitySpec(name: String) -> Bool {
    return name.hasSuffix("F")
}

@inlinable
func toInt(_ name: ArraySlice<Character>) -> Int? {
    return Int(String(name))
}

@inlinable
func toInt(_ name: Array<Character>) -> Int? {
    return Int(String(name))
}
