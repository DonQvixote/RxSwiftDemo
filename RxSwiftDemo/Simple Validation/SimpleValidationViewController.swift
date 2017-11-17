//
//  SimpleValidationViewController.swift
//  RxSwiftDemo
//
//  Created by 夏语诚 on 2017/11/2.
//  Copyright © 2017年 Banana. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

let minimalUsernameLength = 5
let minimalPasswordLenght = 6

class SimpleValidationViewController: UIViewController {

    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var usernameValidLabel: UILabel!
    
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var passwordValidLabel: UILabel!
    
    @IBOutlet weak var signInButton: UIButton!
    
    let disposeBag = DisposeBag()
    
    private var viewModel: SimpleValidationViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        usernameValidLabel.text = "Username has to be at least \(minimalUsernameLength) characters"
        passwordValidLabel.text = "Password has to be at least \(minimalPasswordLenght) characters"
        
        viewModel = SimpleValidationViewModel(
            username: usernameTextField.rx.text.orEmpty.asObservable(),
            password: passwordTextField.rx.text.orEmpty.asObservable()
        )
        
        viewModel.usernameValid
            .bind(to: usernameValidLabel.rx.isHidden)
            .disposed(by: disposeBag)
        
        viewModel.usernameValid
            .bind(to: passwordTextField.rx.isEnabled)
            .disposed(by: disposeBag)
        
        viewModel.passwordValid
            .bind(to: passwordValidLabel.rx.isHidden)
            .disposed(by: disposeBag)
        
        viewModel.everythingValid
            .bind(to: signInButton.rx.isEnabled)
            .disposed(by: disposeBag)
        
        viewModel.everythingValid
            .bind { [weak self] valid in
                self?.signInButton.alpha = valid ? 1 : 0.5
            }
            .disposed(by: disposeBag)
        
        signInButton.rx.tap
            .subscribe(onNext: { [weak self] in self?.showAlert() })
            .disposed(by: disposeBag)
    }

    func showAlert() {
        let alert = UIAlertController(title: "Success", message: "Sign In!", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}
