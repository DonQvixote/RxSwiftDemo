//
//  Calculator.swift
//  RxSwiftDemo
//
//  Created by 夏语诚 on 2017/11/9.
//  Copyright © 2017年 Banana. All rights reserved.
//

import Foundation

enum Operator {
    case addition
    case substraction
    case multiplication
    case division
}

enum CalculatorCommand {
    case clear
    case changeSign
    case percent
    case operation(Operator)
    case equal
    case addNumber(Character)
    case addDot
}

enum CalculatorState {
    case oneOperand(screen: String)
    case oneOperandAndOperator(operand: Double, operator: Operator)
    case twoOperandsAndOperator(operand: Double, operator: Operator, screen: String)
}

extension Operator {
    var sign: String {
        switch self {
        case .addition:
            return "+"
        case .substraction:
            return "-"
        case .multiplication:
            return "x"
        case .division:
            return "/"
        }
    }
    
    var perform: (Double, Double) -> Double {
        switch self {
        case .addition:
            return (+)
        case .substraction:
            return (-)
        case .multiplication:
            return (*)
        case .division:
            return (/)
        }
    }
}

private extension String {
    var doubleValue: Double {
        guard let double = Double(self) else {
            return Double.infinity
        }
        return double
    }
}

private func formatResult(_ result: String) -> String {
    if result.hasSuffix(".0") {
        return String(result[..<result.index(result.endIndex, offsetBy: -2)])
    } else {
        return result
    }
}

extension CalculatorState {
    static let initial = CalculatorState.oneOperand(screen: "0")
    
    func mapScreen(transform: (String) -> String) -> CalculatorState {
        switch self {
        case let .oneOperand(screen):
            return .oneOperand(screen: transform(screen))
        case let .oneOperandAndOperator(operand, operat):
            return .twoOperandsAndOperator(operand: operand, operator: operat, screen: transform("0"))
        case let .twoOperandsAndOperator(operand, operat, screen):
            return .twoOperandsAndOperator(operand: operand, operator: operat, screen: transform(screen))
        }
    }
    
    static var screenIsResult = false
    
    var screen: String {
        switch self {
        case let .oneOperand(screen):
            return screen
        case .oneOperandAndOperator(let operand, _):
            return formatResult(String(operand))
        case let .twoOperandsAndOperator(_, _, screen):
            return formatResult(screen)
        }
    }
    
    var sign: String {
        switch self {
        case .oneOperand:
            return ""
        case let .oneOperandAndOperator(_, o):
            return o.sign
        case let .twoOperandsAndOperator(_, o, _):
            return o.sign
        }
    }

}

extension CalculatorState {
    static func reduce(state: CalculatorState, _ x: CalculatorCommand) -> CalculatorState {
        switch x {
        case .clear:
            return CalculatorState.initial
        case .addNumber(let c):
            return state.mapScreen { screen in
                if screenIsResult || screen == "0" {
                    screenIsResult = false
                    return String(c)
                } else {
                    return screen + String(c)
                }
            }
        case .addDot:
            return state.mapScreen { $0.range(of: ".") == nil ? $0 + "." : $0 }
        case .changeSign:
            return state.mapScreen { "\(-(Double($0) ?? 0.0))" }
        case .percent:
            return state.mapScreen { "\((Double($0) ?? 0.0) / 100.0)"}
        case .operation(let o):
            switch state {
            case let .oneOperand(screen):
                return .oneOperandAndOperator(operand: screen.doubleValue, operator: o)
            case let .oneOperandAndOperator(operand, _):
                return .oneOperandAndOperator(operand: operand, operator: o)
            case let .twoOperandsAndOperator(operand, oldOperator, screen):
                screenIsResult = true
                return .twoOperandsAndOperator(operand: oldOperator.perform(operand, screen.doubleValue), operator: o, screen: String(oldOperator.perform(operand, screen.doubleValue)))
            }
        case .equal:
            switch state {
            case let .twoOperandsAndOperator(operand, operat, screen):
                let result = operat.perform(operand, screen.doubleValue)
                screenIsResult = true
                return .oneOperand(screen: formatResult(String(result)))
            default:
                screenIsResult = true
                return state
            }
        }
    }
}
