//
//  Wireframe.swift
//  RxSwiftDemo
//
//  Created by 夏语诚 on 2017/11/16.
//  Copyright © 2017年 Banana. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

// 弹框服务
protocol Wireframe {
    func open(url: URL)
    func promptFor<Action: CustomStringConvertible>(_ message: String, cancelAction: Action, actions: [Action]) -> Observable<Action>
}

class DefaultWireframe: Wireframe {
    static let shared = DefaultWireframe()
    
    func open(url: URL) {
        UIApplication.shared.open(url)
    }
    
    private static func rootViewController() -> UIViewController {
        // cheating, I know
        return UIApplication.shared.keyWindow!.rootViewController!
    }
    
    static func presentAlert(_ message: String) {
        let alertView = UIAlertController(title: "RxSwiftDemo", message: message, preferredStyle: .alert)
        alertView.addAction(UIAlertAction(title: "OK", style: .cancel) { _ in
        })
        rootViewController().present(alertView, animated: true, completion: nil)
    }
    
    func promptFor<Action : CustomStringConvertible>(_ message: String, cancelAction: Action, actions: [Action]) -> Observable<Action> {
        return Observable.create { observer in
            let alertView = UIAlertController(title: "RxSwiftDemo", message: message, preferredStyle: .alert)
            alertView.addAction(UIAlertAction(title: cancelAction.description, style: .cancel) { _ in
                observer.on(.next(cancelAction))
            })
            
            for action in actions {
                alertView.addAction(UIAlertAction(title: action.description, style: .default) { _ in
                    observer.on(.next(action))
                })
            }
            
            DefaultWireframe.rootViewController().present(alertView, animated: true, completion: nil)
            
            return Disposables.create {
                alertView.dismiss(animated:false, completion: nil)
            }
        }
    }
}

