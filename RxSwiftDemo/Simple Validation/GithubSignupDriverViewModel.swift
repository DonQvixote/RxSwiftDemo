//
//  GithubSignupDriverViewModel.swift
//  RxSwiftDemo
//
//  Created by 夏语诚 on 2017/11/16.
//  Copyright © 2017年 Banana. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class GithubSignupDriverViewModel {
    
    let validatedUsername: Driver<ValidationResult>
    let validatedPassword: Driver<ValidationResult>
    let validatedRepeatedPassword: Driver<ValidationResult>
    let signupEnabled: Driver<Bool>
    let signedIn: Driver<Bool>
    let signingIn: Driver<Bool>
    
    init(
        input: (
            username: Driver<String>,
            password: Driver<String>,
            repeatedPassword: Driver<String>,
            loginTaps: Driver<Void>
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
            .flatMapLatest { username in
                return validationService.validateUsername(username)
                    .asDriver(onErrorJustReturn: .failed(message: "Error contacting server"))
            }
        
        validatedPassword = input.password
            .map { password in
                return validationService.validatePassword(password)
            }
        
        validatedRepeatedPassword = Driver.combineLatest(input.password, input.repeatedPassword, resultSelector: validationService.validateRepeatedPassword)

        let signingIn = ActivityIndicator()
        self.signingIn = signingIn.asDriver()
        
        let usernameAndPassword = Driver.combineLatest(input.username, input.password) { (username: $0, password: $1) }
        
        signedIn = input.loginTaps.withLatestFrom(usernameAndPassword)
            .flatMapLatest { pair in
                return API.signup(pair.username, password: pair.password)
                    .trackActivity(signingIn)
                    .asDriver(onErrorJustReturn: false)
            }
            .flatMapLatest { loggedIn -> Driver<Bool> in
                let message = loggedIn ? "Mock: Signed in to Github." : "Mock: Sign in to Github failed"
                return wireframe.promptFor(message, cancelAction: "OK", actions: [])
                    .map { _ in
                        loggedIn
                    }
                    .asDriver(onErrorJustReturn: false)
            }
        
        signupEnabled = Driver.combineLatest(validatedUsername, validatedPassword, validatedRepeatedPassword, signingIn) {
            username, password, repeatedPassword, signingIn in
            username.isValid && password.isValid && repeatedPassword.isValid && !signingIn
        }
        .distinctUntilChanged()
    }
}
