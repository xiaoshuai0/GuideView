//
//  ZSGuaidViewCell.swift
//  GuideView
//
//  Created by 赵帅 on 2017/6/8.
//  Copyright © 2017年 sun5kong. All rights reserved.
//

import UIKit

class ZSGuaidViewCell: UICollectionViewCell {
    
    public var imageView: UIImageView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.isUserInteractionEnabled = true
        imageView.frame = self.contentView.bounds
        contentView.addSubview(imageView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
