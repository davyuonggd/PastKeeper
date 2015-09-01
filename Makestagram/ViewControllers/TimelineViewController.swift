//
//  TimelineViewController.swift
//  Makestagram
//
//  Created by DAVY UONG on 8/5/15.
//  Copyright (c) 2015 Make School. All rights reserved.
//

/*
Which steps are involved in writing Data to Parse? In most cases it is a three step process. Here's the simplest example from the Parse Quickstart guide:

let testObject = PFObject(className: "TestObject")
testObject["foo"] = "bar"
testObject.saveInBackgroundWithBlock { (success: Bool, error: NSError?) -> Void in
    println("Object has been saved.")
}

The three steps in this code snippet are:
1. Creating a PFObject with a class name that matches on of our Parse classes (in our app this could be "Post", "User", etc.)
2. Set a value for a certain property of that instance using a subscript (the square brackets after the variable name)
3. Call one of the available save... methods on the instance
*/

import UIKit
import Parse
import ConvenienceKit

class TimelineViewController: UIViewController, UITabBarControllerDelegate, TimelineComponentTarget {
    
    @IBOutlet weak var tableView: UITableView!
    
    var photoTakingHelper: PhotoTakingHelper?
    //var posts: [Post] = []
    
    // MARK: - TimelineComponentTarget protocol's
    //Note that you need to provide two different types in the angled brackets: the type of object you are displaying (Post) and the class that will be the target of the TimelineComponent (that's the TimelineViewController in our case).
    var timelineComponent: TimelineComponent<Post, TimelineViewController>!
    let defaultRange = 0...4
    let additionalRangeSize = 5

    @IBAction func logout(sender: AnyObject) {
        let alertController = UIAlertController(title: "Logout?", message: nil, preferredStyle: .ActionSheet)
        let noAction = UIAlertAction(title: "No", style: UIAlertActionStyle.Cancel, handler: nil)
        let yesAction = UIAlertAction(title: "Yes", style: UIAlertActionStyle.Default) { (action: UIAlertAction!) -> Void in
            PFUser.logOut()
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            appDelegate.loginSetup()
        }
        alertController.addAction(yesAction)
        alertController.addAction(noAction)
    
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    func loadInRange(range: Range<Int>, completionBlock: ([Post]?) -> Void) {
        //In the completion block we receive all posts that meet our requirements. The Parse framework hands us an array of type [AnyObject]?. However, we would like to store the posts in an array of type [Post]. In this step we check if it is possible to cast the result into a [Post]; if that's not possible (e.g., because the result is nil) we store an empty array ([]) in self.posts. The ?? operator is called the nil coalescing operator in Swift. If the statement before this operator returns nil, the return value will be replaced with the value after the operator.
        ParseHelper.timelineRequestforCurrentUser(range, completionBlock: { (results: [AnyObject]?, error: NSError?) -> Void in
            if let error = error {
                ErrorHandling.defaultErrorHandler(error)
            }
            let posts = results as? [Post] ?? []
            //We pass the posts that have been loaded back to the TimelineComponent by calling the completionBlock
            completionBlock(posts)
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //The TimelineComponent only takes one argument when it's being initialized: the target. The target is the object to which the TimelineComponent shall add its functionality. In our case that's the TimelineViewController, so we pass self to the initializer.
        timelineComponent = TimelineComponent(target: self)

        // Do any additional setup after loading the view.
        self.tabBarController?.delegate = self
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        //The TimelineComponent wants us to call the loadInitialIfRequired() method when that happens. We can implement that method call inside of the viewDidAppear method, which is called as soon as the TableView becomes visible.
        timelineComponent.loadInitialIfRequired()
    }
    
    func takePhoto() {
        // instantiate photo taking class, provide callback for when photo  is selected
        photoTakingHelper = PhotoTakingHelper(viewController: self.tabBarController!) { (image: UIImage?) in
            let post = Post()
            post.image.value = image
            post.uploadPost()
        }
    }
    //MARK: - Tab Bar Delegate
    func tabBarController(tabBarController: UITabBarController, shouldSelectViewController viewController: UIViewController) -> Bool {
        if (viewController is PhotoViewController) {
            takePhoto()
            return false
        } else {
            return true
        }
    }
}

extension TimelineViewController: UITableViewDataSource, UITableViewDelegate {
    //MARK: - TableView Delegate
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        //We directly call the timelineComponent and inform it that a cell has been displayed
        //timelineComponent.targetWillDisplayEntry(indexPath.row)
        timelineComponent.targetWillDisplayEntry(indexPath.section)
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //return posts.count
        //return timelineComponent.content.count
        return 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("PostCell") as! PostTableViewCell
        //let post = posts[indexPath.row]
        //let post = timelineComponent.content[indexPath.row]
        let post = timelineComponent.content[indexPath.section]
        post.downloadImage()
        post.fetchLikes()
        cell.post = post
        return cell
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.timelineComponent.content.count
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerCell = tableView.dequeueReusableCellWithIdentifier("PostHeader") as! PostSectionHeaderView
        let post = self.timelineComponent.content[section]
        headerCell.post = post
        return headerCell
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
}