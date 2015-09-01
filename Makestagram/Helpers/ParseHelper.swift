//
//  ParseHelper.swift
//  Makestagram
//
//  Created by DAVY UONG on 8/6/15.
//  Copyright (c) 2015 Make School. All rights reserved.
//

import Foundation
import Parse

class ParseHelper {
    //Following Relation
    static let ParseFollowClass = "Follow"
    static let ParseFollowFromUser = "fromUser"
    static let ParseFollowToUser = "toUser"
    
    //Like Relation
    static let ParseLikeClass = "Like"
    static let ParseLikeToPost = "toPost"
    static let ParseLikeFromUser = "fromUser"
    
    //Post Relation
    static let ParsePostUser = "user"
    static let ParsePostCreatedAt = "createdAt"
    
    //Flagged Content Relation
    static let ParseFlaggedContentClass = "FlaggedContent"
    static let ParseFlaggedContentFromUser = "fromUser"
    static let ParseFlaggedContentToPost = "toPost"
    
    //User Relation
    static let ParseUserUsername = "username"
    
    //That Range argument will define which portions of the timeline will be loaded. Ranges in Swift are defined like this: 5..10.
    static func timelineRequestforCurrentUser(range: Range<Int>, completionBlock: PFArrayResultBlock) {
        //query for all Follows
        let followingQuery = PFQuery(className: ParseFollowClass)
        //Follows that the current user follow
        followingQuery.whereKey(ParseLikeFromUser, equalTo:PFUser.currentUser()!)
        
        //query that returns all Posts
        let postsFromFollowedUsers = Post.query() //same as: let postsFromFollowUser = PFQuery(classname:"Post")
        //Posts that created by users current user follow (toUser) in the follwoingQuerry
        postsFromFollowedUsers!.whereKey(ParsePostUser, matchesKey: ParseFollowToUser, inQuery: followingQuery)
        
        //query that returns all Posts
        let postsFromThisUser = Post.query()
        //Posts that current user posted
        postsFromThisUser!.whereKey(ParsePostUser, equalTo: PFUser.currentUser()!)
        
        //We create a combined querie, using the orQueryWithSubqueries method.
        let query = PFQuery.orQueryWithSubqueries([postsFromFollowedUsers!, postsFromThisUser!])
        
        //By using includeKey method we tell Parse to resolve the pointer to the user column of each post, and download all the info about the user along with the post
        query.includeKey(ParsePostUser)
        
        //sort by
        query.orderByDescending(ParsePostCreatedAt)
        //PFQuery provides a skip property. That allows us - as the name lets us suspect - to define how many elements that match our query shall be skipped.
        query.skip = range.startIndex
        //The limit property defines how many elements we want to load.
        query.limit = range.endIndex - range.startIndex
        
        //Once all requirements for the query added, start fetching the data
        query.findObjectsInBackgroundWithBlock(completionBlock) //this completionBlock will be execute after the fetching done. In the completion block we receive all posts that meet our requirements. The Parse framework hands us an array of type [AnyObject]?.
    }
    
    static func timelineRequestforCurrentUser(completionBlock: PFArrayResultBlock) {
        //query for all Follows
        let followingQuery = PFQuery(className: ParseFollowClass)
        //Follows that the current user follow
        followingQuery.whereKey(ParseLikeFromUser, equalTo:PFUser.currentUser()!)
        
        //query that returns all Posts
        let postsFromFollowedUsers = Post.query() //same as: let postsFromFollowUser = PFQuery(classname:"Post")
        //Posts that created by users current user follow (toUser) in the follwoingQuerry
        postsFromFollowedUsers!.whereKey(ParsePostUser, matchesKey: ParseFollowToUser, inQuery: followingQuery)
        
        //query that returns all Posts
        let postsFromThisUser = Post.query()
        //Posts that current user posted
        postsFromThisUser!.whereKey(ParsePostUser, equalTo: PFUser.currentUser()!)
        
        //We create a combined querie, using the orQueryWithSubqueries method.
        let query = PFQuery.orQueryWithSubqueries([postsFromFollowedUsers!, postsFromThisUser!])
        
        //By using includeKey method we tell Parse to resolve the pointer to the user column of each post, and download all the info about the user along with the post
        query.includeKey(ParsePostUser)
        
        //sort by
        query.orderByDescending(ParsePostCreatedAt)
        
        //Once all requirements for the query added, start fetching the data
        query.findObjectsInBackgroundWithBlock(completionBlock) //this completionBlock will be execute after the fetching done. In the completion block we receive all posts that meet our requirements. The Parse framework hands us an array of type [AnyObject]?. 
    }
    
    // MARK: Likes
    
    static func likePost(user: PFUser, post: Post) {
        //create a Like object connected to the Parse Like class
        let likeObject = PFObject(className: ParseLikeClass)
        //set user of the Like object with subscript
        likeObject[ParseLikeFromUser] = user
        //set post iwth subscript
        likeObject[ParseLikeToPost] = post
        //save the Like
        likeObject.saveInBackgroundWithBlock(ErrorHandling.errorHandlingCallback)
    }
    
    static func unlikePost(user: PFUser, post: Post) {
        //query for all Likes
        let query = PFQuery(className: ParseLikeClass)
        //Likes for specific user
        query.whereKey(ParseLikeFromUser, equalTo: user)
        //Likes for specific post
        query.whereKey(ParseLikeToPost, equalTo: post)
        //fetch the Like objects
        query.findObjectsInBackgroundWithBlock { (results: [AnyObject]?, error: NSError?) -> Void in
            if let error = error {
                ErrorHandling.defaultErrorHandler(error)
            }
            if let results = results as? [PFObject] {
                for like in results {
                    like.deleteInBackgroundWithBlock(ErrorHandling.errorHandlingCallback)
                }
            }
        }
    }
    
    static func likesForPost(post: Post, completionBlock: PFArrayResultBlock) {
        //query for all Likes
        let query = PFQuery(className: ParseLikeClass)
        //Likes from specific post
        query.whereKey(ParseLikeToPost, equalTo: post)
        //with the info of all the user that like this post along with their Likes
        query.includeKey(ParseLikeFromUser)
        //fetch the data
        query.findObjectsInBackgroundWithBlock(completionBlock)
    }
    
    //MARK: Following
    static func getFollowingUsersForUser(user: PFUser, completionBlock: PFArrayResultBlock) {
        let query = PFQuery(className: ParseFollowClass)
        query.whereKey(ParseFollowFromUser, equalTo: user)
        query.findObjectsInBackgroundWithBlock(completionBlock)
    }
    
    static func addFollowRelationshipFromUser(user: PFUser, toUser: PFUser) {
        let followObject = PFObject(className: ParseFollowClass)
        followObject[ParseFollowFromUser] = user
        followObject[ParseFollowToUser] = toUser
        followObject.saveInBackgroundWithBlock(ErrorHandling.errorHandlingCallback)
    }
    
    static func removeFollowRelationshipFromUser(user: PFUser, toUser: PFUser) {
        let query = PFQuery(className: ParseFollowClass)
        query.whereKey(ParseFollowFromUser, equalTo:user)
        query.whereKey(ParseFollowToUser, equalTo: toUser)
        
        query.findObjectsInBackgroundWithBlock {
            (results: [AnyObject]?, error: NSError?) -> Void in
            if let error = error {
                ErrorHandling.defaultErrorHandler(error)
            }
            
            let results = results as? [PFObject] ?? []
            
            for follow in results {
                follow.deleteInBackgroundWithBlock(ErrorHandling.errorHandlingCallback)
            }
        }
    }
    
    //MARK: Users
    //Fetch all users, except the one that't currently signed in
    //Limitt he amount of users returned to 20
    static func allUsers(completionBlock: PFArrayResultBlock) -> PFQuery {
        let query = PFUser.query()!
        //exclude the curent user
        query.whereKey(ParseUserUsername, notEqualTo: PFUser.currentUser()!.username!)
        query.limit = 20
        query.findObjectsInBackgroundWithBlock(completionBlock)
        return query
    }
    
    //Fetch users whose usernames match the provided search term
    
    static func searchUsers(searchText: String, completionBlock: PFArrayResultBlock) -> PFQuery {
        let query = PFUser.query()!
        query.whereKey(ParseUserUsername, matchesRegex: searchText, modifiers: "i") //- `i` - Case insensitive search
        query.whereKey(ParseUserUsername, notEqualTo: PFUser.currentUser()!.username!)
        query.orderByAscending(ParseUserUsername)
        query.limit = 20
        query.findObjectsInBackgroundWithBlock(completionBlock)
        return query
    }
}

extension PFObject: Equatable {
    
}

public func ==(lhs: PFObject, rhs: PFObject) -> Bool {
    //consider any two Parse objects equal if they have the same objectId.
    return lhs.objectId == rhs.objectId
}