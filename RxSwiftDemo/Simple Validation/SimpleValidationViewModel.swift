//
//  File.swift
//  RxSwiftDemo
//
//  Created by 夏语诚 on 2017/11/13.
//  Copyright © 2017年 Banana. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

class SimpleValidationViewModel {
    
    let usernameValid: Observable<Bool>
    let passwordValid: Observable<Bool>
    let everythingValid: Observable<Bool>
    
    init(username: Observable<String>, password: Observable<String>) {
        usernameValid = username
            .map { $0.count >= minimalUsernameLength }
            .share(replay: 1)
        
        passwordValid = password
            .map { $0.count >= minimalPasswordLenght }
            .share(replay: 1)
        
        everythingValid = Observable.combineLatest(usernameValid, passwordValid) { $0 && $1 }
            .share(replay: 1)
    }
}
