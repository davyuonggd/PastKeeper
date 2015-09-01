//
//  Post.swift
//  Makestagram
//
//  Created by DAVY UONG on 8/6/15.
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
import Bond
import ConvenienceKit

//To create a custom Parse class you need to inherit from PFObject and implement the PFSubclassing protocol
class Post: PFObject, PFSubclassing {
    
    //we need to provide two pieces of type information: the first is the type of the keys we want to store in the cache, the second is the type of the values
    static var imageCache: NSCacheSwift<String, UIImage>!
    
    //Next, define each property that you want to access on this Parse class. For our Post class that's the user and the imageFile of a post. That will allow you to change the code that accesses properties through strings: post["imageFile"] = imageFile Into code that uses Swift properties: post.imageFile = imageFile
    @NSManaged var imageFile: PFFile?
    @NSManaged var user: PFUser?
    
    //Dynamic is just a wrapper around the actual value that we want to store. That wrapper allows us to listen for changes to the wrapped value. The Dynamic wrapper enables us to use the property together with bindings. You can see the type of the wrapped value in the angled brackets (<UIImage?>).
    var image: Dynamic<UIImage?> = Dynamic(nil)
    
    //var likes: Dynamic<[PFUser]?> = Dynamic(nil) //dynamic optional array of PFUser
    var likes = Dynamic<[PFUser]?>(nil)
    
    var photoUploadTask: UIBackgroundTaskIdentifier?
    
    // MARK: PFSubclassing protocol
    //By implementing the parseClassName you create a connection between the Parse class and your Swift class.
    static func parseClassName() -> String {
        return "Post"
    }
    
    //init and initialize are pure boilerplate code - copy these two into any custom Parse class that you're creating.
    override init() {
        super.init()
    }
    
    override class func initialize() {
        var onceToken: dispatch_once_t = 0;
        dispatch_once(&onceToken) {
            //inform Parse about this subclass
            self.registerSubclass()
            //We create an empty cache. Remember that the other lines in this method are primarily Parse boilerplate code
            Post.imageCache = NSCacheSwift<String, UIImage>()
        }
    }
}

extension Post {
    
    func uploadPost() {
        //Whenever the uploadPost method is called, we grab the photo that shall be uploaded from the image property; turn it into a PFFile and upload it.
        let imageData = UIImageJPEGRepresentation(image.value, 0.8) //convert the image to data
        let imageFile = PFFile(data: imageData) //convert the data to PFFile
        
        //As soon as a post gets uploaded, we create a background task. When a background task gets created, iOS generates a unique ID and returns it. We store that unique id in the photoUploadTask property. The API requires us to provide an expirationHandler in the form of a closure. That closure runs when the extra time that iOS permitted us has expired. In case the additional background time wasn't sufficient, we are required to cancel our task! Within this block you should delete any temporary resources that you created - in the case of our photo upload we don't have any. Additionally you have to call UIApplication.sharedApplication().endBackgroundTask, otherwise your app will be terminated!
        photoUploadTask = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler({ () -> Void in
            UIApplication.sharedApplication().endBackgroundTask(self.photoUploadTask!)
        })
        //Within the completion handler of saveInBackgroundWithBlock we inform iOS that our background task is completed. This block gets called as soon as the image upload is finished. The API for background jobs makes us responsible for calling UIApplication.sharedApplication().endBackgroundTask as soon as our work is completed.ss
        imageFile.saveInBackgroundWithBlock { (success: Bool, error: NSError?) -> Void in
            if let error = error {
                ErrorHandling.defaultErrorHandler(error)
            }
            UIApplication.sharedApplication().endBackgroundTask(self.photoUploadTask!)
            print("\nPost uploaded")
        }
        
        //any uploaded post should be associated with the current user
        user = PFUser.currentUser()
        //Once we have saved the imageFile we assign it to self (which is the Post that's being uploaded). Then we call save() to store the Post.
        self.imageFile = imageFile
        saveInBackgroundWithBlock(ErrorHandling.errorHandlingCallback)
    }
    
    func downloadImage() {
        //We attempt to assign a value to image.value directly from the cache, using self.imageFile.name as key. If this assignment is successful the entire download block will be skipped
        image.value = Post.imageCache[self.imageFile!.name]
        
        // if image is not downloaded yet, get it
        if (image.value == nil) {
            imageFile?.getDataInBackgroundWithBlock { (data: NSData?, error: NSError?) -> Void in
                if let error = error {
                    ErrorHandling.defaultErrorHandler(error)
                }
                if let data = data {
                    let image = UIImage(data: data, scale:1.0)!
                    self.image.value = image
                    //If we didn't have the image cached, we proceed as usual. Then, when the image is downloaded, we add it to the cache.
                    Post.imageCache[self.imageFile!.name] = image
                }
            }
        }
    }
    
//    func downloadImage() {
//        //if image is not downloaded yet, get it
//        if (image.value == nil) {
//            imageFile?.getDataInBackgroundWithBlock({ (data: NSData?, NSError) -> Void in
//                if let data = data {
//                    let image = UIImage(data: data, scale:1.0)!
//                    self.image.value = image
//                }
//            })
//        }
//    }
    
    func fetchLikes() {
        if (likes.value != nil) {
            return
        }
        
        //The filter method that we call on our Array. The filter method takes a closure and returns an array that only contains the objects from the original array that meet the requirement stated in that closure. The closure passed to the filter method gets called for each element in the array, each time passing the current element as the like argument to the closure. Note that you can pick any arbitrary name for the argument that we called like. So why are we filtering the array in the first place? We are removing all likes that belong to users that no longer exist in our Makestagram app (because their account has been deleted). Without this filtering the next statement could crash.
        ParseHelper.likesForPost(self, completionBlock: { (var likes: [AnyObject]?, error: NSError?) -> Void in
            if let error = error {
                ErrorHandling.defaultErrorHandler(error)
            }
            
            likes = likes?.filter({ (like) -> Bool in
                return like[ParseHelper.ParseLikeFromUser] != nil
            })
//            likes = likes?.filter {like in like[ParseHelper.ParseLikeFromUser] != nil }
            
            //The map method behaves similar to the filter method in that it takes a closure that is called for each element in the array and in that it also returns a new array as a result. The difference is that, unlike filter, map does not remove objects but replaces them. In this particular case, we are replacing the likes in the array with the users that are associated with the like. We start with an array of likes and retrieve an array of users. Then we assign the result to our likes.value property.
            self.likes.value = likes?.map({ (like) -> PFUser in
                let like = like as! PFObject
                let fromUser = like[ParseHelper.ParseLikeFromUser] as! PFUser
                return fromUser
            })
//            self.likes.value = likes?.map {like in
//                let like = like as! PFObject
//                let fromUser = like[ParseHelper.ParseLikeFromUser] as! PFUser
//                return fromUser
//            }
        })
    }
    
    func doesUserLikePost(user: PFUser) -> Bool {
        if let likes = likes.value {
            return contains(likes, user)
        }
        else {
            return false
        }
    }
    
    func toggleLikePost(user: PFUser) {
        if (doesUserLikePost(user)) {
            //unlike if liked
            //First by removing the user from the local cache stored in the likes property, then by syncing the change with Parse. We remove the user from the local cache by using the filter method on the array stored in likes.value.
//            likes.value = likes.value?.filter({ (fromUser) -> Bool in
//                return fromUser != user
//            })
            likes.value = likes.value?.filter { $0 != user }
            ParseHelper.unlikePost(user, post: self)
        }
        else {
            //like if not liked
            //add them to the local cache and then synch the change with Parse.
            likes.value?.append(user)
            ParseHelper.likePost(user, post: self)
        }
    }
}
