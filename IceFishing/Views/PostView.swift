//
//  PostView.swift
//  IceFishing
//
//  Created by Alexander Zielenski on 4/12/15.
//  Copyright (c) 2015 Alexander Zielenski and Mark Bryan. All rights reserved.
//

import UIKit
import MediaPlayer

enum ViewType: Int {
    case Feed
    case Search
}

class PostView: UIView, UIGestureRecognizerDelegate {
    private var progressGestureRecognizer: UIPanGestureRecognizer?
    var tapGestureRecognizer: UITapGestureRecognizer?
    @IBOutlet var profileNameLabel: MarqueeLabel?
    @IBOutlet var avatarImageView: FeedImageView?
    @IBOutlet var descriptionLabel: MarqueeLabel?
    @IBOutlet var dateLabel: UILabel?
    @IBOutlet var spacingConstraint: NSLayoutConstraint?
    @IBOutlet var likesLabel: UILabel?
    @IBOutlet var likedButton: UIButton?
    @IBOutlet var addButton: UIButton?
    var fillColor = UIColor.iceDarkGray
 
    var type: ViewType = .Feed
    private var updateTimer: NSTimer?
    private var notificationHandler: AnyObject?
    
    var post: Post? {
        didSet {
            if let handler: AnyObject = notificationHandler {
                NSNotificationCenter.defaultCenter().removeObserver(handler)
            }

            setUpTimer()
            
            // update stuff
            if let post = post {
                switch type {
                case .Feed:
                    profileNameLabel?.text = post.user.name
                    descriptionLabel?.text = "\(post.song.title) · \(post.song.artist)"
                    likesLabel?.text = "\(post.likes) likes"
					SpotifyController.sharedController.spotifyIsAvailable {// Audit this model object as it's becoming a monster
						self.addButton?.hidden = !$0
					}
                    break
                case .Search:
                    profileNameLabel?.text = post.song.title
                    descriptionLabel?.text = post.song.artist
                    likesLabel?.text = ""
                    break
                }
                
                if type == .Feed {
                    post.user.loadImage {
                        avatarImageView?.image = $0
                    }
                }
                
                //! TODO: Write something that makes this nice and relative
                //! that updates every minute
                print(post.date)
				
                if let _ = post.date {
                    let dateFormatter = NSDateFormatter()
                    // dateFormatter.doesRelativeDateFormatting = true
                    dateFormatter.dateStyle = .NoStyle
                    dateFormatter.timeStyle = .ShortStyle
                    //dateLabel?.text = dateFormatter.stringFromDate(date)
                    dateLabel?.text = post.relativeDate()
                } else {
                    dateLabel?.text = ""
                }
                
                notificationHandler = NSNotificationCenter.defaultCenter().addObserverForName(PlayerDidChangeStateNotification,
                    object: post.player,
                    queue: nil, usingBlock: { [weak self] note in
                        self?.updateProfileLabelTextColor()
                        self?.setUpTimer()
                        self?.setNeedsDisplay()
                })
            }
        }
    }
	
	func updateAddButton() {
		SpotifyController.sharedController.spotifyIsAvailable {
			addButton?.hidden = !$0
		}
	}
	
    private func setUpTimer() {
        if self.updateTimer == nil && self.post?.player.isPlaying() ?? false {
            // 60 fps
            self.updateTimer = NSTimer(timeInterval: 1.0 / 60.0,
                target: self, selector: Selector("timerFired:"),
                userInfo: nil,
                repeats: true)

            NSRunLoop.currentRunLoop().addTimer(self.updateTimer!, forMode: NSRunLoopCommonModes)
        } else if !(self.post?.player.isPlaying() ?? false) {
            self.updateTimer?.invalidate()
            self.updateTimer = nil
        }
        
    }
    
    override func didMoveToWindow() {
        if progressGestureRecognizer == nil {
            progressGestureRecognizer = UIPanGestureRecognizer(target: self, action: "changeProgress:")
            progressGestureRecognizer?.delegate = self
            progressGestureRecognizer?.delaysTouchesBegan = true
            addGestureRecognizer(progressGestureRecognizer!)
        }
        
        if tapGestureRecognizer == nil {
            tapGestureRecognizer = UITapGestureRecognizer(target: self, action: "postViewPressed:")
            tapGestureRecognizer?.delegate = self
            tapGestureRecognizer?.cancelsTouchesInView = false
            addGestureRecognizer(tapGestureRecognizer!)
        }
        
        avatarImageView?.layer.cornerRadius = avatarImageView!.bounds.size.width / 2
        avatarImageView?.clipsToBounds = true
        userInteractionEnabled = true
        avatarImageView?.userInteractionEnabled = true
        profileNameLabel?.userInteractionEnabled = true
        
        layer.borderColor = UIColor.iceDarkGray.CGColor
        layer.borderWidth = 0.7
        
        profileNameLabel?.scrollRate = 0
        profileNameLabel?.trailingBuffer = 8.0
        descriptionLabel?.scrollRate = 0
        descriptionLabel?.trailingBuffer = 8.0
        
        profileNameLabel?.type = .Continuous
        profileNameLabel?.fadeLength = 8
        profileNameLabel?.tapToScroll = false
        profileNameLabel?.holdScrolling = true
        profileNameLabel?.animationDelay = 2.0
        
        descriptionLabel?.type = .Continuous
        descriptionLabel?.fadeLength = 8
        descriptionLabel?.tapToScroll = false
        descriptionLabel?.holdScrolling = true
        descriptionLabel?.animationDelay = 2.0
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        if superview != nil && dateLabel != nil {
            spacingConstraint?.constant = (dateLabel!.frame.origin.x - superview!.frame.size.width) + 8
        }
    }
    
    dynamic private func timerFired(timer: NSTimer) {
        if self.post?.player.isPlaying() ?? false {
            self.setNeedsDisplay()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setNeedsDisplay()
        updateProfileLabelTextColor()
        setUpTimer()
    }
    
    // Customize view to be able to re-use it for search results.
    func flagAsSearchResultPost() {
        descriptionLabel?.text = post!.song.title + " · " + post!.song.album
    }
    
    func updateProfileLabelTextColor() {
        let avatarLayer = avatarImageView?.layer
//        let current: AnyObject? = layer.presentationLayer()?.valueForKeyPath("transform.rotation")
        if let layer = avatarLayer {
            layer.transform = CATransform3DIdentity
            layer.removeAnimationForKey("transform.rotation")
        }

        if let post = post {
            var color: UIColor!
            let duration = NSTimeInterval(0.3) as NSTimeInterval
            let label = self.profileNameLabel!
            if post.player.isPlaying() {
                color = UIColor.iceDarkRed
				if let layer = avatarLayer {
                    let animation = CABasicAnimation(keyPath: "transform.rotation")
                    animation.fromValue = 0
                    animation.duration = 3 * M_PI
                    animation.toValue = 2 * M_PI
                    animation.repeatCount = FLT_MAX
                    layer.addAnimation(animation, forKey: "transform.rotation")
                    
                }
                
                // Will scroll labels
                profileNameLabel?.holdScrolling = false
                descriptionLabel?.holdScrolling = false
            } else {
                color = UIColor.whiteColor()
                // Labels won't scroll
                profileNameLabel?.holdScrolling = true
                descriptionLabel?.holdScrolling = true
//                if let layer = avatarLayer {
//                    print("\(current)")
//                    
//                }

            }
            
            if !label.textColor.isEqual(color) {
                UIView.transitionWithView(label, duration: duration, options: .TransitionCrossDissolve, animations: {
                    label.textColor = color
                    }, completion: {
                        (success) in
                        label.textColor = color
                })
            }
        }
    }
    
    dynamic func changeProgress(gesture: UIPanGestureRecognizer) {
        if gesture.state != .Ended {
            post?.player.pause(false)
        } else {
            post?.player.play(false)
        }
        
        let xTranslation = gesture.locationInView(self).x
        let cellWidth = bounds.width
        
        let progress = Double(xTranslation/cellWidth)
        post?.player.progress = progress
        
        self.setNeedsDisplay()
    }
    
    override func drawRect(rect: CGRect) {
        let progress = post?.player.progress ?? 0.0
        
        super.drawRect(rect)
        fillColor.setFill()
        CGContextFillRect(UIGraphicsGetCurrentContext(),
            CGRect(x: 0, y: 0,
                width: self.bounds.size.width * CGFloat(progress),
                height: self.bounds.size.height))
    }
    
    override func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == progressGestureRecognizer {
            if let player = post?.player {
                var offsetY:CGFloat = 0.0
                var offsetX:CGFloat = 0.0
                if let superview = self.superview?.superview?.superview as? UIScrollView {
                    offsetY = superview.contentOffset.y
                    offsetX = superview.contentOffset.x
                }
                let translation = self.progressGestureRecognizer?.translationInView(self)
                
                if let translation = translation {
                    return ((fabs(translation.x) > fabs(translation.y)) &&
                        (offsetY == 0.0 && offsetX == 0.0)) &&
                        player.isPlaying()
                }
            }
            return false
        }
        return true
    }
    
    func postViewPressed(sender: UITapGestureRecognizer) {
        if let post = post {
            let tapPoint = sender.locationInView(self)
            let hitView = self.hitTest(tapPoint, withEvent: nil)
            if hitView == likedButton {
				// TODO: Currently difficult to check against model for liked songs
				// Should add logic for if a post is liked by you (currently there is none)
                if (post.postID != 1.stringValue){
                    post.like()
                    likesLabel?.text = "\(post.likes+1) likes"
                    likedButton?.setImage(UIImage(named: "Heart-Red"), forState: .Normal)
                    print("Liking")
                } else {
                    post.unlike()
                    likesLabel?.text = "\(post.likes-1) likes"
                    likedButton?.setImage(UIImage(named: "Heart"), forState: .Normal)
                    print("Unliking")
                }
            } else if hitView == addButton {
                print("Adding")
            } else if post.player.isPlaying() {
                if hitView == avatarImageView || hitView == self.profileNameLabel {
                    // GO TO PROFILE VIEW CONTROLLER
                    print(post.user.fbid) 
                }
            }
        }
    }
}