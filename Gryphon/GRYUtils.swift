#if DEBUG
    let log: ((Any) -> Void)? = { (item: Any) in print(item) }
#else
    let log: ((Any) -> Void)? = nil
#endif

//
private let gryShouldLogParser = false

//
let gryParserLog = gryShouldLogParser ? log : nil
