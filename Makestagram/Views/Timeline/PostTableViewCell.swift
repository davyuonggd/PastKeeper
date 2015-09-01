//
//  PostTableViewCell.swift
//  Makestagram
//
//  Created by DAVY UONG on 8/6/15.
//  Copyright (c) 2015 Make School. All rights reserved.
//

import UIKit
import Bond
import Parse

class PostTableViewCell: UITableViewCell {

    @IBOutlet weak var postImageView: UIImageView!
    @IBOutlet weak var likesIconImageView: UIImageView!
    @IBOutlet weak var likesLabel: UILabel!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var moreButton: UIButton!
    
    @IBAction func likeButtonTapped(sender: AnyObject) {
        post?.toggleLikePost(PFUser.currentUser()!)
    }
    
    @IBAction func moreButtonTapped(sender: AnyObject) {
    }
    
    
    var post: Post? {
        didSet {
            //free memory of image stored with post that is no longer displayed
            //The oldValue variable is available automatically in the didSet property observer. It provides us with a way to access the previous value of a property. We check if an oldValue exists and if that oldValue is different from the new post. If that's the case, we know that we need to do some cleanup
            if let oldValue = oldValue where oldValue != post {
                //In most cases where you create a binding, you should also have code that destroys that binding when it is no longer needed. In case of the PostTableViewCell we don't need the binding anymore if the cell is displaying a new post. By calling unbindAll on the likeBond, we unsubscribe from future updates of the old post. We do the same for postImageView.designatedBond - that's the bond that updates the postImageView when the image of the current post is loaded successfully. It is called designatedBond because it exists by default, without that we have to explicitly create it (like we had to with the likeBond). The Bond framework adds designatedBonds to most UI components such as UIImageView and UITextField
                likeBond.unbindAll()
                postImageView.designatedBond.unbindAll()
                //After we have unbound from the old post, we check if the image of the old post has any bindings left. If oldValue.image.bonds.count is 0, we know that no one is binding to the image of the old post anymore. This means we can free up the memory by setting the image.value to nil.
                if (oldValue.image.bonds.count == 0) {
                    oldValue.image.value = nil
                }
            }
            
            if let post = post {
                //bind the image of the post to the postImage view
                post.image ->> postImageView
                
                //bind the likeBond that we definded earlier, to update likesLabel and likeButton when likes change
                post.likes ->> likeBond
            }
        }
    }
    
    var likeBond: Bond<[PFUser]?>!
    
//    func stringFromUserList(userList: [PFUser]) -> String {
//        let usernameList = userList.map({ (user) -> String in
//            return user.username!
//        })
//        let commaSeparatedUserList = ", ".join(usernameList)
//        return commaSeparatedUserList
//    }
    
    func stringFromUserlist(userList: [PFUser]) -> String {
        let usernameList = userList.map { user in user.username! }
        let commaSeperatedUserList = ", ".join(usernameList)
        
        return commaSeperatedUserList
    }
    
    //MARK: Initialization
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        //We create a new Bond. That Bond has exactly the same type ([PFUser]?) as the likeBond property that we declared. The Bond takes a trailing closure when it is initialized. That closure contains the code that will run whenever the Bond receives a new value. The Bond receives the list of users that have liked a post in the likeList parameter. There's something new hidden in this line:[unowned self]. The list in square brackets is called a capture list. We need the capture list to avoid retain cycles. Since PostTableViewCell is creating and storing this Bond, it has a strong reference to it. Because we are accessing self from within the Bond's closure, the Bond would also have a strong reference to the PostTableViewCell. This way we would have retain cycle in which two objects reference each other strongly.
        likeBond = Bond<[PFUser]?>() { [unowned self] likeList in
            //this code runs as soon as the value of likes on a Post changes. First, we check whether we have received a value for likeList or if we have received nil
            if let likeList = likeList {
                self.likesLabel.text = self.stringFromUserlist(likeList)
                self.likeButton.selected = contains(likeList, PFUser.currentUser()!)
                self.likesIconImageView.hidden = (likeList.count == 0)
            }
            else {
                //if there is no list of users that like this post, reset everything
                self.likesLabel.text = ""
                self.likeButton.selected = false
                self.likesIconImageView.hidden = true
            }
        }
    }
}

