//
//  ZSLaunchAdViewController.swift
//  NewsDemo
//
//  Created by 赵帅 on 2017/4/11.
//  Copyright © 2017年 zhaoshuai. All rights reserved.
//

import UIKit
//import Kingfisher
//MARK: 屏幕相关
public let ScreenBounds: CGRect = UIScreen.main.bounds
public let ScreenWidth: CGFloat = ScreenBounds.size.width
public let ScreenHeight: CGFloat = ScreenBounds.size.height

enum SkipButtonType {
    case none       //无跳转按钮
    case timer      //跳过+倒计时
    case circle     //圆形跳转
}

enum SkipButtonPosition {
    case rightTop               //屏幕右上角
    case rightBottom            //屏幕右下角
    case rightAdViewBottom      //广告的右下角
}

enum TransitionType {
    case rippleEffect           //波纹
    case fade                   //淡化
    case flipFromTop            // 上下翻转
    case filpFromBottom
    case filpFromLeft           // 左右翻转
    case filpFromRight
}

class ZSLaunchAdViewController: UIViewController {
    //MARK: 属性
    //显示时间默认为3s
    var defaultTime = 3
    //广告距离底部100
    fileprivate var adViewBottomMargin: CGFloat = 100
    fileprivate var transitionType: TransitionType = .fade
    //按钮位置默认为右上角
    fileprivate var skipBtnPosition: SkipButtonPosition = .rightTop
    //按钮类型
    fileprivate var skipBtnType: SkipButtonType = .timer {
        didSet {
            var y: CGFloat = 0
            
            switch skipBtnPosition {
            case .rightBottom:
                y = ScreenHeight - 50
            case .rightAdViewBottom:
                y = ScreenHeight - adViewBottomMargin - 50
            default:
                y = 30
            }
            
            skipBtn.frame = self.skipBtnType == .timer ? CGRect(x: Int(ScreenWidth) - 70, y: Int(y), width: 60, height: 30) : CGRect(x: Int(ScreenWidth) - 50, y: Int(y), width: 30, height: 30)
            skipBtn.titleLabel?.font = UIFont.systemFont(ofSize: self.skipBtnType == .timer ? 13.5 : 12)
            skipBtn.setTitle(self.skipBtnType == .timer ? "\(self.adDuration) 跳过" : "跳过", for: .normal)
        }
    }
    //广告时间
    fileprivate var adDuration: Int = 0
    //默认3s定时器
    fileprivate var originalTimer: DispatchSourceTimer?
    //数据定时器
    fileprivate var dataTimer: DispatchSourceTimer?
    
    fileprivate var adImageViewClick:(()->())?
    fileprivate var completion: (()->())?
    fileprivate var setAdParams: ((_ launchAdVC: ZSLaunchAdViewController) -> ())?
    //layer 
    fileprivate var animationLayer: CAShapeLayer?
    
    fileprivate lazy var launchImageView: UIImageView = {
        let imageView: UIImageView = UIImageView()
        imageView.frame = ScreenBounds
        imageView.image = self.getLaunchImage()
        return imageView
    }()
    
    fileprivate lazy var launchAdImageView: UIImageView = { [unowned self] in
        let imageView: UIImageView = UIImageView()
        imageView.frame = CGRect(x: 0, y: 0, width: ScreenWidth, height: ScreenHeight - self.adViewBottomMargin)
        imageView.backgroundColor = UIColor.red
        imageView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapLaunchAdAction(tap:)))
        imageView.addGestureRecognizer(tap)
        imageView.alpha = 0.2
        return imageView
    }()
    
    fileprivate lazy var skipBtn: UIButton = {
        let button: UIButton = UIButton(type: .custom)
        button.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        button.layer.cornerRadius = 15
        button.addTarget(self, action: #selector(skipBtnClick), for: .touchUpInside)
        return button
    }()
    convenience init(adViewBottomDistance: CGFloat = 100, skipBtnPosition: SkipButtonPosition = .rightTop, setAdParams: ((_ launchAdVC: ZSLaunchAdViewController) -> ())?) {
        self.init(nibName: nil, bundle: nil)
        self.adViewBottomMargin = adViewBottomDistance
        self.skipBtnPosition = skipBtnPosition
        self.setAdParams = setAdParams
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.view.addSubview(self.launchImageView)
        if self.setAdParams != nil {
            self.setAdParams!(self)
        }
        startTimer()
    }
    
    

}
//MARK: 公有方法
extension ZSLaunchAdViewController {
    /*
     *  url:                广告的地址
     *
     *  defaultDuration:    广告图片没有加载的最大时间
     *
     *  adDuration:         广告的显示时间
     *
     *  skipBtnType:        跳转按钮类型
     *
     *  transitionType:     页面消失的类型
     *
     *  adImageViewClick:   点击广告的时间
     *
     *  completion:         广告播放完成的事件
     */
    func setAdImageView(url: String, defaultDuration: Int, adDuration: Int, skipBtnType: SkipButtonType = .timer, transitionType: TransitionType = .rippleEffect, adImageViewClick:(()->())?, completion:(()->())?) {
        self.transitionType = transitionType
        self.adDuration = adDuration
        
        if defaultDuration >= 1 {
            self.defaultTime = defaultDuration
        }
        
        if adDuration < 1 {
            self.adDuration = 1
        }
        self.skipBtnType = skipBtnType
        if url != "" {
            view.addSubview(launchAdImageView)
            launchAdImageView.kf.setImage(with: URL.init(string: url),  completionHandler: { (image, error, cacheType, url) in
                self.skipBtn.removeFromSuperview()
                if self.animationLayer != nil {
                    self.animationLayer?.removeFromSuperlayer()
                    self.animationLayer = nil
                }
                
                if self.skipBtnType != .none {
                    self.view.addSubview(self.skipBtn)
                    if self.skipBtnType == .circle {
                        self.addLayer()
                    }
                }
                self.adStartTimer()
                
                UIView.animate(withDuration: 0.8, animations: { 
                    self.launchAdImageView.alpha = 1
                })
            })
        }
        self.adImageViewClick = adImageViewClick
        self.completion = completion
    }
    
    fileprivate func addLayer() {
        let bezierPath = UIBezierPath(ovalIn: skipBtn.bounds)
        animationLayer = CAShapeLayer()
        animationLayer?.path = bezierPath.cgPath
        animationLayer?.lineWidth = 2
        animationLayer?.strokeColor = UIColor.red.cgColor
        animationLayer?.fillColor = UIColor.clear.cgColor
        let animation = CABasicAnimation(keyPath: "strokeStart")
        animation.duration = Double(adDuration)
        animation.fromValue = 0
        animation.toValue = 1
        animationLayer?.add(animation, forKey: nil)
        skipBtn.layer.addSublayer(animationLayer!)
    }
}
//MARK: GCD定时器
extension ZSLaunchAdViewController {
    fileprivate func startTimer() {
        originalTimer = DispatchSource.makeTimerSource(flags: [], queue: DispatchQueue.main)
        originalTimer?.scheduleRepeating(deadline: DispatchTime.now(), interval: DispatchTimeInterval.seconds(1), leeway: DispatchTimeInterval.microseconds(defaultTime))
        originalTimer?.setEventHandler(handler: { 
            print(self.defaultTime)
            if self.defaultTime == 0 {
                self.originalTimer?.cancel()
                self.launchAdVCRemove(completion: nil)
            }
            self.defaultTime -= 1
        })
        originalTimer?.resume()
    }
    
    fileprivate func adStartTimer() {
        originalTimer?.cancel()
        
        dataTimer = DispatchSource.makeTimerSource(flags: [], queue: DispatchQueue.main)
        dataTimer?.scheduleRepeating(deadline: DispatchTime.now(), interval: DispatchTimeInterval.seconds(1), leeway: DispatchTimeInterval.milliseconds(adDuration))
        dataTimer?.setEventHandler(handler: { 
            self.skipBtn.setTitle(self.skipBtnType == .timer ? "\(self.adDuration) 跳过" : "跳过", for: .normal)
            if self.adDuration == 0 {
                self.dataTimer?.cancel()
                self.launchAdVCRemove(completion: nil)
            }
            self.adDuration -= 1
        })
        dataTimer?.resume()
    }
}
//MARK: 点击事件
extension ZSLaunchAdViewController {
    @objc fileprivate func tapLaunchAdAction(tap: UITapGestureRecognizer) {
        print("点击广告")
        dataTimer?.cancel()
        launchAdVCRemove { 
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.4, execute: { 
                if self.adImageViewClick != nil {
                    self.adImageViewClick!()
                }
            })
        }
    }
    
    @objc fileprivate func skipBtnClick() {
        dataTimer?.cancel()
        launchAdVCRemove(completion: nil)
    }
    
    //关闭广告
    fileprivate func launchAdVCRemove(completion: (() -> ())?) {
        let trans = CATransition()
        trans.duration = 0.5
        switch transitionType {
        case .rippleEffect:
            trans.type = "rippleEffect"
        case .filpFromLeft:
            trans.type = "oglFlip"
            trans.subtype = kCATransitionFromLeft
        case .filpFromRight:
            trans.type = "oglFlip"
            trans.subtype = kCATransitionFromRight
        case .flipFromTop:
            trans.type = "oglFlip"
            trans.subtype = kCATransitionFromTop
        case .filpFromBottom:
            trans.type = "oglFlip"
            trans.subtype = kCATransitionFromBottom
        default:
            trans.type = "fade"
        }
        
        UIApplication.shared.keyWindow?.layer.add(trans, forKey: nil)
        if self.completion != nil {
            self.completion!()
            if completion != nil {
                completion!()
            }
        }
    }
}
//MARK: 私有方法
extension ZSLaunchAdViewController {
    fileprivate func getLaunchImage() -> UIImage {
        if assetsLaunchImage() == nil {
            return storyboardLaunchImage()!
        }
        return assetsLaunchImage()!
    }
    
    fileprivate func assetsLaunchImage() -> UIImage? {
        let size = UIScreen.main.bounds.size
        let orientation = "Portrait"
        var launchImageName: String?
        guard let launchImages = Bundle.main.infoDictionary?["UILaunchImages"] as? [[String: Any]] else {
            return nil
        }
        for dict in launchImages {
            let imageSize = CGSizeFromString(dict["UILaunchImageSize"] as! String)
            if __CGSizeEqualToSize(imageSize, size) && orientation == (dict["UILaunchImageOrientation"] as! String) {
                launchImageName = dict["UILaunchImageName"] as? String
                let image = UIImage(named: launchImageName!)
                return image
            }
        }
        return nil
    }
    /// 获取Storyboard
    fileprivate func storyboardLaunchImage() -> UIImage? {
        guard let storyboardLaunchName = Bundle.main.infoDictionary?["UILaunchStoryboardName"] as? String,
            let launchVC = UIStoryboard.init(name: storyboardLaunchName, bundle: nil).instantiateInitialViewController()
            else {
                return nil
        }
        let view = launchVC.view
        view?.frame = UIScreen.main.bounds
        let image = viewConvertImage(view: view!)
        return image
    }
    /// view转换图片
    fileprivate func viewConvertImage(view: UIView) -> UIImage {
        let size = view.bounds.size
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        view.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
}






















