public class GRYKotlinTranslator {
    public func translateAST(_ ast: GRYAst) -> String {
        var result = ""
        
        for subTree in ast.subTrees {
            switch subTree.name {
            case "Function Declaration":
                let string = translate(functionDeclaration: subTree, withIndentation: "")
                result += string + "\n"
            default:
                result += "<Unknown: \(subTree.name)>\n\n"
            }
        }
        
        return result
    }
    
    private func translate(functionDeclaration: GRYAst, withIndentation indentation: String) -> String {
        var indentation = indentation
        var result = ""

        result += indentation
        
        if let access = functionDeclaration["access"] {
            result += access + " "
        }
        
        result += "fun "
        
        let functionName = functionDeclaration.standaloneAttributes[0]
        let functionNamePrefix = functionName.prefix { $0 != "(" }
        
        result += functionNamePrefix + "("
        
        var parameterStrings = [String]()
        if let parameterList = functionDeclaration.subTree(named: "Parameter List") {
            for parameter in parameterList.subTrees {
                let name = parameter["apiName"]!
                let type = parameter["interface type"]!
                parameterStrings.append(name + ": " + type)
            }
        }
        
        result += parameterStrings.joined(separator: ", ")
        
        result += ")"

        // TODO: Doesn't allow to return function types
        let returnType = functionDeclaration["interface type"]!.split(separator: " -> ").last!
        if returnType != "()" {
            result += ": " + returnType
        }
        
        result += " {\n"
        
        indentation = increaseIndentation(indentation)
        
        // TODO: Write statements
        
        indentation = decreaseIndentation(indentation)
        
        result += indentation + "}\n"
        
        return result
    }
    
    //
    func increaseIndentation(_ indentation: String) -> String {
        return indentation + "\t"
    }
    
    func decreaseIndentation(_ indentation: String) -> String {
        return String(indentation.dropLast())
    }
}
