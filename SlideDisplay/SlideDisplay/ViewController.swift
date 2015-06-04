//
//  ViewController.swift
//  SlideDisplay
//
//  Created by Fuji on 2015/06/04.
//  Copyright (c) 2015年 FromF. All rights reserved.
//

import UIKit
import CoreGraphics
import AVFoundation
import CoreMedia

extension UIColor {
    class func rgb(#r: Int, g: Int, b: Int, alpha: CGFloat) -> UIColor{
        return UIColor(red: CGFloat(r) / 255.0, green: CGFloat(g) / 255.0, blue: CGFloat(b) / 255.0, alpha: alpha)
    }
}

class ViewController: UIViewController , UIScrollViewDelegate {
    //表示する画像リスト
    var imageList = [
        //Sample photo by http://www.ashinari.com/
        "a0050_000081",
        "a0150_000078",
        "a0150_000165",
        "a0880_000017",
        "a0990_000074",
        "a1130_000005",
        "a1130_000380",
        "a1220_000039",
        "a1370_000058",
        "a1370_000075",
    ]
    
    var movieList = [
        //Sample Movie by http://動画素材.com
        "CITY_0852",
        "CITY_0998",
        "CITY_3748",
    ]
    // スライド表示
    var viewList = NSMutableArray()
    var circulated:Bool = true
    var leftImageIndex:NSInteger = 0
    var leftViewIndex:NSInteger = 0
    var rightViewIndex:NSInteger = 0
    var imageViewHeight : CGFloat = 0
    var imageViewWidth : CGFloat = 0
    var displayImageNum:NSInteger = 0
    let MAX_SCROLLABLE_IMAGES:NSInteger = 10000
    var MAX_IMAGE_NUM:NSInteger = 0
    var timer : NSTimer!
    // 動画再生
    var playerItem : AVPlayerItem!
    var videoPlayer : AVPlayer!
    var movieIndex:NSInteger = 0
    var playerLayer:AVPlayerLayer!
    
    //UI
    @IBOutlet weak var _scrollView: UIScrollView!
    @IBOutlet weak var _subView: UIView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        _subView.backgroundColor = UIColor.rgb(r: 0xD3, g: 0xED, b: 0xFB, alpha: 1.0)
        view.backgroundColor = UIColor.rgb(r: 0xD3, g: 0xED, b: 0xFB, alpha: 1.0)
        _scrollView.delegate = self
        self.timer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: "onNextAnimation:", userInfo: nil, repeats: false)
        
        //Notification Regist
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "playerDidPlayToEndTime:", name: AVPlayerItemDidPlayToEndTimeNotification , object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "NotificationApplicationBackground:", name: UIApplicationDidEnterBackgroundNotification , object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "NotificationApplicationForeground:", name: UIApplicationDidBecomeActiveNotification , object: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        //スライド表示準備
        imageViewHeight = _scrollView.frame.size.height
        imageViewWidth = CGFloat(NSInteger(imageViewHeight * 4 / 3))
        
        var imageViewFrame : CGRect = CGRectMake(imageViewWidth * CGFloat(-1) , 0, imageViewWidth, imageViewHeight)
        
        displayImageNum = NSInteger(_scrollView.frame.size.width / imageViewWidth)
        MAX_IMAGE_NUM = displayImageNum + 2
        
        _scrollView.contentSize = CGSizeMake(imageViewWidth * CGFloat(MAX_IMAGE_NUM), imageViewHeight)
        for var i = 0 ; i < MAX_IMAGE_NUM ; i++ {
            let imageView:UIImageView = UIImageView(frame: imageViewFrame)
            viewList.addObject(imageView)
            _scrollView.addSubview(imageView)
            imageViewFrame.origin.x += imageViewWidth
        }
        
        setImageList()
        
        //動画再生
        playMovie()
    }
    
    func blankimage () -> UIImage {
        var rect : CGRect = CGRectMake(0, 0, 1, 1)
        UIGraphicsBeginImageContext(rect.size)
        var context:CGContext! = UIGraphicsGetCurrentContext()
        CGContextSetFillColorWithColor(context, UIColor.grayColor().CGColor)
        var image:UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    func imageAtIndex(prmindex:NSInteger) -> UIImage {
        let numberOfImages : NSInteger = imageList.count
        var image:UIImage!
        var index:NSInteger = prmindex
        if circulated {
            if 0 <= index && index <= MAX_SCROLLABLE_IMAGES - 1 {
                index = ( index + numberOfImages) % numberOfImages
            }
        }
        
        if 0 <= index && index < numberOfImages {
            image = getUncachedImage(named: imageList[index])
        } else {
            image = blankimage()
        }
        
        return image
    }
    
    func updateScrollViewSetting () {
        var contentSize:CGSize = CGSizeMake(0, imageViewHeight)
        let numberOfImages : NSInteger = imageList.count
        
        if circulated {
            contentSize.width = imageViewWidth * CGFloat(MAX_SCROLLABLE_IMAGES)
            var contentOffset:CGPoint = CGPoint.zeroPoint
            contentOffset.x = CGFloat((MAX_SCROLLABLE_IMAGES - numberOfImages) / 2 ) * imageViewWidth
            var viewFrame = CGRectMake(contentOffset.x - imageViewWidth, 0, imageViewWidth, imageViewHeight)
            
            for (var i = 0 ; i < self.viewList.count ; i++) {
                var view:UIImageView = self.viewList.objectAtIndex(i) as! UIImageView
                view.frame = viewFrame
                viewFrame.origin.x += imageViewWidth
            }
            
            leftImageIndex = NSInteger(contentOffset.x / imageViewWidth)
            _scrollView.contentOffset = contentOffset
            
            var leftView:UIImageView = self.viewList.objectAtIndex(leftViewIndex) as! UIImageView
            leftView.image = imageAtIndex(displayImageNum)
        } else {
            contentSize.width = imageViewWidth * CGFloat(numberOfImages)
        }
        
        _scrollView.contentSize = contentSize
        _scrollView.showsHorizontalScrollIndicator = !circulated
    }
    
    
    func setImageList() {
        // initialize indices
        leftImageIndex = 0
        leftViewIndex = 0
        rightViewIndex = MAX_IMAGE_NUM - 1
        
        // [1]setup blank
        for var i = 0 ; i < MAX_IMAGE_NUM ; i++ {
            var view : UIImageView = viewList.objectAtIndex(i) as! UIImageView
            view.image = blankimage()
        }
        
        // [2]display area
        var index : NSInteger = 1;	// skip 0
        for (var i = 0 ; i < imageList.count ; i++) {
            var image : UIImage = getUncachedImage(named: imageList[i])!
            var view : UIImageView = viewList.objectAtIndex(index) as! UIImageView
            view.image = image
            index++
            if (index > displayImageNum) {
                break
            }
        }
        
        // [3]outside
        var rightView : UIImageView = viewList.objectAtIndex(MAX_IMAGE_NUM - 1) as! UIImageView
        rightView.image = imageAtIndex(displayImageNum)
        
        // [4]setup scrollView
        updateScrollViewSetting()
    }
    
    // MARK: - Notification
    func NotificationApplicationBackground(notification : NSNotification?) {
        // 再生を停止
        videoPlayer.pause()
    }
    
    func NotificationApplicationForeground(notification : NSNotification?) {
        // 再生時間を最初に戻して再生.
        videoPlayer.seekToTime(CMTimeMakeWithSeconds(0, Int32(NSEC_PER_SEC)))
        videoPlayer.play()
    }
    
    //MARK:- unchached uiimageload
    func getUncachedImage (named name : String) -> UIImage?
    {
        if let imgPath = NSBundle.mainBundle().pathForResource(name, ofType: "jpg")
        {
            return UIImage(contentsOfFile: imgPath)
        }
        return nil
    }
    
    //MARK:- Movie Play
    func playMovie() {
        // パスからassetを生成.
        let path = NSBundle.mainBundle().pathForResource(movieList[movieIndex] , ofType: "mov")
        let fileURL = NSURL(fileURLWithPath: path!)
        let avAsset = AVURLAsset(URL: fileURL, options: nil)
        
        // AVPlayerに再生させるアイテムを生成.
        playerItem = AVPlayerItem(asset: avAsset)
        
        // AVPlayerを生成.
        videoPlayer = AVPlayer(playerItem: playerItem)
        
        // Viewを生成.
        var videoPlayerFrame : CGRect = CGRectMake(0, 0, _subView.frame.size.width, _subView.frame.size.height)
        let videoPlayerView = AVPlayerView(frame: videoPlayerFrame)
        
        // UIViewのレイヤーをAVPlayerLayerにする.
        if playerLayer != nil {
            playerLayer.removeFromSuperlayer()
        }
        playerLayer = videoPlayerView.layer as! AVPlayerLayer
        playerLayer.videoGravity = AVLayerVideoGravityResizeAspect
        playerLayer.player = videoPlayer
        
        // レイヤーを追加する.
        _subView.layer.addSublayer(playerLayer)
        
        // 再生時間を最初に戻して再生.
        videoPlayer.seekToTime(CMTimeMakeWithSeconds(0, Int32(NSEC_PER_SEC)))
        videoPlayer.play()
    }
    
    func playerDidPlayToEndTime(notification : NSNotification?) {
        //再生する動画ファイル選択
        movieIndex++
        if (movieList.count - 1) < movieIndex {
            movieIndex = 0
        }
        
        //動画再生
        playMovie()
    }
    
    //MARK:- Animation
    func startAnimation() {
        _scrollView.delegate = nil
        var animationTime : NSTimeInterval = NSTimeInterval(imageViewWidth) / 100
        UIView.animateWithDuration(
            animationTime,
            delay:0.0,
            options:UIViewAnimationOptions.CurveLinear,
            animations: {() -> Void in
                var offsetpoint : CGPoint = CGPointMake(self._scrollView.contentOffset.x - self.imageViewWidth, self._scrollView.contentOffset.y)
                self._scrollView.contentOffset = offsetpoint
            },
            completion: {(value: Bool) in
                self._scrollView.delegate = self
                self.scrollViewDidScroll(self._scrollView)
                self.onNextAnimation(self.timer)
            }
        );
    }
    
    func onNextAnimation(timer : NSTimer){
        dispatch_async(dispatch_get_main_queue()) {
            self.startAnimation()
        }
    }
    
    //MARK:-
    enum ScrollDirection {
        case KScrollDirectionLeft
        case KScrollDirectionRight
    }
    
    
    func addViewIndex(index:NSInteger , incremental:NSInteger) -> NSInteger {
        return (index + incremental + MAX_IMAGE_NUM) % MAX_IMAGE_NUM
    }
    
    func scrollWithDirection(scrollDirection:ScrollDirection) {
        var incremental : NSInteger = 0
        var viewIndex : NSInteger = 0
        var imageIndex : NSInteger = 0
        
        if scrollDirection == ScrollDirection.KScrollDirectionLeft {
            incremental = -1
            viewIndex = rightViewIndex
        } else if scrollDirection == ScrollDirection.KScrollDirectionRight {
            incremental = 1
            viewIndex = leftViewIndex
        }
        // change position
        var view : UIImageView = viewList.objectAtIndex(viewIndex) as! UIImageView
        var frame:CGRect = view.frame
        frame.origin.x += imageViewWidth * CGFloat(MAX_IMAGE_NUM * incremental)
        view.frame = frame
        
        // change image
        leftImageIndex = leftImageIndex + incremental
        
        if scrollDirection == ScrollDirection.KScrollDirectionLeft {
            imageIndex = leftImageIndex - 1
        } else if scrollDirection == ScrollDirection.KScrollDirectionRight {
            imageIndex = leftImageIndex + displayImageNum
        }
        view.image = imageAtIndex(imageIndex)
        
        // adjust indicies
        leftViewIndex = addViewIndex(leftViewIndex, incremental: incremental)
        rightViewIndex = addViewIndex(rightViewIndex, incremental: incremental)
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        var position : CGFloat = scrollView.contentOffset.x / imageViewWidth
        var delta : CGFloat = position - CGFloat(leftImageIndex)
        
        if fabs(delta) >= 1.0 {
            if delta > 0 {
                scrollWithDirection(ScrollDirection.KScrollDirectionRight)
            } else {
                scrollWithDirection(ScrollDirection.KScrollDirectionLeft)
            }
        }
    }
}
