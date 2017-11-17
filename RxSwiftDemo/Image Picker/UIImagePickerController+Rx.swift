//
//  UIImagePickerController+RxCreate.swift
//  RxSwiftDemo
//
//  Created by 夏语诚 on 2017/11/2.
//  Copyright © 2017年 Banana. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

func dismissViewController(_ viewController: UIViewController, animated: Bool) {
    if viewController.isBeingDismissed || viewController.isBeingPresented {
        DispatchQueue.main.async {
            dismissViewController(viewController, animated: animated)
        }
        
        return
    }
    
    if viewController.presentingViewController != nil {
        viewController.dismiss(animated: animated, completion: nil)
    }
}

fileprivate func castOrThrow<T>(_ resultType: T.Type, _ object: Any) throws -> T {
    guard let returnValue = object as? T else {
        throw RxCocoaError.castingError(object: object, targetType: resultType)
    }
    return returnValue
}

class RxImagePickerDelegateProxy: RxNavigationControllerDelegateProxy, UIImagePickerControllerDelegate {
    init(imagePicker: UIImagePickerController) {
        super.init(navigationController: imagePicker)
    }
}

extension Reactive where Base: UIImagePickerController {
    
    public var didCancel: Observable<Void> {
        return delegate
            .methodInvoked(#selector(UIImagePickerControllerDelegate.imagePickerControllerDidCancel(_:)))
            .map{ _ in }
    }
    
    public var didFinishPickingMediaWithInfo: Observable<[String: AnyObject]> {
        return delegate
            .methodInvoked(#selector(UIImagePickerControllerDelegate.imagePickerController(_:didFinishPickingMediaWithInfo:)))
            .map { a in
                return try castOrThrow(Dictionary<String, AnyObject>.self, a[1])
            }
    }
    
    static func createWithParent(_ parent: UIViewController?, animated: Bool = true,
                                 configureImagePicker: @escaping (UIImagePickerController) throws -> () = { x in }) ->
        Observable<UIImagePickerController> {
            return Observable.create({ [weak parent] observer in
                let imagePicker = UIImagePickerController()
                let dismissDisposable = imagePicker.rx
                    .didCancel
                    .subscribe(onNext: { [weak imagePicker] _ in
                        guard let imagePicker = imagePicker else {
                            return
                        }
                        dismissViewController(imagePicker, animated: animated)
                    })
                do {
                    try configureImagePicker(imagePicker)
                }
                catch let error {
                    observer.on(.error(error))
                    return Disposables.create()
                }
                
                guard let parent = parent else {
                    observer.on(.completed)
                    return  Disposables.create()
                }
                
                parent.present(imagePicker, animated: animated, completion: nil)
                observer.on(.next(imagePicker))
                
                return Disposables.create(dismissDisposable, Disposables.create {
                    dismissViewController(imagePicker, animated: animated)
                })
            })
    }
}
