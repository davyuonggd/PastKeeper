//
//  AppDelegate.swift
//  Makestagram
//
//  Created by Benjamin Encz on 5/15/15.
//  Copyright (c) 2015 Make School. All rights reserved.
//

import UIKit
import Parse
//for login mechanism
import FBSDKCoreKit
import ParseUI

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    var parseLoginHelper: ParseLoginHelper!
    
    override init() {
        super.init()
        
        parseLoginHelper = ParseLoginHelper(callback: { [unowned self] (user, error) -> Void in
            //initialize the ParseLoginHelper with a callback
            if let error = error {
                ErrorHandling.defaultErrorHandler(error)
            }
            //if we received a user, we know that our login was successful. In this case we load the Main storyboard and create the TabBarController. This is the line where we use the Storyboard ID that we've set up earlier.
            else if let user = user {
                //if login was successful, display the TabBarController
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let tabBarController = storyboard.instantiateViewControllerWithIdentifier("TabBarController") as! UIViewController
                self.window?.rootViewController!.presentViewController(tabBarController, animated: true, completion: nil)
            }
        })
    }

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        //setup the Parse SDK
        Parse.setApplicationId("h7iHPYWtRgs73fWbIPrSEJheN3rbK1Sz9SPZ6mJ8", clientKey: "y4E9dm42IS34oUUuRUCTqqLw4omfMio8gmcew6TL")

//        PFUser.logInWithUsername("test", password: "test")
//        if let user = PFUser.currentUser() {
//            print("Log in successful")
//        }
//        else {
//            print("No logged in user")
//        }

        //Allows public read access - any user can see all objects created with this default ACL
        //Only provides write access to the user that created the object
        let acl = PFACL()
        acl.setPublicReadAccess(true)
        PFACL.setDefaultACL(acl, withAccessForCurrentUser: true)
        
        //init Facebook
        PFFacebookUtils.initializeFacebookWithApplicationLaunchOptions(launchOptions)
        
//        //check if we have logged in user
//        let user = PFUser.currentUser()
//        
//        let startViewController: UIViewController
//        
//        if user != nil {
//            //if we have a user, set the TabBarController to be the initial view controller
//            let storyboard = UIStoryboard(name: "Main", bundle: nil)
//            startViewController = storyboard.instantiateViewControllerWithIdentifier("TabBarController") as! UITabBarController
//        }
//        else {
//            //otherwise set the loginViewController to be the first
//            let loginViewController = PFLogInViewController()
//            loginViewController.fields = .UsernameAndPassword | .LogInButton | .SignUpButton | .PasswordForgotten | .Facebook
//            loginViewController.delegate = parseLoginHelper
//            loginViewController.signUpController?.delegate = parseLoginHelper
//            
//            startViewController = loginViewController
//        }
//        
//        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
//        self.window?.rootViewController = startViewController
//        self.window?.makeKeyAndVisible()
        
        loginSetup()
        
        //return true
        return FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    func loginSetup() {
        //check if we have logged in user
        let user = PFUser.currentUser()
        
        let startViewController: UIViewController
        
        if user != nil {
            //if we have a user, set the TabBarController to be the initial view controller
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            startViewController = storyboard.instantiateViewControllerWithIdentifier("TabBarController") as! UITabBarController
        }
        else {
            //otherwise set the loginViewController to be the first
            let loginViewController = PFLogInViewController()
            loginViewController.fields = .UsernameAndPassword | .LogInButton | .SignUpButton | .PasswordForgotten | .Facebook
            loginViewController.delegate = parseLoginHelper
            loginViewController.signUpController?.delegate = parseLoginHelper
            
            startViewController = loginViewController
        }
        
        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
        self.window?.rootViewController = startViewController
        self.window?.makeKeyAndVisible()
    }

    func applicationWillResignActive(application: UIApplication) {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationWillTerminate(application: UIApplication) {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    //MARK: Facebook Integration
    func applicationDidBecomeActive(application: UIApplication) {
        FBSDKAppEvents.activateApp()
    }
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject?) -> Bool {
        return FBSDKApplicationDelegate.sharedInstance().application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation)
    }
}

