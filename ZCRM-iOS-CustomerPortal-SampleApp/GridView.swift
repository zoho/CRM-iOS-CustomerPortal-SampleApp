//
//  GridView.swift
//  ZCRM-iOS-CustomerPortal-SampleApp
//
//  Created by Umashri R on 12/09/19.
//  Copyright © 2019 Umashri R. All rights reserved.
//

import UIKit

class GridView : UICollectionView
{
    let collectionViewHeaderFooterReuseIdentifier = "MyHeaderFooterClass"
    var contentHeight : CGFloat?{
        didSet
        {
            if let contentHeight = contentHeight, let prodCount = productCount
            {
                let layout = GridLayout()
                layout.contentHeight = contentHeight
                layout.footerIndex = prodCount + 1
                self.collectionViewLayout = layout
            }
            else if let contentHeight = contentHeight
            {
                let layout = GridLayout()
                layout.contentHeight = contentHeight
            }
        }
    }
    var productCount : Int?{
        didSet
        {
            if let prodCount = productCount, let contentHeight = contentHeight
            {
                let layout = GridLayout()
                layout.footerIndex = prodCount + 1
                layout.contentHeight = contentHeight
            }
            else if let prodCount = productCount
            {
                let layout = GridLayout()
                layout.footerIndex = prodCount + 1
            }
        }
    }
    
    convenience init()
    {
        let layout = GridLayout()
        self.init( frame : .zero, collectionViewLayout : layout )
        self.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.translatesAutoresizingMaskIntoConstraints = true
        self.backgroundColor = UIColor.clear
    }
    
    func scrollToCenter()
    {
        let size = self.contentSize
        let topLeftCoordinatesWhenCentered = CGPoint( x : ( size.width - self.frame.width ) * 0.5, y : ( size.height - self.frame.height ) * 0.5 )
        self.setContentOffset( topLeftCoordinatesWhenCentered, animated : false )
    }
}
