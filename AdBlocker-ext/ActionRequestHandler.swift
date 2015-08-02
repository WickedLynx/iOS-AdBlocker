//
//  ActionRequestHandler.swift
//  AdBlocker-ext
//
//  Created by Harshad Dange on 01/08/2015.
//  Copyright © 2015 Laughing Buddha Software. All rights reserved.
//

import UIKit
import MobileCoreServices

class ActionRequestHandler: NSObject, NSExtensionRequestHandling {

    func beginRequestWithExtensionContext(context: NSExtensionContext) {
        var attachment = NSItemProvider(contentsOfURL: NSBundle.mainBundle().URLForResource("blockerList", withExtension: "json"))!
        
        let containerURL = NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier("group.adblocker")?.URLByAppendingPathComponent("blockedDomains.json")
        if let path = containerURL?.path {
            if NSFileManager.defaultManager().fileExistsAtPath(path) {
                attachment = NSItemProvider(contentsOfURL: containerURL)!
            }
        }
        
        let item = NSExtensionItem()
        item.attachments = [attachment]
    
        context.completeRequestReturningItems([item], completionHandler: nil);
    }
}
