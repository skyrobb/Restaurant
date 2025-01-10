//
//  OrderTableViewController.swift
//  Restaruant
//
//  Created by Skyler Robbins on 1/9/25.
//

import UIKit

class OrderTableViewController: UITableViewController {
    var imageLoadTasks: [IndexPath: Task<Void, Never>] = [:]
    
    var minutesToPrepareOrder = 0
    
    @IBOutlet weak var submitButton: UIBarButtonItem!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = editButtonItem
        NotificationCenter.default.addObserver(tableView!, selector: #selector(UITableView.reloadData), name: MenuController.orderUpdatedNotification, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        MenuController.shared.updateUserActivity(with: .order)
        tabBarButtonStyle()
    }
    
    func tabBarButtonStyle() {
        if MenuController.shared.order.menuItems.isEmpty {
            submitButton.isEnabled = false
            navigationItem.leftBarButtonItem?.isEnabled = false
        } else {
            submitButton.isEnabled = true
            navigationItem.leftBarButtonItem?.isEnabled = true
        }
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return MenuController.shared.order.menuItems.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Order", for: indexPath)

        // Configure the cell...
        configure(cell, atItemFor: indexPath)
        return cell
    }
    
    func configure(_ cell: UITableViewCell, atItemFor indexPath: IndexPath) {
        guard let cell = cell as? MenuItemCell else { return }
        
        let menuItem = MenuController.shared.order.menuItems[indexPath.row]

        cell.itemName = menuItem.name
        cell.price = menuItem.price
        cell.image = nil

        imageLoadTasks[indexPath] = Task.init {
            if let image = try? await MenuController.shared.fetchImage(from: menuItem.imageURL) {
                if let currentIndexPath = self.tableView.indexPath(for: cell), currentIndexPath == indexPath {
                    cell.image = image
                }
            }
            imageLoadTasks[indexPath] = nil
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {

        return true
    }
    
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            tableView.beginUpdates()
            tableView.deleteRows(at: [indexPath], with: .fade)
            MenuController.shared.order.menuItems.remove(at: indexPath.item)
            tableView.endUpdates()

            tabBarButtonStyle()
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        44
    }

    
    @IBSegueAction func confirmOrder(_ coder: NSCoder, sender: Any?) -> OrderConfirmationViewController? {
        return OrderConfirmationViewController(coder: coder, minutesToPrepare: minutesToPrepareOrder)
    }
    
    @IBAction func submitTapped(_ sender: Any) {
        let orderTotal = MenuController.shared.order.menuItems.reduce(0.0) {
            (result, MenuItem) -> Double in
            return result + MenuItem.price
        }
        
        let formattedTotal = orderTotal.formatted(.currency(code: "usd"))
        
        let alertController = UIAlertController(title: "Confirm Order", message: "You are about to submit your order with a total of \(formattedTotal)", preferredStyle: .actionSheet)
        
        alertController.addAction(UIAlertAction(title: "Submit", style: .default, handler: { _ in
            self.uploadOrder()
        }))
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(alertController, animated: true, completion: nil)
    }
    
    func uploadOrder() {
        let menuIds = MenuController.shared.order.menuItems.map { $0.id }
        Task.init{
            do {
                let minuteToPrepare = try await MenuController.shared.submitOrder(forMenuIDs: menuIds)
                minutesToPrepareOrder = minuteToPrepare
                performSegue(withIdentifier: "confirmOrder", sender: nil)
            } catch {
                displayError(error, title: "Order Submission Failed")
            }
        }
    }
    
    func displayError(_ error: Error, title: String) {
        guard let _ = viewIfLoaded?.window else { return }
        
        let alert = UIAlertController(title: title, message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func unwindToOrderList(segue: UIStoryboardSegue) {
        if segue.identifier == "dismissConfirmation" {
            MenuController.shared.order.menuItems.removeAll()
            tableView.reloadData()
        }
    }
}
