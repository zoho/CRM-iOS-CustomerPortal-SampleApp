//
//  FooterView.swift
//  ZCRM-iOS-CustomerPortal-SampleApp
//
//  Created by Umashri R on 12/09/19.
//  Copyright © 2019 Umashri R. All rights reserved.
//

import UIKit

class FooterView: UICollectionReusableView
{
    var contentWidth : CGFloat = 0
    let numberOfColumns = 8
    var footerDetails : [ String : String ] = [ String : String ]()
    
    static let footerViewIdentifier = "FooterView"
    
    static func register( with collectionView : UICollectionView )
    {
        collectionView.register( self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: footerViewIdentifier )
    }
    
    static func dequeue( from collectionView : UICollectionView, at indexPath : IndexPath, for details : [ String : String ] ) -> FooterView
    {
        let footer = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: footerViewIdentifier, for: indexPath ) as? FooterView ?? FooterView()
        footer.contentWidth = 8 * 150
        footer.footerDetails = details
        footer.setupLabels()
        return footer
    }
    
    private func setupLabels()
    {
        let columnWidth = contentWidth / CGFloat( numberOfColumns )
        var xOffset = [ CGFloat ]()
        for column in 0 ..< numberOfColumns {
            xOffset.append(CGFloat(column) * columnWidth)
        }
        var column = 0
        var yOffset = [CGFloat](repeating: 0, count: numberOfColumns)
        let height : CGFloat = 30
        var count = 0
        for _ in 0..<numberOfColumns * 5
        {
            if column == 6
            {
                let frame = CGRect( x : xOffset[ column ], y : yOffset[ column ], width : columnWidth, height : height )
                setLabel(frame: frame, text: getKey(count: count))
            }
            else if column == 7
            {
                let frame = CGRect( x : xOffset[ column ], y : yOffset[ column ], width : columnWidth, height : height )
                setLabel(frame: frame, text: footerDetails[ getKey(count: count) ]!)
            }
            
            
            yOffset[ column ] = yOffset[ column ] + height
            
            column = column < ( numberOfColumns - 1 ) ? ( column + 1 ) : 0
            count = ( count + 1 ) % 5
        }
    }
    
    private func getKey( count : Int ) -> String
    {
        if count == 0
        {
            return "Sub_Total"
        }
        else if count == 1
        {
            return "Discount"
        }
        else if count == 2
        {
            return "Tax"
        }
        else if count == 3
        {
            return "Adjustment"
        }
        else if count == 4
        {
            return "Grand_Total"
        }
        else
        {
            return ""
        }
    }
    
    private func setLabel( frame : CGRect, text : String )
    {
        let label = UILabel(frame: frame)
        label.text = text
        label.font = UIFont.boldSystemFont(ofSize: 18.0)
        
        label.textColor = UIColor.black
        label.textAlignment = .center
        label.minimumScaleFactor = 0.5
        label.adjustsFontSizeToFitWidth = true
        label.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        self.addSubview(label)
    }
}

