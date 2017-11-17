//
//  GithubSearchRepositoriesAPI.swift
//  RxSwiftDemo
//
//  Created by 夏语诚 on 2017/11/17.
//  Copyright © 2017年 Banana. All rights reserved.
//

import RxSwift

struct Repository: CustomDebugStringConvertible {
    var name: String
    var url: URL
    
    init(name: String, url: URL) {
        self.name = name
        self.url = url
    }
}

extension Repository {
    var debugDescription: String{
        return "\(name) | \(url)"
    }
}

enum Result<T, E: Error> {
    case success(T)
    case failure(E)
}

enum GithubServiceError: Error {
    case offline
    case githubLimitReached
    case networkError
}

extension GithubServiceError {
    var displayMessage: String {
        switch self {
        case .offline:
            return "Ups, no network connectivity"
        case .githubLimitReached:
            return "Reached Github throttle limit, wait 60 sec"
        case .networkError:
            return "Network error"
        }
    }
}

struct SystemError: Error {
    let message: String
    let file: StaticString
    let line: UInt
    
    init(_ message: String, file: StaticString = #file, line: UInt = #line) {
        self.message = message
        self.file = file
        self.line = line
    }
}

typealias SearchRepositoriesResponse = Result<(repositories: [Repository], nextURL: URL?), GithubServiceError>

extension Repository {
    static func parse(httpResponse: HTTPURLResponse, data: Data) throws -> SearchRepositoriesResponse {
        if httpResponse.statusCode == 403 {
            return .failure(.githubLimitReached)
        }
        
        let jsonRoot = try Repository.parseJSON(httpResponse, data: data)
        
        guard let json = jsonRoot as? [String: AnyObject] else {
            throw SystemError("Casting to dictionary failed")
        }
        
        let repositories = try Repository.parse(json)
        
        let nextURL = try Repository.parseNextURL(httpResponse)
        
        return .success((repositories: repositories, nextURL: nextURL))
    }
    
    private static let parseLinksPattern = "\\s*,?\\s*<([^\\>]*)>\\s*;\\s*rel=\"([^\"]*)\""
    private static let linksRegex = try! NSRegularExpression(pattern: parseLinksPattern, options: [.allowCommentsAndWhitespace])
    
    private static func parse(_ json: [String: AnyObject]) throws -> [Repository] {
        guard let items = json["items"] as? [[String: AnyObject]] else {
            throw SystemError("Can't find items")
        }
        return try items.map { item in
            guard let name = item["name"] as? String,
                let url = item["url"] as? String else {
                    throw SystemError("Can't parse repository")
            }
            guard let parsedURL = URL(string: url) else {
                throw SystemError("Invalid url")
            }
            return Repository(name: name, url: parsedURL)
        }
    }
    
    private static func parseLinks(_ links: String) throws -> [String: String] {
        
        let length = (links as NSString).length
        let matches = Repository.linksRegex.matches(in: links, options: NSRegularExpression.MatchingOptions(), range: NSRange(location: 0, length: length))
        
        var result: [String: String] = [:]
        
        for m in matches {
            let matches = (1 ..< m.numberOfRanges).map { rangeIndex -> String in
                let range = m.range(at: rangeIndex)
                let startIndex = links.index(links.startIndex, offsetBy: range.location)
                let endIndex = links.index(links.startIndex, offsetBy: range.location + range.length)
                return String(links[startIndex ..< endIndex])
            }
            
            if matches.count != 2 {
                throw SystemError("Error parsing links")
            }
            
            result[matches[1]] = matches[0]
        }
        
        return result
    }
    
    private static func parseNextURL(_ httpResponse: HTTPURLResponse) throws -> URL? {
        guard let serializedLinks = httpResponse.allHeaderFields["Link"] as? String else {
            return nil
        }
        
        let links = try Repository.parseLinks(serializedLinks)
        
        guard let nextPageURL = links["next"] else {
            return nil
        }
        
        guard let nextUrl = URL(string: nextPageURL) else {
            throw SystemError("Error parsing next url `\(nextPageURL)`")
        }
        
        return nextUrl
    }
    
    private static func parseJSON(_ httpResponse: HTTPURLResponse, data: Data) throws -> AnyObject {
        if !(200 ..< 300 ~= httpResponse.statusCode) {
            throw SystemError("Call failed")
        }
        
        return try JSONSerialization.jsonObject(with: data, options: []) as AnyObject
    }
}
