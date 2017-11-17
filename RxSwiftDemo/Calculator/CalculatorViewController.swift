//
//  CalculatorViewController.swift
//  RxSwiftDemo
//
//  Created by 夏语诚 on 2017/11/9.
//  Copyright © 2017年 Banana. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class CalculatorViewController: UIViewController {

    @IBOutlet weak var lastSignLabel: UILabel!
    @IBOutlet weak var resultLabel: UILabel!
    
    @IBOutlet weak var allClearButton: UIButton!
    @IBOutlet weak var changeSignButton: UIButton!
    @IBOutlet weak var percentButton: UIButton!
    
    @IBOutlet weak var divideButton: UIButton!
    @IBOutlet weak var multiplyButton: UIButton!
    @IBOutlet weak var minusButton: UIButton!
    @IBOutlet weak var plusButton: UIButton!
    @IBOutlet weak var equalButton: UIButton!
    
    @IBOutlet weak var dotButton: UIButton!
    
    @IBOutlet weak var zeroButton: UIButton!
    @IBOutlet weak var oneButton: UIButton!
    @IBOutlet weak var twoButton: UIButton!
    @IBOutlet weak var threeButton: UIButton!
    @IBOutlet weak var fourButton: UIButton!
    @IBOutlet weak var fiveButton: UIButton!
    @IBOutlet weak var sixButton: UIButton!
    @IBOutlet weak var sevenButton: UIButton!
    @IBOutlet weak var eightButton: UIButton!
    @IBOutlet weak var nineButton: UIButton!
    
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let commands: Observable<CalculatorCommand> = Observable.merge([
            allClearButton.rx.tap.map { _ in .clear },
            changeSignButton.rx.tap.map { _ in .changeSign },
            percentButton.rx.tap.map { _ in .percent },
            
            divideButton.rx.tap.map { _ in .operation(.division) },
            multiplyButton.rx.tap.map { _ in .operation(.multiplication) },
            minusButton.rx.tap.map { _ in .operation(.substraction) },
            plusButton.rx.tap.map { _ in .operation(.addition) },
            
            equalButton.rx.tap.map { _ in .equal },
            dotButton.rx.tap.map { _ in .addDot },
            
            zeroButton.rx.tap.map { _ in .addNumber("0") },
            oneButton.rx.tap.map { _ in .addNumber("1") },
            twoButton.rx.tap.map { _ in .addNumber("2") },
            threeButton.rx.tap.map { _ in .addNumber("3") },
            fourButton.rx.tap.map { _ in .addNumber("4") },
            fiveButton.rx.tap.map { _ in .addNumber("5") },
            sixButton.rx.tap.map { _ in .addNumber("6") },
            sevenButton.rx.tap.map { _ in .addNumber("7") },
            eightButton.rx.tap.map { _ in .addNumber("8") },
            nineButton.rx.tap.map { _ in .addNumber("9") }
        ])
    
    let system = Observable.system(CalculatorState.initial, accumulator: CalculatorState.reduce, scheduler: MainScheduler.instance, feedback: { _ in commands })
        .debug("Calculator state")
        .share(replay: 1)
        
        system.map { $0.screen }
            .bind(to: resultLabel.rx.text)
            .disposed(by: disposeBag)
        
        system.map { $0.sign }
            .bind(to: lastSignLabel.rx.text)
            .disposed(by: disposeBag)
    }
    
}

extension Observable {
    public static func system<State>(
        _ initialState: State,
        accumulator: @escaping (State, Element) -> State,
        scheduler: SchedulerType,
        feedback: (Observable<State>) -> Observable<Element>...
        ) -> Observable<State> {
        return Observable<State>.deferred {
            let replaySubject = ReplaySubject<State>.create(bufferSize: 1)
            
            let inputs: Observable<Element> = Observable.merge(feedback.map { $0(replaySubject.asObservable()) })
                .observeOn(scheduler)
            
            return inputs.scan(initialState, accumulator: accumulator)
                .startWith(initialState)
                .do(onNext: { output in
                    replaySubject.onNext(output)
                })
        }
    }
}
