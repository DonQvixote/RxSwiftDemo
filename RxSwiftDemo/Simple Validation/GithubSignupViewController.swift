//
//  GithubSignupViewController.swift
//  RxSwiftDemo
//
//  Created by 夏语诚 on 2017/11/13.
//  Copyright © 2017年 Banana. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class GithubSignupViewController: UIViewController {

    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var usernameValidationLabel: UILabel!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var passwordValidationLabel: UILabel!
    @IBOutlet weak var repeatedPasswordTextField: UITextField!
    @IBOutlet weak var repeatedPasswordValidationLabel: UILabel!
    @IBOutlet weak var signupButton: UIButton!
    @IBOutlet weak var signingUpIndicator: UIActivityIndicatorView!
    
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let viewModel = GithubSignupViewModel(
            input: (
                username: usernameTextField.rx.text.orEmpty.asObservable(),
                password: passwordTextField.rx.text.orEmpty.asObservable(),
                repeatedPassword: repeatedPasswordTextField.rx.text.orEmpty.asObservable(),
                loginTaps: signupButton.rx.tap.asObservable()
            ),
            dependency: (
                API: GithubDefaultAPI.sharedAPI,
                validationService: GithubDefaultValidationService.sharedValidationService,
                wireframe: DefaultWireframe.shared
            )
        )
        
        viewModel.signupEnabled
            .subscribe(onNext: { [weak self] valid in
                self?.signupButton.isEnabled = valid
                self?.signupButton.alpha = valid ? 1.0 : 0.5
            })
            .disposed(by: disposeBag)
        
        viewModel.validatedUsername
            .bind(to: usernameValidationLabel.rx.validationResult)
            .disposed(by: disposeBag)
        
        viewModel.validatedPassword
            .bind(to: passwordValidationLabel.rx.validationResult)
            .disposed(by: disposeBag)
        
        viewModel.validatedRepeatedPassword
            .bind(to: repeatedPasswordValidationLabel.rx.validationResult)
            .disposed(by: disposeBag)
        
        viewModel.signingIn
            .bind(to: signingUpIndicator.rx.isAnimating)
            .disposed(by: disposeBag)
        
        viewModel.signedIn
            .subscribe(onNext: { signedIn in
                print("User signed in \(signedIn)")
            })
            .disposed(by: disposeBag)
        
        let tapBackground = UITapGestureRecognizer()
        tapBackground.rx.event
            .subscribe(onNext: { [weak self] _ in
                self?.view.endEditing(true)
            })
            .disposed(by: disposeBag)
        view.addGestureRecognizer(tapBackground)
    }
}
