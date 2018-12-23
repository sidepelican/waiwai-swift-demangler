public func demangle(name: String) -> String {
    return Parser(name: name).parse().description
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

    func parseIdentifier(length: Int) -> String {
        defer {
            self.skip(length: length)
        }

        return String(remains.prefix(upTo: length))
    }

    func parseIdentifier() -> String? {
        guard let len = self.parseInt() else { return nil }
        return self.parseIdentifier(length: len)
    }

    func parsePrefix() -> String {
        if isSwiftSymbol(name: remainsString) {
            self.skip(length: swiftPrefix.count)
            return swiftPrefix
        }
        fatalError("name has not swiftPrefix.")
    }

    func parseModule() -> String {
        if let module = self.parseIdentifier() {
            return module
        }
        fatalError(#function)
    }

    func parseDeclName() -> String {
        if let declName = self.parseIdentifier() {
            return declName
        }
        fatalError(#function)
    }

    func parseLabelList() -> [String] {
        var ret = [String]()
        while let label = self.parseIdentifier() {
            ret.append(label)
        }
        return ret
    }

    func parseKnownType() -> Type {
        let remains = self.remains
        if let type = Type(c1: remains[0], c2: remains[1]) {
            self.skip(length: 2)
            return type
        }
        fatalError(#function)
    }

    func parseType() -> Type {
        let firstType = self.parseKnownType()

        // リストかどうか
        guard self.peek() == "_" else { return firstType }
        self.skip(length: 1) // 先読みした "_" の分を進める

        var ret = [firstType]
        while self.peek() != "t" {
            ret.append(self.parseKnownType())
        }
        self.skip(length: 1) // 先読みした "t" の分を進める

        return .list(ret)
    }

    func parseFunctionSignature() -> FunctionSignature {
        return FunctionSignature(
            returnType: self.parseType(),
            argsType: self.parseType()
        )
    }

    func parseFunctionEntity() -> FunctionEntity {
        return FunctionEntity(
            module: self.parseModule(),
            declName: self.parseDeclName(),
            labelList: self.parseLabelList(),
            functionSignature: self.parseFunctionSignature())
    }

    func parse() -> FunctionEntity {
        let _ = self.parsePrefix()
        return self.parseFunctionEntity()
    }

    // indexはそのままに一文字先読みする
    func peek() -> Character {
        if let c = remains.first {
            return c
        }
        fatalError(#function)
    }

    func skip(length: Int) {
        self.index += length
    }
}

enum Type: Equatable {
    case bool
    case int
    case string
    case float
    indirect case list([Type])

    init?(c1: Character, c2: Character) {
        if c1 != "S" { return nil }
        switch c2 {
        case "b": self = .bool
        case "i": self = .int
        case "S": self = .string
        case "f": self = .float
        default: return nil
        }
    }

    var names: [String] {
        switch self {
        case .bool: return ["Swift.Bool"]
        case .int: return ["Swift.Int"]
        case .string: return ["Swift.String"]
        case .float: return ["Swift.Float"]
        case let .list(types):
            return types.flatMap { $0.names }
        }
    }
}

struct FunctionSignature: Equatable {
    let returnType: Type
    let argsType: Type
}

struct FunctionEntity: Equatable, CustomStringConvertible {
    let module: String
    let declName: String
    let labelList: [String]
    let functionSignature: FunctionSignature

    var description: String {
        let args = zip(labelList, functionSignature.argsType.names).map { label, typeName in
            "\(label): \(typeName)"
        }.joined(separator: ", ")

        return "\(module).\(declName)(\(args)) -> \(functionSignature.returnType.names.first!)"
    }
}

private let swiftPrefix = "$S"

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
