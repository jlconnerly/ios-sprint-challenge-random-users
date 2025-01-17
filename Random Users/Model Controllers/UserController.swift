//
//  UserController.swift
//  Random Users
//
//  Created by Jake Connerly on 10/4/19.
//  Copyright © 2019 Erica Sadun. All rights reserved.
//

import Foundation

enum HTTPMethod: String {
    case get    = "GET"
    case put    = "PUT"
    case post   = "POST"
    case delete = "DELETE"
}

enum NetworkError: Error {
    case noAuth
    case badAuth
    case otherError(Error)
    case badData
    case noDecode
    case noEncode
    case badResponse
}

enum ResultLimiter: String {
    case name
    case email
    case cell
    case picture
    case id
    case login
}

class UserController {
    
    //MARK: - Properties
    
    let baseURL = URL(string: "https://randomuser.me/api/")!
    var users: [User] = []
    
    
    private func cleanURL(numberOfUsers results: Int) -> URL {
        let url = baseURL
        let resultsCountString = String(results)
        
        var infoLimiter = ""
        let limiters: [ResultLimiter] = [.name, .email, .cell, .picture, .id, .login]
        for limiter in limiters {
            infoLimiter.append("\(limiter.rawValue),")
        }
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)!
        
        urlComponents.queryItems = [URLQueryItem(name: "results", value: resultsCountString), URLQueryItem(name: "inc", value: infoLimiter)]
        return urlComponents.url!
    }
    
    //MARK: - FetchUsers
    
    func fetchUsers(amountOfUsers: Int, using session: URLSession = URLSession.shared, completion: @escaping ([User]?, Error?) -> Void) {
        
        let request = URLRequest(url: cleanURL(numberOfUsers: amountOfUsers))
        
        session.dataTask(with: request) { (data, _, error) in
            if let error = error {
                NSLog("error fetching user:\(error)")
                return
            }
            
            guard let data = data else {
                NSLog("bad data")
                return
            }
            
            do{
                let results = try JSONDecoder().decode(Results.self, from: data)
                self.users = results.results
            } catch {
                NSLog("Unable to decode users:\(error)")
            }
            
            completion(self.users, nil)
            
        }.resume()
    }
}
