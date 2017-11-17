//
//  GithubSearchRxFeedbackViewController.swift
//  RxSwiftDemo
//
//  Created by 夏语诚 on 2017/11/16.
//  Copyright © 2017年 Banana. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxFeedback

fileprivate struct State {
    var search: String {
        didSet {
            if search.isEmpty {
                self.nextPageURL = nil
                self.shouldLoadNextPage = false
                self.results = []
                self.lastError = nil
                return
            }
            self.nextPageURL = URL(string: "https://api.github.com/search/repositories?q=\(search.URLEscaped)")
            self.shouldLoadNextPage = true
            self.lastError = nil
        }
    }
    
    var nextPageURL: URL?
    var shouldLoadNextPage: Bool
    var results: [Repository]
    var lastError: GithubServiceError?
}

extension State {
    var loadNextPage: URL? {
        return self.shouldLoadNextPage ? self.nextPageURL : nil
    }
}

enum Event {
    case searchChanged(String)
    case response(SearchRepositoriesResponse)
    case startLoadingNextPage
}

extension State {
    static var empty: State {
        return State(search: "", nextPageURL: nil, shouldLoadNextPage: true, results: [], lastError: nil)
    }
    static func reduce(state: State, event: Event) -> State {
        switch event {
        case .searchChanged(let search):
            var result = state
            result.search = search
            result.results = []
            return result
        case .startLoadingNextPage:
            var result = state
            result.shouldLoadNextPage = true
            return result
        case .response(.success(let reponse)):
            var result = state
            result.results += reponse.repositories
            result.shouldLoadNextPage = false
            result.nextPageURL = reponse.nextURL
            result.lastError = nil
            return result
        case .response(.failure(let error)):
            var result = state
            result.shouldLoadNextPage = false
            result.lastError = error
            return result
        }
    }
}

class GithubSearchRxFeedbackViewController: UIViewController {

    @IBOutlet weak var searchResults: UITableView!
    @IBOutlet weak var searchText: UISearchBar!
    @IBOutlet weak var status: UILabel!
    @IBOutlet weak var loadNextPage: UILabel!
    
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        let searchResults = self.searchResults
        searchResults?.register(UITableViewCell.self, forCellReuseIdentifier: "repo")
        
        let triggerLoadNextPage: (Driver<State>) -> Signal<Event> = { state in
            return state.flatMapLatest { state -> Signal<Event> in
                if state.shouldLoadNextPage {
                    return Signal.empty()
                }

                return searchResults!.rx.nearBottom.map { _ in Event.startLoadingNextPage }
            }
        }
        
        func configrueRepository(_: Int, repo: Repository, cell: UITableViewCell) {
            cell.textLabel?.text = repo.name
            cell.detailTextLabel?.text = repo.url.description
        }
        
        let bindUI: (Driver<State>) -> Signal<Event> = bind(self) { me, state in
            let subscriptions = [
                state.map { $0.search }.drive(me.searchText.rx.text),
                state.map { $0.lastError?.displayMessage }.drive(me.status.rx.textOrHide),
                state.map { $0.results }.drive((searchResults?.rx.items(cellIdentifier: "repo"))!)(configrueRepository),
                state.map { $0.loadNextPage?.description }.drive(me.loadNextPage.rx.textOrHide)
            ]
            let events: [Signal<Event>] = [
                me.searchText.rx.text.orEmpty.changed.asSignal().map(Event.searchChanged),
                triggerLoadNextPage(state)
            ]
            return Bindings(subscriptions: subscriptions, events: events)
        }
        Driver.system(
            initialState: State.empty,
            reduce: State.reduce,
            feedback:
                bindUI,
            react(query: { $0.loadNextPage },
                  effects: { resource in
                    return URLSession.shared.loadRepositories(resource: resource)
                        .asSignal(onErrorJustReturn: .failure(.offline))
                        .map(Event.response)
            })
        )
        .drive()
        .disposed(by: disposeBag)
    }

}

extension URLSession {
    func loadRepositories(resource: URL) -> Observable<SearchRepositoriesResponse> {
        let maxAttempts = 4
        
        return self
            .rx
            .response(request: URLRequest(url: resource))
            .retry(3)
            .map(Repository.parse)
            .retryWhen { errorTrigger in
                return errorTrigger.enumerated().flatMap { (attempt, error) -> Observable<Int> in
                    if attempt >= maxAttempts - 1 {
                        return Observable.error(error)
                    }
                    return Observable<Int>
                        .timer(Double(attempt + 1), scheduler: MainScheduler.instance).take(1)
            }
        }
    }
}
