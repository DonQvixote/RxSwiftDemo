//
//  GithubSignupViewModel.swift
//  RxSwiftDemo
//
//  Created by 夏语诚 on 2017/11/13.
//  Copyright © 2017年 Banana. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class GithubSignupViewModel {
    let validatedUsername: Observable<ValidationResult>
    let validatedPassword: Observable<ValidationResult>
    let validatedRepeatedPassword: Observable<ValidationResult>
    let signupEnabled: Observable<Bool>
    let signedIn: Observable<Bool>
    let signingIn: Observable<Bool>

    init(input: (
            username: Observable<String>,
            password: Observable<String>,
            repeatedPassword: Observable<String>,
            loginTaps: Observable<Void>
        ),
         dependency: (
            API: GithubAPI,
            validationService: GithubValidationService,
            wireframe: Wireframe
        )
    ) {
        let API = dependency.API
        let validationService = dependency.validationService
        let wireframe = dependency.wireframe
        
        validatedUsername = input.username
            .flatMapLatest({ username in
                return validationService.validateUsername(username)
                    .observeOn(MainScheduler.instance)
                    .catchErrorJustReturn(.failed(message: "Error contacting server"))
            })
            .share(replay: 1)
        
        validatedPassword = input.password
            .map { password in
                return validationService.validatePassword(password)
            }
            .share(replay: 1)
        
        validatedRepeatedPassword = Observable.combineLatest(input.password, input.repeatedPassword, resultSelector: validationService.validateRepeatedPassword)
            .share(replay: 1)
        
        let signingIn = ActivityIndicator()
        self.signingIn = signingIn.asObservable()
        
        let usernameAndPassword = Observable.combineLatest(input.username, input.password) { (username: $0, password: $1) }
        
        signedIn = input.loginTaps.withLatestFrom(usernameAndPassword)
            .flatMapLatest { pair in
                return API.signup(pair.username, password: pair.password)
                    .observeOn(MainScheduler.instance)
                    .catchErrorJustReturn(false)
                    .trackActivity(signingIn)
            }
            .flatMapLatest { loggedIn -> Observable<Bool> in
                let message = loggedIn ? "Mock: Signed in to Github." : "Mock: Sign in to Github failed"
                return wireframe.promptFor(message, cancelAction: "OK", actions: [])
                    .map { _ in
                        loggedIn
                    }
            }
            .share(replay: 1)
        
        signupEnabled = Observable.combineLatest(validatedUsername, validatedPassword, validatedRepeatedPassword, signingIn.asObservable())
            { (username, password, repeatPassword, signingIn) in
                username.isValid && password.isValid && repeatPassword.isValid && !signingIn
            }
            .distinctUntilChanged()
            .share(replay: 1)
    }
}

