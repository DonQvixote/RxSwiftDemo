//
//  SimpleTableViewController.swift
//  RxSwiftDemo
//
//  Created by 夏语诚 on 2017/11/9.
//  Copyright © 2017年 Banana. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources

class SimpleTableViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    let dataSource = RxTableViewSectionedReloadDataSource<SectionModel<String, Double>>(configureCell: { (_, tv, indexPath, element) in
        let cell = tv.dequeueReusableCell(withIdentifier: "Cell")!
        cell.textLabel?.text = "\(element) @ row \(indexPath.row)"
        return cell
    }, titleForHeaderInSection: { (dataSource, sectionIndex) in
        return dataSource[sectionIndex].model
    })
    
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let dataSource = self.dataSource
        
        let items = Observable.just([
            SectionModel(model: "First Section", items: [
                    1.0,
                    2.0,
                    3.0
                ]),
            SectionModel(model: "Second Setion",items: [
                    1.0,
                    2.0,
                    3.0
                ]),
            SectionModel(model: "Third Section", items: [
                    1.0,
                    2.0,
                    3.0
                ])
            ])
        
        items
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
        tableView.rx
            .setDelegate(self)
            .disposed(by: disposeBag)
        
        tableView.rx
            .itemSelected
            .map { indexPath in
                return (indexPath, dataSource[indexPath])
            }
            .subscribe(onNext: { pair in
                let alert = UIAlertController(title: "RxSwfitDemo", message: "Tapped `\(pair.1)` @ \(pair.0)", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
                self.tableView.deselectRow(at: pair.0, animated: true)
            })
            .disposed(by: disposeBag)
        
        tableView.tableFooterView = UIView(frame: .zero)
    }
}

extension SimpleTableViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .none
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
}
