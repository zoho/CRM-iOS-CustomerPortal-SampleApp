//
//  GridLayout.swift
//  ZCRM-iOS-CustomerPortal-SampleApp
//
//  Created by Umashri R on 12/09/19.
//  Copyright © 2019 Umashri R. All rights reserved.
//

import UIKit

class GridLayout: UICollectionViewLayout
{
    fileprivate var numberOfColumns : Int = 8
    fileprivate var cache : [ UICollectionViewLayoutAttributes ] = [ UICollectionViewLayoutAttributes ]()
    fileprivate var headerCache : UICollectionViewLayoutAttributes?
    fileprivate var footerCache : UICollectionViewLayoutAttributes?
    var contentHeight : CGFloat = 0
    fileprivate var contentWidth : CGFloat {
        return 8 * 150
    }
    override var collectionViewContentSize: CGSize
    {
        return CGSize( width : contentWidth, height : contentHeight )
    }
    var footerIndex : Int?
    var footerXOffset : CGFloat?
    var footerYOffset : CGFloat?
    
    override func prepare()
    {
        super.prepare()
        cache.removeAll()
        guard let collectionView = collectionView, cache.isEmpty == true else
        {
            return
        }
        
        let columnWidth = contentWidth / CGFloat( numberOfColumns )
        var xOffset = [ CGFloat ]()
        for column in 0 ..< numberOfColumns {
            xOffset.append(CGFloat(column) * columnWidth)
        }
        var column = 0
        var yOffset = [CGFloat](repeating: 0, count: numberOfColumns)
        let height : CGFloat = 30
        var row = 1
        
        for item in 0..<collectionView.numberOfItems( inSection : 0 )
        {
            if item < 8
            {
                let indexPath = IndexPath( item : item, section : 0 )
                let frame = CGRect( x : xOffset[ 0 ], y : yOffset[ column ], width : columnWidth * CGFloat(column), height : height )
                
                let attributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, with: indexPath)
                attributes.frame = frame
                headerCache = attributes
                
                yOffset[ column ] = yOffset[ column ] + height
                
                column = column < ( numberOfColumns - 1 ) ? ( column + 1 ) : 0
            }
            else if item <= collectionView.numberOfItems(inSection: 0) - ( 8 * 5 )
            {
                let indexPath = IndexPath( item : item - 8, section : 0 )
                let frame = CGRect( x : xOffset[ column ], y : yOffset[ column ], width : columnWidth, height : height )
                
                let attributes = UICollectionViewLayoutAttributes( forCellWith : indexPath )
                attributes.frame = frame
                cache.append( attributes )
                
                yOffset[ column ] = yOffset[ column ] + height
                
                column = column < ( numberOfColumns - 1 ) ? ( column + 1 ) : 0
            }
            else
            {
                let indexPath = IndexPath( item : item, section : 0 )
                
                if item == collectionView.numberOfItems(inSection: 0) - ( 8 * 5 ) + 1
                {
                    footerXOffset = xOffset[ 0 ]
                    footerYOffset = yOffset[ column ]
                }
                
                let frame = CGRect( x : footerXOffset!, y : footerYOffset!, width : columnWidth * CGFloat( column ), height : height * CGFloat( row ) )
                
                let attributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, with: indexPath)
                attributes.frame = frame
                footerCache = attributes
                
                yOffset[ column ] = yOffset[ column ] + height
                
                column = column < ( numberOfColumns - 1 ) ? ( column + 1 ) : 0
                row = ( row + 1 ) / 8
            }
        }
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [ UICollectionViewLayoutAttributes ]?
    {
        var visibleLayoutAttributes = [UICollectionViewLayoutAttributes]()
        
        let header = layoutAttributesForSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, at: IndexPath(row: 0, section: 0))
        
        let footer = layoutAttributesForSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter, at: IndexPath(item: footerIndex! + 1, section: 0) )
        
        visibleLayoutAttributes.append( header! )
        
        for attributes in cache {
            if attributes.frame.intersects(rect) {
                visibleLayoutAttributes.append(attributes)
            }
        }
        visibleLayoutAttributes.removeLast()
        visibleLayoutAttributes.append( footer! )
        return visibleLayoutAttributes
    }
    
    override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes?
    {
        switch elementKind
        {
        case UICollectionView.elementKindSectionHeader :
            return headerCache
            
        case UICollectionView.elementKindSectionFooter :
            return footerCache
            
        default:
            return nil
        }
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes?
    {
        return cache[ indexPath.item ]
    }
    
    override func invalidateLayout()
    {
        prepare()
    }
}
