//
//  UsersTableViewController.swift
//  Random Users
//
//  Created by Jake Connerly on 10/4/19.
//  Copyright © 2019 Erica Sadun. All rights reserved.
//

import UIKit

class UsersTableViewController: UITableViewController {

    //MARK: - Properties
    
    let userController = UserController()
    private let photoFetchQueue = OperationQueue()
    let imageCache = Cache<String, Data>()
    private var operations = [String: Operation]()
    var userCount = 10
    
    // MARK: - View LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchUsers(amountOfUsers: userCount)
    }
    
    // MARK: - IBActions & Methods
    
    @IBAction func addButtonTapped(_ sender: UIBarButtonItem) {
        userCount += 10
        fetchUsers(amountOfUsers: userCount)
    }
    
    func fetchUsers(amountOfUsers: Int) {
        userController.fetchUsers(amountOfUsers: userCount) { (users, error) in
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    private func loadImage(forCell cell: CustomUserTableViewCell, forRowAt indexPath: IndexPath) {
        let user = userController.users[indexPath.row]
        
        if let cachedData = imageCache.value(for: user.login.uuid),
            let image = UIImage(data: cachedData) {
            cell.userImageView.image = image
            return
        }
        
        //MARK: - Operations Queue
        
        let fetchOp = FetchPhotoOperation(user: user)
        
        let cacheOp = BlockOperation {
            if let data = fetchOp.imageData {
                self.imageCache.cache(value: data, for: user.login.uuid)
            }
        }
        
        let completionOp = BlockOperation {
            defer { self.operations.removeValue(forKey: user.login.uuid) }
            if let currentIndexPath = self.tableView.indexPath(for: cell),
               currentIndexPath != indexPath {
                print("Got image for reused cell")
                return
            }
            if let data = fetchOp.imageData {
                cell.userImageView.image = UIImage(data: data)
            }
            
        }
        
        cacheOp.addDependency(fetchOp)
        completionOp.addDependency(fetchOp)
        photoFetchQueue.addOperation(fetchOp)
        photoFetchQueue.addOperation(cacheOp)
        OperationQueue.main.addOperation(completionOp)
        
        operations[user.login.uuid] = fetchOp
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowUserSegue" {
            guard let detailVC = segue.destination as? UserDetailViewController,
                let indexPath = tableView.indexPathForSelectedRow else { return }
            let user = userController.users[indexPath.row]
            detailVC.user = user
        }
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userController.users.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell", for: indexPath) as? CustomUserTableViewCell else { return UITableViewCell() }
        loadImage(forCell: cell, forRowAt: indexPath)
        let user = userController.users[indexPath.row]
        let fullName = "\(user.name.firstName) \(user.name.lastName)"
        cell.nameLabel.text = fullName
        return cell
    }
}
