//
//  PostSectionHeaderView.swift
//  Makestagram
//
//  Created by DAVY UONG on 8/17/15.
//  Copyright (c) 2015 Make School. All rights reserved.
//

import UIKit

class PostSectionHeaderView: UITableViewCell {

    @IBOutlet weak var postTimeLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    
    var post: Post? {
        didSet {
            usernameLabel.text = post?.user?.username
            //We are reading the createdAt date from the post. This is a property that Parse sets by default on all PFObjects. Then we use an extension provided by the DateTools library: shortTimeAgoSinceDate(_:). This method takes a comparison date. By calling NSDate() we create a date object with the current time. If the post has been created 4 hours ago, this line of code will generate the string "4h". Since createdAt? is an optional, we use the ?? operator to fall back to an empty string, in case the 'createdAt' date should be nil.
            postTimeLabel.text = post?.createdAt?.shortTimeAgoSinceDate(NSDate()) ?? ""
        }
    }
}
