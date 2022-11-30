//
//  GridCell.swift
//  ZCRM-iOS-CustomerPortal-SampleApp
//
//  Created by Umashri R on 12/09/19.
//  Copyright © 2019 Umashri R. All rights reserved.
//

import UIKit

class GridCell: UICollectionViewCell
{
    var labelText : String = ""
    {
        didSet
        {
            setLabel().text = labelText
        }
    }
    
    static let identifier = "InfiniteGridCell"
    static func register(with collectionView: UICollectionView) {
        collectionView.register(self, forCellWithReuseIdentifier: identifier)
    }
    
    static func dequeue( from collectionView : UICollectionView, at indexPath : IndexPath, for label : String ) -> GridCell
    {
        let cell = collectionView.dequeueReusableCell( withReuseIdentifier : identifier, for : indexPath ) as? GridCell ?? GridCell()
        cell.labelText = label
        return cell
    }
    
    private func setLabel() -> UILabel {
        if let label = self.contentView.subviews.first as? UILabel {
            return label
        }
        let label = UILabel(frame: self.contentView.bounds)
        label.font = UIFont.systemFont(ofSize: 18.0)
        label.textColor = UIColor.black
        label.textAlignment = .center
        label.minimumScaleFactor = 0.5
        label.adjustsFontSizeToFitWidth = true
        label.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        self.contentView.addSubview(label)
        return label
    }
}
