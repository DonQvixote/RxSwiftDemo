//
//  GithubSignupDriverViewController.swift
//  RxSwiftDemo
//
//  Created by 夏语诚 on 2017/11/16.
//  Copyright © 2017年 Banana. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class GithubSignupDriverViewController: UIViewController {
    
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

        // Do any additional setup after loading the view.
        let viewModel = GithubSignupDriverViewModel(
            input: (
                username: usernameTextField.rx.text.orEmpty.asDriver(),
                password: passwordTextField.rx.text.orEmpty.asDriver(),
                repeatedPassword: repeatedPasswordTextField.rx.text.orEmpty.asDriver(),
                loginTaps: signupButton.rx.tap.asDriver()
            ),
            dependency: (
                API: GithubDefaultAPI.sharedAPI,
                validationService: GithubDefaultValidationService.sharedValidationService,
                wireframe: DefaultWireframe.shared
            )
        )
        
        viewModel.signupEnabled
            .drive(onNext: { [weak self] valid in
                self?.signupButton.isEnabled = valid
                self?.signupButton.alpha = valid ? 1.0 : 0.5
            })
            .disposed(by: disposeBag)
        
        viewModel.validatedUsername
            .drive(usernameValidationLabel.rx.validationResult)
            .disposed(by: disposeBag)
        
        viewModel.validatedPassword
            .drive(passwordValidationLabel.rx.validationResult)
            .disposed(by: disposeBag)
        
        viewModel.validatedRepeatedPassword
            .drive(repeatedPasswordValidationLabel.rx.validationResult)
            .disposed(by: disposeBag)
        
        viewModel.signingIn
            .drive(signingUpIndicator.rx.isAnimating)
            .disposed(by: disposeBag)
        
        viewModel.signedIn
            .drive(onNext: { signedIn in
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
