//
//  DetailViewController.swift
//  ZCRMCustomerPortal
//
//  Created by Umashri R on 27/08/19.
//  Copyright © 2019 Umashri R. All rights reserved.
//

import UIKit
import ZCRMiOS

class DetailViewController: UIViewController {
    
    var layouts : [ ZCRMLayout ] = [ ZCRMLayout ]()
    var record : ZCRMRecord
    var myView = UIView()
    var productDetails : [ ZCRMInventoryLineItem ]?
    var footerDetails : [ String : String ]?
    var count = 0
    var numOfProductDetails : Int?
    let collectionView = GridView()
    
    init( record : ZCRMRecord, layouts : [ ZCRMLayout ], nibName nibNameOrNil : String?, bundle nibBundleOrNil : Bundle? )
    {
        self.record = record
        self.layouts = layouts
        super.init( nibName : nibNameOrNil, bundle : nibBundleOrNil )
    }
    
    required init?( coder aDecoder : NSCoder )
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear( _ animated : Bool )
    {
        let logoutButton = UIBarButtonItem( title : "Logout", style : .plain, target : self, action : #selector( logout ) )
        self.navigationItem.rightBarButtonItem = logoutButton
        
        super.viewWillAppear( true )
        myView.backgroundColor = .white
        self.view = myView
        var isFirst = true
        var hasData = false
        
        let sections = layouts[0].sections
        
        var lastView : UIView = self.view
        
        for section in sections
        {
            if section.name == "Product Details"
            {
                let fields = section.fields
                footerDetails = [ String : String ]()
                if record.getData()[ "Product_Details" ] != nil
                {
                    collectionView.collectionViewLayout.invalidateLayout()
                    for field in fields
                    {
                        if field.apiName == "Product_Details"
                        {
                            if let productDet = record.getData()[ field.apiName ] as? [ ZCRMInventoryLineItem ]
                            {
                                lastView = addSectionName( labelText : section.displayName, previousView : lastView, isFirst : isFirst )
                                hasData = true
                                isFirst = false
                                self.productDetails = productDet
                            }
                        }
                        else
                        {
                            if let isPresentInViewLayout = field.isPresentInViewLayout(), isPresentInViewLayout
                            {
                                if let value = record.getData()[ field.apiName ] as? String
                                {
                                    footerDetails?.updateValue( value, forKey: field.apiName )
                                    lastView = self.addData( label : field.displayLabel, value : value, previousView : lastView )
                                }
                                else if let value = record.getData()[ field.apiName ] as? Double
                                {
                                    footerDetails?.updateValue( String(value), forKey: field.apiName )
                                }
                                else if let value = record.getData()[ field.apiName ] as? Int
                                {
                                    footerDetails?.updateValue( String(value), forKey: field.apiName )
                                }
                                else if let value = record.getData()[ field.apiName ] as? Int64
                                {
                                    footerDetails?.updateValue( String(value), forKey: field.apiName )
                                }
                                else
                                {
                                    print("Not handled")
                                }
                            }
                        }
                    }
                    lastView = self.addCollectionView( previousView : lastView )
                }
            }
            else
            {
                let fields = section.fields
                for field in fields
                {
                    if let isPresentInViewLayout = field.isPresentInViewLayout(), isPresentInViewLayout
                    {
                        if let value = record.getData()[ field.apiName ] as? String
                        {
                            if !hasData
                            {
                                lastView = addSectionName( labelText : section.displayName, previousView : lastView, isFirst : isFirst )
                                hasData = true
                                isFirst = false
                            }
                            lastView = self.addData( label : field.displayLabel, value : value, previousView : lastView )
                        }
                        else if let value = record.getData()[ field.apiName ] as? Double
                        {
                            if !hasData
                            {
                                lastView = addSectionName( labelText : section.displayName, previousView : lastView, isFirst : isFirst )
                                hasData = true
                                isFirst = false
                            }
                            lastView = self.addData( label : field.displayLabel, value : String( value ), previousView : lastView )
                        }
                        else if let value = record.getData()[ field.apiName ] as? Int
                        {
                            if !hasData
                            {
                                lastView = addSectionName( labelText : section.displayName, previousView : lastView, isFirst : isFirst )
                                hasData = true
                                isFirst = false
                            }
                            lastView = self.addData( label : field.displayLabel, value : String( value ), previousView : lastView )
                        }
                        else if let value = record.getData()[ field.apiName ] as? Int64
                        {
                            if !hasData
                            {
                                lastView = addSectionName( labelText : section.displayName, previousView : lastView, isFirst : isFirst )
                                hasData = true
                                isFirst = false
                            }
                            lastView = self.addData( label : field.displayLabel, value : String( value ), previousView : lastView )
                        }
                        else if (record.getData()[ field.apiName ] as? [ String : Any ]) != nil
                        {
                            if !hasData
                            {
                                lastView = addSectionName( labelText : section.displayName, previousView : lastView, isFirst : isFirst )
                                hasData = true
                                isFirst = false
                            }
                            print( "Not handled" )
                        }
                    }
                }
            }
            
            
            hasData = false
        }
    }
    
    override func viewDidAppear( _ animated : Bool )
    {
        super.viewDidAppear( true )
        
        collectionView.scrollToCenter()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    func addSectionName( labelText : String, previousView : UIView, isFirst : Bool ) -> UIView
    {
        let label = UILabel()
        label.text = labelText
        label.textColor = .black
        label.font = UIFont.boldSystemFont( ofSize : 18 )
        label.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview( label )
        
        if isFirst
        {
            label.topAnchor.constraint( equalTo : previousView.safeAreaLayoutGuide.topAnchor, constant : 10 ).isActive = true
            label.leadingAnchor.constraint( equalTo : self.view.safeAreaLayoutGuide.leadingAnchor, constant : 10 ).isActive = true
            label.widthAnchor.constraint( equalTo : self.view.safeAreaLayoutGuide.widthAnchor, multiplier : 0.5 ).isActive = true
            label.heightAnchor.constraint( equalToConstant : 20 ).isActive = true
        }
        else
        {
            label.topAnchor.constraint( equalTo : previousView.safeAreaLayoutGuide.bottomAnchor, constant : 10 ).isActive = true
            label.leadingAnchor.constraint( equalTo : self.view.safeAreaLayoutGuide.leadingAnchor, constant : 10 ).isActive = true
            label.widthAnchor.constraint( equalTo : self.view.safeAreaLayoutGuide.widthAnchor, multiplier : 0.5 ).isActive = true
            label.heightAnchor.constraint( equalToConstant : 20 ).isActive = true
        }
        return label
    }
    
    func addData( label : String, value : String?, previousView : UIView ) -> UIView
    {
        let label1 = UILabel()
        label1.text = label
        label1.textColor = .darkGray
        label1.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview( label1 )
        
        let label2 = UILabel()
        label2.text = value
        label2.textColor = .black
        label2.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview( label2 )
        
        label1.topAnchor.constraint( equalTo : previousView.safeAreaLayoutGuide.bottomAnchor, constant : 10 ).isActive = true
        label1.leadingAnchor.constraint( equalTo : self.view.safeAreaLayoutGuide.leadingAnchor, constant : 10 ).isActive = true
        label1.widthAnchor.constraint( equalTo : self.view.safeAreaLayoutGuide.widthAnchor, multiplier : 0.5 ).isActive = true
        label1.heightAnchor.constraint( equalToConstant : 20 ).isActive = true
        
        label2.topAnchor.constraint( equalTo : label1.topAnchor ).isActive = true
        label2.leadingAnchor.constraint( equalTo : label1.trailingAnchor, constant : 10 ).isActive = true
        label2.trailingAnchor.constraint( equalTo : self.view.safeAreaLayoutGuide.trailingAnchor, constant : -10 ).isActive = true
        label2.heightAnchor.constraint( equalTo : label1.heightAnchor ).isActive = true
        
        return label1
    }
    
    func addCollectionView( previousView : UIView ) -> UICollectionView
    {
        collectionView.productCount = productDetails!.count
        collectionView.contentHeight = CGFloat( 30 * ( productDetails!.count + 2 ) )
        collectionView.isScrollEnabled = true
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.dataSource = self
        collectionView.backgroundColor = .white
        GridCell.register( with : collectionView )
        
        HeaderView.register(with: collectionView)
        FooterView.register(with: collectionView)
        
        self.view.addSubview( collectionView )
        
        collectionView.topAnchor.constraint( equalTo : previousView.safeAreaLayoutGuide.bottomAnchor, constant : 10 ).isActive = true
        collectionView.leadingAnchor.constraint( equalTo : self.view.safeAreaLayoutGuide.leadingAnchor, constant : 10 ).isActive = true
        collectionView.widthAnchor.constraint( equalTo : self.view.safeAreaLayoutGuide.widthAnchor ).isActive = true
        if productDetails!.count > 20
        {
            collectionView.bottomAnchor.constraint( equalTo : collectionView.topAnchor, constant : 600 ).isActive = true
        }
        else
        {
            collectionView.bottomAnchor.constraint( equalTo : collectionView.topAnchor, constant : CGFloat( ( productDetails!.count + 6 ) * 30 ) ).isActive = true
        }
        
        return collectionView
    }
    
    @objc func logout()
    {
        ZCRMSDKClient.shared.logout { error in
            if let error = error {
                print("Logout failed.... \(error)")
                return
            }
            print("logout successful")
            
            DispatchQueue.main.async {
                ZCRMSDKClient.shared.showLogin { error in
                    if let error = error {
                        print("unable to show login.... \(error)")
                        return
                    }
                    print( "Login successful" )
                }
            }
        }
    }
}

extension DetailViewController : UICollectionViewDataSource
{
    func numberOfSections(in collectionView: UICollectionView) -> Int
    {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return ( self.productDetails!.count + 6 ) * 8
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let cell = GridCell.dequeue( from : collectionView, at : indexPath, for : getData( indexPath : indexPath ) )
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView
    {
        switch kind {
            
        case UICollectionView.elementKindSectionHeader :
            let header = HeaderView.dequeue(from: collectionView, at: indexPath)
            return header
            
        case UICollectionView.elementKindSectionFooter :
            let footer = FooterView.dequeue(from: collectionView, at: indexPath, for: footerDetails!)
            return footer
            
        default:
            assert(false, "Unexpected element kind")
        }
    }
    
    func getData( indexPath : IndexPath ) -> String
    {
        let index = indexPath.item / 8
        if index < productDetails!.count
        {
            guard let prodDetails = productDetails?[ index ] else
            {
                return ""
            }
            if indexPath.item % 8 == 0
            {
                return String( index + 1 )
            }
            else if indexPath.item % 8 == 1
            {
                return prodDetails.product.label ?? ""
            }
            else if indexPath.item % 8 == 2
            {
                return String( prodDetails.listPrice )
            }
            else if indexPath.item % 8 == 3
            {
                return String( prodDetails.quantity )
            }
            else if indexPath.item % 8 == 4
            {
                return String( prodDetails.total )
            }
            else if indexPath.item % 8 == 5
            {
                return String( prodDetails.discount )
            }
            else if indexPath.item % 8 == 6
            {
                return String( prodDetails.tax )
            }
            else
            {
                return String( prodDetails.netTotal )
            }
        }
        else
        {
            return ""
        }
    }
}
