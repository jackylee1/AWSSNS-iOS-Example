//
//  AppDelegate.swift
//  AWSSNSPushNotification_Sample
//
//  Created by Steve on 2016/7/7.
//  Copyright © 2016年 Steve. All rights reserved.
//

import UIKit
import AWSMobileAnalytics
import AWSSNS

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    let SNSPlatformApplicationArn = "您的ApplicationArn"
    let topicArnString = "您的TopicArn"
    var endpointArn = ""
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        // Sets up Mobile Push Notification
        let readAction = UIMutableUserNotificationAction()
        readAction.identifier = "READ_IDENTIFIER"
        readAction.title = "Read"
        readAction.activationMode = UIUserNotificationActivationMode.Foreground
        readAction.destructive = false
        readAction.authenticationRequired = true
        
        let deleteAction = UIMutableUserNotificationAction()
        deleteAction.identifier = "DELETE_IDENTIFIER"
        deleteAction.title = "Delete"
        deleteAction.activationMode = UIUserNotificationActivationMode.Foreground
        deleteAction.destructive = true
        deleteAction.authenticationRequired = true
        
        let ignoreAction = UIMutableUserNotificationAction()
        ignoreAction.identifier = "IGNORE_IDENTIFIER"
        ignoreAction.title = "Ignore"
        ignoreAction.activationMode = UIUserNotificationActivationMode.Foreground
        ignoreAction.destructive = false
        ignoreAction.authenticationRequired = false
        
        let messageCategory = UIMutableUserNotificationCategory()
        messageCategory.identifier = "MESSAGE_CATEGORY"
        messageCategory.setActions([readAction, deleteAction], forContext: UIUserNotificationActionContext.Minimal)
        messageCategory.setActions([readAction, deleteAction, ignoreAction], forContext: UIUserNotificationActionContext.Default)
        
        let notificationSettings = UIUserNotificationSettings(forTypes: [UIUserNotificationType.Badge, UIUserNotificationType.Sound, UIUserNotificationType.Alert], categories: (NSSet(array: [messageCategory])) as? Set<UIUserNotificationCategory>)
        
        UIApplication.sharedApplication().registerForRemoteNotifications()
        UIApplication.sharedApplication().registerUserNotificationSettings(notificationSettings)
        return true
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
    
    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        print("DEVICE TOKEN = \(deviceToken)")
        createEndpointAndSubscription(deviceToken)
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        print(error)
    }
    
    func application(application: UIApplication, handleActionWithIdentifier identifier: String?, forRemoteNotification userInfo: [NSObject : AnyObject], completionHandler: () -> Void) {
        
        let mobileAnalytics = AWSMobileAnalytics.defaultMobileAnalytics()
        let eventClient = mobileAnalytics.eventClient
        let pushNotificationEvent = eventClient.createEventWithEventType("PushNotificationEvent")
        
        var action = "Undefined"
        if identifier == "READ_IDENTIFIER" {
            action = "Read"
            print("User selected 'Read'")
        } else if identifier == "DELETE_IDENTIFIER" {
            action = "Deleted"
            print("User selected 'Delete'")
        } else {
            action = "Undefined"
        }
        
        pushNotificationEvent.addAttribute(action, forKey: "Action")
        eventClient.recordEvent(pushNotificationEvent)
        completionHandler()
    }
    
    func createEndpointAndSubscription(deviceToken:NSData) {
        let deviceTokenString = "\(deviceToken)"
            .stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString:"<>"))
            .stringByReplacingOccurrencesOfString(" ", withString: "")
        print("deviceTokenString: \(deviceTokenString)")
        NSUserDefaults.standardUserDefaults().setObject(deviceTokenString, forKey: "deviceToken")
        
        let sns = AWSSNS.defaultSNS()
        // AWS SNS : Create a platform endpoint at Application.
        let request = AWSSNSCreatePlatformEndpointInput()
        request.token = deviceTokenString
        request.platformApplicationArn = self.SNSPlatformApplicationArn
        sns.createPlatformEndpoint(request).continueWithExecutor(AWSExecutor.mainThreadExecutor(), withBlock: { (task: AWSTask!) -> AnyObject! in
            if task.error != nil {
                print("Error: \(task.error)")
            } else {
                let createEndpointResponse = task.result as! AWSSNSCreateEndpointResponse
                self.endpointArn = createEndpointResponse.endpointArn!
                print("endpointArn: \(createEndpointResponse.endpointArn)")
                NSUserDefaults.standardUserDefaults().setObject(createEndpointResponse.endpointArn, forKey: "endpointArn")
                
                // AWS SNS : Create a subscription at Topic.
                let input = AWSSNSSubscribeInput()
                input.topicArn = self.topicArnString
                input.endpoint = self.endpointArn
                input.protocols = "application"
                sns.subscribe(input).continueWithExecutor(AWSExecutor.mainThreadExecutor(), withBlock: {(task:AWSTask!) -> AnyObject! in
                    if task.error != nil {
                        print("Error: \(task.error)")
                    } else {
                        let SubscriptionArnResponse = task.result as! AWSSNSSubscribeResponse
                        print("SubscriptionArn: \(SubscriptionArnResponse.subscriptionArn)")
                        NSUserDefaults.standardUserDefaults().setObject(SubscriptionArnResponse.subscriptionArn, forKey: "subscriptionArn")
                    }
                    return nil
                })
            }
            return nil
        })
    }
}

