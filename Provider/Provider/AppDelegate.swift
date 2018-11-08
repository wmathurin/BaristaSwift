/*
  AppDelegate.swift
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
import SalesforceSDKCore
import SalesforceMobileSDKPromises
import SmartSync
import Fabric
import Crashlytics
import Common
import PromiseKit

// Primary
// SFDCOAuthLoginHost - app-data-4945-dev-ed.cs62.my.salesforce.com

// Backup
// SFDCOAuthLoginHost - innovation-saas-8421-dev-ed.cs54.my.salesforce.com
//let RemoteAccessConsumerKey = "3MVG9XmM8CUVepGaQs_Zw_6A0W73CMRjybtIuqOlXJ6m7yb9FSRjbrLnj388H9rOXzRJG6hbPY0KyXKi_orlr"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    override init() {
        super.init()
        _ =  SalesforceSwiftSDKManager.initSDK()
       
        AuthHelper.registerBlock(forCurrentUserChangeNotifications: { [weak self] in
            self?.resetViewState {
                self?.setupRootViewController()
            }
        })
        
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.initializeAppViewState();
        
        let navAppearance = UINavigationBar.appearance()
        navAppearance.barTintColor = Theme.appNavBarTintColor
        navAppearance.titleTextAttributes = [NSAttributedStringKey.foregroundColor: Theme.appNavBarTextColor, NSAttributedStringKey.font: Theme.appMediumFont(14.0)!]
        
        // If you wish to register for push notifications, uncomment the line below.  Note that,
        // if you want to receive push notifications from Salesforce, you will also need to
        // implement the application:didRegisterForRemoteNotificationsWithDeviceToken: method (below).
        //
        // SFPushNotificationManager.sharedInstance().registerForRemoteNotifications()
        
        //Uncomment the code below to see how you can customize the color, textcolor, font and fontsize of the navigation bar
        //var loginViewConfig = LoginViewControllerConfig()
        //Set showSettingsIcon to NO if you want to hide the settings icon on the nav bar
        //loginViewConfig.showSettingsIcon = false
        //Set showNavBar to NO if you want to hide the top bar
        //loginViewConfig.showNavbar = true
        //loginViewConfig.navBarColor = UIColor(red: 0.051, green: 0.765, blue: 0.733, alpha: 1.0)
        //loginViewConfig.navBarTextColor = UIColor.white
        //loginViewConfig.navBarFont = UIFont(name: "Helvetica", size: 16.0)
        //UserAccountManager.sharedInstance().loginViewControllerConfig = loginViewConfig
        
        AuthHelper.loginIfRequired { [weak self] in
            if let _ = UserAccountManager.sharedInstance().currentUserIdentity?.userId {
                _ = AccountStore.instance.syncDown()
                    .then { _ -> Promise<Account> in
                        return AccountStore.instance.getOrCreateMyAccount()
                    }
                    .then { _ -> Promise<Void> in
                        return (self?.beginSyncDown())!
                    }
                    .done { _ in
                        DispatchQueue.main.async {
                            self?.setupRootViewController()
                        }
                }
            } else {
                UserAccountManager.sharedInstance().logout()
            }
        }
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    // MARK: - Private methods
    func initializeAppViewState() {
        if (!Thread.isMainThread) {
            DispatchQueue.main.async {
                self.initializeAppViewState()
            }
            return
        }
        
        self.window!.rootViewController = InitialViewController(nibName: nil, bundle: nil)
        self.window!.makeKeyAndVisible()
    }
    
    func setupRootViewController() {
        self.window?.rootViewController = ViewController(nibName: nil, bundle: nil)
    }
    
    func beginSyncDown() -> Promise<Void> {
        let syncs : [Promise<Void>] = [
            UserStore.instance.syncDown(),
            AccountStore.instance.syncDown(),
            ProductStore.instance.syncDown(),
            ProductOptionStore.instance.syncDown(),
            QuoteStore.instance.syncDown(),
            QuoteLineItemStore.instance.syncDown(),
            QuoteLineGroupStore.instance.syncDown(),
            OpportunityStore.instance.syncDown(),
            PricebookStore.instance.syncDown()
        ]
        
        return when(fulfilled: syncs)
    }
    
    func resetViewState(_ postResetBlock: @escaping () -> ()) {
        if let rootViewController = self.window!.rootViewController {
            if let _ = rootViewController.presentedViewController {
                rootViewController.dismiss(animated: false, completion: postResetBlock)
                return
            }
        }
        
        postResetBlock()
    }

}

