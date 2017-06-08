//
//  ZSGuaidViewController.swift
//  GuideView
//
//  Created by 赵帅 on 2017/6/8.
//  Copyright © 2017年 sun5kong. All rights reserved.
//

import UIKit

class ZSGuaidViewController: UIViewController {

    var hide: (() -> Void)?
    
    fileprivate var property: NSDictionary?
    fileprivate var imageNames: [String]?
    fileprivate var collectionView: UICollectionView!
    fileprivate var pageControl: UIPageControl!
    fileprivate var hideButton: UIButton?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let path = Bundle.main.path(forResource: "GuideProperty", ofType: "plist")
        
        property = NSDictionary(contentsOfFile: path!)
        imageNames = property?.value(forKey: "kImageNamsArray") as? [String]
        if property != nil {
            setUpUI()
        }
    }
    deinit {
        print("ZSGuaidViewController销毁")
    }
    fileprivate func setUpUI() {
        
        self.view.backgroundColor = UIColor.clear
        
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.scrollDirection = .horizontal
        layout.itemSize = self.view.frame.size
        collectionView = UICollectionView(frame: self.view.bounds, collectionViewLayout: layout)
        collectionView.bounces = true
        collectionView.isPagingEnabled = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = UIColor.clear
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(ZSGuaidViewCell.self, forCellWithReuseIdentifier: "GUAIDCELL")
        view.addSubview(collectionView)
        
        pageControl = UIPageControl()
        pageControl.isUserInteractionEnabled = false
        pageControl.hidesForSinglePage = true
        pageControl.numberOfPages = imageNames?.count ?? 0
        let pageSize = pageControl.size(forNumberOfPages: (imageNames?.count ?? 0))
        pageControl.frame = CGRect(x: (self.view.center.x - pageSize.width / 2), y: (self.view.frame.height - pageSize.height), width: pageSize.width, height: pageSize.height)
        view.addSubview(pageControl)
        
        if let hiddenBtnImageName = property!.value(forKey: "kHiddenBtnImageName") as? String {
            hideButton = UIButton(type: .custom)
            hideButton?.isHidden = true
            hideButton?.setImage(UIImage(named: hiddenBtnImageName), for: .normal)
            hideButton?.sizeToFit()
            hideButton?.addTarget(self, action: #selector(hideBtnAction), for: .touchUpInside)
            let centerStr: String = property!.value(forKey: "kHiddenBtnCenter") as? String ?? "{0.5, 0.85}"
            let point = CGPointFromString(centerStr)
            hideButton?.center = CGPoint(x: self.view.frame.width * point.x, y: self.view.frame.height * point.y)
            view.addSubview(hideButton!)
        }
        
    }
   

    @objc fileprivate func hideBtnAction() {
        if hide != nil {
            hide!()
        }
    }
}




extension ZSGuaidViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.imageNames?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GUAIDCELL", for: indexPath) as? ZSGuaidViewCell
        cell?.imageView.image = UIImage(named: (self.imageNames?[indexPath.row])!)
        return cell!
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let current = Int(scrollView.contentOffset.x / scrollView.frame.size.width)
        
        self.pageControl.currentPage = current
        hideButton?.isHidden = ((imageNames?.count)! - 1 != current)
    }
    
}













