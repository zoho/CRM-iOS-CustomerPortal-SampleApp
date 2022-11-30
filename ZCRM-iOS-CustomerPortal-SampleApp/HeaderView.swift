//
//  HeaderView.swift
//  ZCRM-iOS-CustomerPortal-SampleApp
//
//  Created by Umashri R on 12/09/19.
//  Copyright © 2019 Umashri R. All rights reserved.
//

import UIKit

class HeaderView : UICollectionReusableView
{
    let titles : [ String ] = [ "S.No", "Product Name", "List Price", "Quantity", "Amount", "Discount", "Tax", "Total" ]
    var contentWidth : CGFloat = 0
    let numberOfColumns = 8
    
    static let headerViewIdentifier = "HeaderView"
    
    static func register( with collectionView : UICollectionView )
    {
        collectionView.register( self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: headerViewIdentifier )
    }
    
    static func dequeue( from collectionView : UICollectionView, at indexPath : IndexPath ) -> HeaderView
    {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: headerViewIdentifier, for: indexPath ) as? HeaderView ?? HeaderView()
        header.contentWidth = 8 * 150
        header.setLabels()
        return header
    }
    
    private func setLabels()
    {
        let columnWidth = contentWidth / CGFloat( numberOfColumns )
        var xOffset = [ CGFloat ]()
        for column in 0 ..< numberOfColumns {
            xOffset.append(CGFloat(column) * columnWidth)
        }
        var column = 0
        var yOffset = [CGFloat](repeating: 0, count: numberOfColumns)
        let height : CGFloat = 30
        
        for index in 0..<numberOfColumns
        {
            let frame = CGRect( x : xOffset[ column ], y : yOffset[ column ], width : columnWidth, height : height )
            let label = UILabel(frame: frame)
            label.text = titles[ index ]
            label.font = UIFont.boldSystemFont(ofSize: 18.0)
            
            label.textColor = UIColor.black
            label.textAlignment = .center
            label.minimumScaleFactor = 0.5
            label.adjustsFontSizeToFitWidth = true
            label.autoresizingMask = [.flexibleHeight, .flexibleWidth]
            self.addSubview(label)
            
            yOffset[ column ] = yOffset[ column ] + height
            
            column = column < ( numberOfColumns - 1 ) ? ( column + 1 ) : 0
        }
    }
}
