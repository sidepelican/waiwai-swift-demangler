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
        let swiftPrefix = "$S"
        if remainsString.hasPrefix(swiftPrefix) {
            self.skip(length: swiftPrefix.count)
            return swiftPrefix
        }
        fatalError("name has not swiftPrefix.")
    }

    func parseSuffix() -> Bool {
        func isFunctionEntitySpec(name: String) -> Bool {
            return name.hasSuffix("F")
        }

        func isThrowsFunctionEntitySpec(name: String) -> Bool {
            return name.hasSuffix("KF")
        }

        let remainsString = self.remainsString
        if isThrowsFunctionEntitySpec(name: remainsString) {
            self.skip(length: 2)
            return true
        } else if isFunctionEntitySpec(name: remainsString) {
            self.skip(length: 1)
            return false
        }

        fatalError(#function)
    }

    func parseModule() -> String {
        if let module = self.parseIdentifier() {
            return module
        }
        fatalError(#function)
    }

    func parseNominalType() -> NominalTypeHolder? {
        let startIndex = self.index
        let startRemains = self.remains

        // 先読み
        guard let nextLength = self.parseInt() else {
            fatalError(#function)
        }
        let nominalTypeIdentifierIndex = nextLength + 1

        guard startRemains.indices.contains(nominalTypeIdentifierIndex) else {
            self.index = startIndex
            return nil
        }

        guard let nominalType = NominalType(rawValue: startRemains[nominalTypeIdentifierIndex]) else {
            self.index = startIndex
            return nil
        }

        // 先読みした結果いけそうなことがわかったので、nominalTypeを読みにかかる
        self.index = startIndex
        guard let identifier = self.parseIdentifier() else {
            fatalError(#function)
        }
        self.skip(length: 1) // NominalTypeIdentifierの分進める

        return NominalTypeHolder(type: nominalType, name: identifier)
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
        if let type = Type(name: remains) {
            self.skip(length: type.identifierLength)
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
            nominalType: self.parseNominalType(),
            declName: self.parseDeclName(),
            labelList: self.parseLabelList(),
            functionSignature: self.parseFunctionSignature(),
            throws: self.parseSuffix()
        )
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

enum Type: Equatable, CustomStringConvertible {
    case bool
    case int
    case string
    case float
    case void
    indirect case list([Type])

    init?(name: [Character]) {
        guard !name.isEmpty else { return nil }
        switch name[0] {
        case "y":
            self = .void
        case "S":
            let count = name.count
            guard count >= 2 else { return nil }
            switch name[1] {
            case "b": self = .bool
            case "i": self = .int
            case "S": self = .string
            case "f": self = .float
            default: return nil
            }
        default:
            return nil
        }
    }

    var identifierLength: Int {
        switch self {
        case .bool: return 2
        case .int: return 2
        case .string: return 2
        case .float: return 2
        case .void: return 1
        case .list: fatalError()
        }
    }

    var namesForLabelList: [String] {
        switch self {
        case .bool: return ["Swift.Bool"]
        case .int: return ["Swift.Int"]
        case .string: return ["Swift.String"]
        case .float: return ["Swift.Float"]
        case .void: return []
        case let .list(types):
            return types.flatMap { $0.namesForLabelList }
        }
    }

    var description: String {
        switch self {
        case let .list(types):
            return "(\(types.flatMap { $0.namesForLabelList }.joined(separator: ", ")))"
        case .void:
            return "()"
        default:
            let names = self.namesForLabelList
            assert(names.count == 1)
            return names[0]
        }
    }
}

struct FunctionSignature: Equatable {
    let returnType: Type
    let argsType: Type
}

enum NominalType: Character {
    case `struct` = "V"
    case `class` = "O"
    case `enum` = "C"
}

struct NominalTypeHolder: Equatable {
    let type: NominalType
    let name: String
}

struct FunctionEntity: Equatable, CustomStringConvertible {
    let module: String
    let nominalType: NominalTypeHolder?
    let declName: String
    let labelList: [String]
    let functionSignature: FunctionSignature
    let `throws`: Bool

    var description: String {
        let args = zip(labelList, functionSignature.argsType.namesForLabelList).map { label, typeName in
            "\(label): \(typeName)"
        }.joined(separator: ", ")

        let nominalTypeLabel: String
        if let nominalType = self.nominalType {
            nominalTypeLabel = "\(nominalType.name)."
        } else {
            nominalTypeLabel = ""
        }

        let throwsLabel: String
        if self.throws {
            throwsLabel = " throws"
        } else {
            throwsLabel = ""
        }
        return "\(module).\(nominalTypeLabel)\(declName)(\(args))\(throwsLabel) -> \(functionSignature.returnType)"
    }
}

@inlinable
func toInt(_ name: ArraySlice<Character>) -> Int? {
    return Int(String(name))
}

@inlinable
func toInt(_ name: Array<Character>) -> Int? {
    return Int(String(name))
}
