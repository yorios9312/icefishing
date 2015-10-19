//
//  ProfileViewController.swift
//  Profile
//
//  Created by Annie Cheng on 3/17/15.
//  Copyright (c) 2015 Annie Cheng. All rights reserved.
//

import UIKit

class ProfileViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    var user: User = User.currentUser
    var isFollowing = false
    
    // Post History Calendar
    var calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
    var startDate = NSDate(dateString:"2015-01-26")
    var postedDates: [NSDate] = []
	var postedDays: [String] = []
    var padding: CGFloat = 5
	var dateFormatter = NSDateFormatter()
    
    // Outlets
    @IBOutlet weak var profilePictureView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var userHandleLabel: UILabel!
    @IBOutlet weak var followButton: UIButton!
	@IBOutlet weak var followersButton: UIButton!
	@IBOutlet weak var followingButton: UIButton!
    @IBOutlet weak var divider: UIView!
    @IBOutlet weak var separator: UIView!
	@IBOutlet weak var collectionView: UICollectionView!
	
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // TODO: Backend route is currently wrong
		dateFormatter.dateFormat = "dd-MM-yyyy"
		API.sharedAPI.fetchPosts(self.user.id) { post in
			self.postedDates = post.map { $0.date! }
			self.postedDays = self.postedDates.map { self.dateFormatter.stringFromDate($0) }
			self.collectionView.reloadData()
		}
		
        // Profile Info
		title = "Profile"
		beginIceFishing()
		
        nameLabel.text = user.name
        userHandleLabel.text = "@\(user.username)"
        user.loadImage {
            self.profilePictureView.image = $0
        }
        profilePictureView.layer.borderWidth = 1.5
        profilePictureView.layer.borderColor = UIColor.whiteColor().CGColor
        profilePictureView.layer.cornerRadius = profilePictureView.frame.size.height/2
        profilePictureView.clipsToBounds = true
		
		followButton.setTitle(isFollowing ? "FOLLOWING" : "FOLLOW", forState: .Normal)
		
        if User.currentUser.username == user.username {
            followButton.hidden = true
		}
		
		followingButton.setTitle("\(user.followingCount) Following", forState: .Normal)
		followersButton.setTitle("\(user.followersCount) Followers", forState: .Normal)
		
		// Post History Calendar
        separator.backgroundColor = UIColor.iceDarkRed
        
        let layout = collectionView.collectionViewLayout as! HipStickyHeaderFlowLayout
        layout.sectionInset = UIEdgeInsets(top: 0, left: padding*6, bottom: padding*2, right: 0)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
		
        collectionView.registerClass(HipCalendarCollectionReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "Header")
        collectionView.registerClass(HipCalendarDayCollectionViewCell.self, forCellWithReuseIdentifier: "DayCell")
        collectionView.backgroundColor = UIColor.clearColor()
		collectionView.scrollsToTop = false
		
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "Close-Icon"), style: .Plain, target: self, action: "popToRoot")
		
		let views: [String : AnyObject] = ["pic" : profilePictureView, "topGuide": self.topLayoutGuide]
		self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[topGuide]-[pic]", options: NSLayoutFormatOptions.DirectionLeadingToTrailing, metrics: nil, views: views))
    }

    // Return to profile view
    func popToRoot() {
        navigationController?.popToRootViewControllerAnimated(true)
    }
    
    // Return to previous view
    func popToPrevious() {
        navigationController?.popViewControllerAnimated(true)
    }
    
    // <------------------------FOLLOW BUTTONS------------------------>
	
	// TODO: Currently no checks against whether already followed
    @IBAction func followButtonPressed(sender: UIButton) {
        if !isFollowing {
            isFollowing = true
            followButton.setTitle("FOLLOWING", forState: .Normal)
            User.currentUser.followingCount++
            API.sharedAPI.updateFollowings(user.id, unfollow: false) { bool in
                print(bool)
            }
        } else {
            isFollowing = false
            followButton.setTitle("FOLLOW", forState: .Normal)
            User.currentUser.followingCount--
            API.sharedAPI.updateFollowings(user.id, unfollow: true) { bool in
                print(bool)
            }
        }
    }
    
    @IBAction func followersButtonPressed(sender: UIButton) {
		displayUsers(.Followers)
    }

    @IBAction func followingButtonPressed(sender: UIButton) {
        displayUsers(.Following)
    }
	
	private func displayUsers(displayType: DisplayType) {
		let followersVC = UsersViewController(nibName: "UsersViewController", bundle: nil)
		followersVC.displayType = displayType
		followersVC.user = user
		followersVC.title = String(displayType)
		navigationController?.pushViewController(followersVC, animated: true)
	}
	
    // <------------------------POST HISTORY------------------------>
    
    // When post history label clicked
    @IBAction func scrollToTop(sender: UIButton) {
        collectionView.setContentOffset(CGPointZero, animated: true)
    }
    
    // Helper Methods
    private func dateForIndexPath(indexPath: NSIndexPath) -> NSDate {
        let date = NSDate().dateByAddingMonths(-indexPath.section).lastDayOfMonth()
        let components : NSDateComponents = date.components()
        components.day = date.numDaysInMonth() - indexPath.item
        return NSDate.dateFromComponents(components)
    }
	
	// MARK: - UICollectionViewDataSource
	
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let date = dateForIndexPath(indexPath)
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("DayCell", forIndexPath: indexPath) as! HipCalendarDayCollectionViewCell
        cell.date = date
        cell.userInteractionEnabled = false
		
        if postedDays.contains(dateFormatter.stringFromDate(cell.date)) {
            cell.dayInnerCircleView.backgroundColor = UIColor.iceDarkRed
			cell.userInteractionEnabled = true
        }
        
        return cell
    }
	
    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        
        if kind == UICollectionElementKindSectionHeader {
            let firstDayOfMonth = dateForIndexPath(indexPath).firstDayOfMonth()
            let header = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "Header", forIndexPath: indexPath) as! HipCalendarCollectionReusableView
            header.firstDayOfMonth = firstDayOfMonth
            
            return header
        }
        
        return UICollectionReusableView()
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return startDate.numberOfMonths(NSDate())
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let firstDayOfMonth = NSDate().firstDayOfMonth().dateByAddingMonths(-section)
        var numberOfDays = firstDayOfMonth.numDaysInMonth()
        
        if firstDayOfMonth.month() == startDate.month() && firstDayOfMonth.year() == startDate.year() {
            numberOfDays = startDate.numDaysUntilEndDate(firstDayOfMonth.lastDayOfMonth())
        }
        
        return numberOfDays
    }
    
    // MARK: - UICollectionViewDelegate
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let date = dateForIndexPath(indexPath)
        let index = postedDates.indexOf(date) as Int?
        
        // Push to TableView with posted songs and dates
        let postHistoryVC = PostHistoryTableViewController(nibName: "PostHistoryTableViewController", bundle: nil)
        postHistoryVC.postedDates = postedDates
        postHistoryVC.selectedDate = date
        postHistoryVC.index = index!
        navigationController?.pushViewController(postHistoryVC, animated: true)
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSizeMake(collectionView.frame.width - padding * 2, 30)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
		let cols: CGFloat = 6
		let dayWidth = collectionView.frame.width / cols
		let dayHeight = dayWidth
        return CGSize(width: dayWidth, height: dayHeight)
    }
    
}

