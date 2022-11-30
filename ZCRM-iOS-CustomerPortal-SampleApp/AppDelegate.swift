//
//  AppDelegate.swift
//  ZCRM-iOS-CustomerPortal-SampleApp
//
//  Created by Umashri R on 12/09/19.
//  Copyright © 2019 Umashri R. All rights reserved.
//

import UIKit
import CoreData
import ZCRMiOS

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    private var appConfigurationDict : Dictionary< String, Any > = Dictionary< String, Any >()
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        do
        {
            self.window = UIWindow(frame: UIScreen.main.bounds)
            self.window?.makeKeyAndVisible()
            
            let viewController = ViewController()
            let navController = UINavigationController( rootViewController : viewController )
            self.window?.rootViewController = navController
            self.window?.makeKeyAndVisible()
            
            if let window = self.window
            {
                
                //Replace *** with your credentials
                let zcrmSDKConfig = try ZCRMSDKConfigs.Builder(clientId: "---CLIENT_ID---", clientSecret: "---CLIENT_SECRET---", redirectURL: "---REDIRECT_URL---", oauthScopes: ["ZohoCRM.settings.ALL", "ZohoCRM.modules.ALL", "ZohoCRM.users.READ", "ZohoCRM.org.READ", "Aaaserver.profile.Read", "profile.userphoto.READ" ], portalId: "---PORTAL_ID---").setAPPType( .zcrmcp ).setAPIBaseURL( "crm.zoho.com" ).setAccountsURL( "https://accounts.zohoportal.com" ).build()
                try zcrmSDKConfig.validateProperties()
                try ZCRMSDKClient.shared.initSDK(window: window, appConfiguration: zcrmSDKConfig)
                
                ZCRMSDKClient.shared.turnLoggerOn( minLogLevel : .debug )
                ZCRMSDKClient.shared.requestHeaders = Dictionary< String, String >()
                ZCRMSDKClient.shared.requestHeaders?[ "X-CRMPORTAL" ] = "---PORTAL_NAME---" // Replace *** with your Portal
            }
            else
            {
                print("Window is nil")
            }
        }
        catch
        {
            print("unable to init ZCRMiOS SDK : \(error)")
        }
        return true
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        ZCRMSDKClient.shared.handle(url: url, sourceApplication: sourceApplication, annotation: annotation)
        return true
    }
    
    func application( _ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        let sourceapp = options[ UIApplication.OpenURLOptionsKey.sourceApplication ]
        ZCRMSDKClient.shared.handle(url: url, sourceApplication: sourceapp as? String, annotation: "")
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
        self.saveContext()
    }
    
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "TestingWithPod")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}

