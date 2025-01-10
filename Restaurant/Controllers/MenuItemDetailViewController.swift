//
//  MenuItemDetailViewController.swift
//  Restaruant
//
//  Created by Skyler Robbins on 1/9/25.
//

import UIKit

@MainActor
class MenuItemDetailViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var itemNameLabel: UILabel!
    @IBOutlet weak var itemPriceLabel: UILabel!
    @IBOutlet weak var itemDetailsLabel: UILabel!
    @IBOutlet weak var addToOrderButton: UIButton!
    
    let menuItem: MenuItem
    
    init?(coder: NSCoder, menuItem: MenuItem) {
        self.menuItem = menuItem
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        updateUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        MenuController.shared.updateUserActivity(with: .menuItemDetail(menuItem))
    }
    
    func updateUI() {
        itemNameLabel.text = menuItem.name
        itemPriceLabel.text = menuItem.price.formatted(.currency(code: "usd"))
        itemDetailsLabel.text = menuItem.detailText
        
        Task.init {
            if let image = try? await MenuController.shared.fetchImage(from: menuItem.imageURL) {
                imageView.image = image
            }
        }
    }

    @IBAction func orderButtonTapper(_ sender: Any) {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.1, options: [], animations: {
            self.addToOrderButton.transform = CGAffineTransform(scaleX: 2, y: 2)
            self.addToOrderButton.transform = CGAffineTransform(scaleX: 1, y: 1)
        }, completion: nil)
        MenuController.shared.order.menuItems.append(menuItem)
    }
}
