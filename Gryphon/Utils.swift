#if DEBUG
    let log: ((Any) -> Void)? = { (item: Any) in print(item) }
#else
    let log: ((Any) -> Void)? = nil
#endif

//
let shouldLogParser = false

//
let parserLog = shouldLogParser ? log : nil
