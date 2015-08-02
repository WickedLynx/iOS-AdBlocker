//
//  ViewController.swift
//  AdBlocker
//
//  Created by Harshad Dange on 01/08/2015.
//  Copyright © 2015 Laughing Buddha Software. All rights reserved.
//

struct BlockedDomain {
    let domain: String
    
    init(domain: String) {
        self.domain = domain
    }
    
    func dictionaryRepresentation() -> [String : NSDictionary] {
        let actionDictionary = ["type" : "block"]
        let triggerDictionary = ["url-filter" : domain]
        return ["action" : actionDictionary, "trigger" : triggerDictionary]
    }
}

import UIKit
import SafariServices

class ViewController: UIViewController {
    
    private weak var spinner: UIActivityIndicatorView?
    private weak var debugLabel: UILabel?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let button = UIButton(type: .System)
        button.setTitle("Reload", forState: .Normal)
        button.addTarget(self, action: "tapReload", forControlEvents: .TouchUpInside)
        
        let spinner = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        spinner.hidesWhenStopped = true
        
        for viewToAdd in [spinner, button] {
            view.addSubview(viewToAdd)
            viewToAdd.translatesAutoresizingMaskIntoConstraints = false
            view.addConstraint(NSLayoutConstraint(item: viewToAdd, attribute: .CenterX, relatedBy: .Equal, toItem: view, attribute: .CenterX, multiplier: 1.0, constant: 0.0))
            view.addConstraint(NSLayoutConstraint(item: viewToAdd, attribute: .CenterY, relatedBy: .Equal, toItem: view, attribute: .CenterY, multiplier: 1.0, constant: 0.0))
        }
        
        let label = UILabel(frame: CGRectZero)
        label.textAlignment = .Center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(label)
        view.addConstraint(NSLayoutConstraint(item: label, attribute: .CenterX, relatedBy: .Equal, toItem: view, attribute: .CenterX, multiplier: 1.0, constant: 0.0))
        view.addConstraint(NSLayoutConstraint(item: label, attribute: .Bottom, relatedBy: .Equal, toItem: view, attribute: .Bottom, multiplier: 1.0, constant: 0.0))
        
        label.text = "Tap reload to reload >.>"
        
        self.spinner = spinner
        self.debugLabel = label
    }
    
    func tapReload() {
        spinner?.startAnimating()
        
        debugLabel?.text = "Fetching baddies..."
        
        let url: NSURL! = NSURL(string: "http://hosts-file.net/ad_servers.txt")!
        let request = NSURLRequest(URL: url)
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { [weak self](data, response, error) -> Void in
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                if let cData = data {
                    self?.extractDomainsAndReload(cData)
                } else {
                    let alert = UIAlertController(title: "Error fetching baddies", message: error?.localizedDescription, preferredStyle: .Alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
                    self?.presentViewController(alert, animated: true, completion: nil)
                    self?.spinner?.stopAnimating()
                    self?.debugLabel?.text = "Tap reload to reload >.>"
                }
            })
            
            print("URL loading error: \(error)")
        }
        task.resume()
    }
    
    private func extractDomainsAndReload(data: NSData) {
        debugLabel?.text = "Parsing..."
        do {
            let fileContents = NSString(data: data, encoding: NSUTF8StringEncoding)
            var domainsToBlock: [[String : NSDictionary]] = []
            let localhost = "127.0.0.1"
            fileContents!.enumerateLinesUsingBlock({ (line, stop) -> Void in
                if line.hasPrefix(localhost) {
                    // This is a domain to block
                    if let domainToBlock = line.componentsSeparatedByString(localhost).last {
                        let trimmedDomain = domainToBlock.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                        domainsToBlock.append(BlockedDomain(domain: trimmedDomain).dictionaryRepresentation())
                    }
                }
            })
            let json = try NSJSONSerialization.dataWithJSONObject(domainsToBlock, options: NSJSONWritingOptions.PrettyPrinted)
            
            let containerURL = NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier("group.adblocker")?.URLByAppendingPathComponent("blockedDomains.json")
            //            let previousVersion = try NSString(contentsOfFile: containerURL!.path!, encoding: NSUTF8StringEncoding)
            //            print(previousVersion)
            json.writeToURL(containerURL!, atomically: true)
            
            self.debugLabel?.text = "Reloading Safari"
            
            SFContentBlockerManager.reloadContentBlockerWithIdentifier("com.lbs.AdBlocker.AdBlocker-ext", completionHandler: {[weak self] (error) -> Void in
                self?.spinner?.stopAnimating()
                self?.debugLabel?.text = "Done. Try Safari now!"
                if let cError = error {
                    let alert = UIAlertController(title: "Error Reloading Safari", message: cError.localizedDescription, preferredStyle: .Alert)
                    let action = UIAlertAction(title: "OK", style: .Default, handler: nil)
                    alert.addAction(action)
                    self?.presentViewController(alert, animated: true, completion: nil)
                }
                print("Error: \(error?.localizedDescription)")
                
                UIApplication.sharedApplication().openURL(NSURL(string: "http://macrumors.com")!)
            })
            
        }
        catch {
            print(error)
        }
    }


}

