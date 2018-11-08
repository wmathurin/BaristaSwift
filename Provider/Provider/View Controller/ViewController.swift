/*
  ViewController.swift
  Provider

  Created by Nicholas McDonald on 3/6/18.

 Copyright (c) 2018-present, salesforce.com, inc. All rights reserved.
 
 Redistribution and use of this software in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright notice, this list of conditions
 and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of
 conditions and the following disclaimer in the documentation and/or other materials provided
 with the distribution.
 * Neither the name of salesforce.com, inc. nor the names of its contributors may be used to
 endorse or promote products derived from this software without specific prior written
 permission of salesforce.com, inc.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
 CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
 WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import UIKit
import Common
import PromiseKit

class ViewController: UIViewController {
    
    fileprivate let completeButton = UIButton(type: .custom)
    fileprivate var tableView = UITableView(frame: .zero, style: .plain)
    fileprivate var refreshControl = UIRefreshControl()
    fileprivate var orders:[LocalOrder] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.white
        
        self.orders = LocalOrderStore.instance.currentOrders()
        
        let fauxNavBar = UIView()
        fauxNavBar.translatesAutoresizingMaskIntoConstraints = false
        fauxNavBar.backgroundColor = UIColor(displayP3Red: 246.0/255.0, green: 244.0/255.0, blue: 243.0/255.0, alpha: 1.0)
        self.view.addSubview(fauxNavBar)
        
        fauxNavBar.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        fauxNavBar.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        fauxNavBar.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        fauxNavBar.heightAnchor.constraint(equalToConstant: 80.0).isActive = true
        
        let navLabel = UILabel()
        navLabel.translatesAutoresizingMaskIntoConstraints = false
        navLabel.text = "Process Order"
        navLabel.font = Theme.appMediumFont(24.0)
        navLabel.textColor = UIColor(displayP3Red: 28.0/255.0, green: 15.0/255.0, blue: 11.0/255.0, alpha: 1.0)
        fauxNavBar.addSubview(navLabel)
        navLabel.centerXAnchor.constraint(equalTo: fauxNavBar.centerXAnchor).isActive = true
        navLabel.bottomAnchor.constraint(equalTo: fauxNavBar.bottomAnchor, constant:-12.0).isActive = true
        
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        self.tableView.backgroundColor = UIColor.clear
        self.tableView.separatorColor = UIColor(white: 0.0, alpha: 0.3)
        self.tableView.separatorInset = UIEdgeInsets.zero
        self.tableView.register(OrderTableViewCell.self, forCellReuseIdentifier: "itemCell")
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.estimatedRowHeight = 120.0
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.view.addSubview(self.tableView)
        
        self.refreshControl.tintColor = UIColor.gray
        self.refreshControl.addTarget(self, action: #selector(runRefresh), for: .valueChanged)
        self.tableView.refreshControl = self.refreshControl
        
        self.completeButton.translatesAutoresizingMaskIntoConstraints = false
        self.completeButton.setTitle("COMPLETE TOP ORDER", for: .normal)
        self.completeButton.titleLabel?.textColor = UIColor.white
        self.completeButton.titleLabel?.font = Theme.appBoldFont(24.0)
        self.completeButton.backgroundColor = Theme.appAccentColor01
        self.completeButton.addTarget(self, action: #selector(didPressCompleteTopOrder), for: .touchUpInside)
        self.view.addSubview(self.completeButton)
        
        self.tableView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.tableView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        self.tableView.topAnchor.constraint(equalTo: fauxNavBar.bottomAnchor).isActive = true
        self.tableView.bottomAnchor.constraint(equalTo: self.completeButton.topAnchor).isActive = true
        
        self.completeButton.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.completeButton.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        // hiding button for now
        self.completeButton.topAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        self.completeButton.heightAnchor.constraint(equalToConstant: 80.0).isActive = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @objc func didPressCompleteTopOrder() {
        if let order = self.orders.first {
            let activity = UIActivityIndicatorView(activityIndicatorStyle: .white)
            activity.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview(activity)
            activity.centerXAnchor.constraint(equalTo: self.completeButton.centerXAnchor).isActive = true
            activity.centerYAnchor.constraint(equalTo: self.completeButton.centerYAnchor).isActive = true
            activity.startAnimating()
            self.completeButton.isUserInteractionEnabled = false
            self.completeButton.setTitle("", for: .normal)
            _ = LocalOrderStore.instance.completeOrder(order)
                .then { LocalOrderStore.instance.syncDownOrders() }
                .done { _ in
                    self.updateData()

                    DispatchQueue.main.async {
                        activity.stopAnimating()
                        activity.removeFromSuperview()
                        self.completeButton.isUserInteractionEnabled = true
                        self.completeButton.setTitle("COMPLETE TOP ORDER", for: .normal)
                        
                    }
                }
        }
    }
    
    func completeLocally(order:LocalOrder) {
        LocalOrderStore.instance.locallyCompleteOrder(order)
    }
    
    func updateData() {
        self.orders = LocalOrderStore.instance.currentOrders()
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    @objc func runRefresh() {
        _ = self.runSync()
                .done {
                    self.updateData()
                    self.refreshControl.endRefreshing()
                }
    }
    
    func runSync() -> Promise<Void> {
        return LocalOrderStore.instance.syncUpDownOrders()
    }
}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1.0
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footer = UIView()
        footer.backgroundColor = UIColor(white: 0.5, alpha: 0.3)
        return footer
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UIView()
        header.backgroundColor = UIColor(white: 0.5, alpha: 0.3)
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 1.0
    }
}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.orders.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "itemCell") as! OrderTableViewCell
        cell.selectionStyle = .none
        let order = self.orders[indexPath.row]
        let opty = order.opportunity
        
        if let accountId = opty.accountName,
            let account = AccountStore.instance.account(forAccountId: accountId),
            let ownerId = account.ownerId,
            let user = UserStore.instance.user(ownerId) {
            let firstName = user.firstName
            cell.customerName = firstName
            if let photoUrl = user.appPhoto {
                cell.profilePhoto = photoUrl
            }
        }
        let time = opty.createdDate
        if let waiting = time?.timeIntervalSinceNow {
            let waitingString =  "\(UInt(floor(fabs(waiting)/60.0)))min"
            
            cell.timeWaiting = waitingString
        }
        for item in order.orderItems {
            cell.add(product: item.product, options: item.options)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let completeAction = UIContextualAction(style: .normal, title: "  COMPLETE  ") { (action, view, handler) in
            let order = self.orders[indexPath.row]
            self.completeLocally(order: order)
            // Necessary due to limiations of swipe actions
            self.orders.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .left)
            //
            handler(true)
            self.updateData()
            _ = self.runSync()
                .done { self.updateData() }
        }
        completeAction.backgroundColor = Theme.appAccentColor01
        let config = UISwipeActionsConfiguration(actions: [completeAction])
        return config
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let config = UISwipeActionsConfiguration(actions: [])
        return config
    }
}

