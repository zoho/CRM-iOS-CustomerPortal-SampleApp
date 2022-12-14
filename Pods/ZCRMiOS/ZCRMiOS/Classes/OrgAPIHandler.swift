//
//  OrgAPIHandler.swift
//  ZCRMiOS
//
//  Created by Boopathy P on 30/08/17.
//  Copyright © 2017 zohocrm. All rights reserved.
//

import Foundation

internal class OrgAPIHandler : CommonAPIHandler
{
    let cache : CacheFlavour
    internal var variable : ZCRMVariable?
    
    internal init( cacheFlavour : CacheFlavour ) {
        self.cache = cacheFlavour
    }
    
    init( variable : ZCRMVariable ) {
        self.cache = CacheFlavour.noCache
        self.variable = variable
    }
    
    internal init( variable : ZCRMVariable, cacheFlavour : CacheFlavour ) {
        self.cache = cacheFlavour
        self.variable = variable
    }
    
	override init() {
        self.cache = CacheFlavour.noCache
	}
    
    override func setModuleName() {
        self.requestedModule = "org"
    }
    
    internal func getCompanyDetails( _ id : Int64? = nil, completion : @escaping( Result.DataResponse< ZCRMCompanyInfo, APIResponse > ) -> () )
    {
        setIsForceCacheable( true )
        setJSONRootKey( key : JSONRootKey.ORG )
        setUrlPath(urlPath:  "\( URLPathConstants.org )" )
        setRequestMethod(requestMethod: .get)
        
        if let id = id
        {
            addRequestHeader(header: X_CRM_ORG, value: "\( id )")
        }
        
        let request : APIRequest = APIRequest(handler: self, cacheFlavour: self.cache )
        ZCRMLogger.logDebug(message: "Request : \(request.toString())")
        
        request.getAPIResponse { ( resultType ) in
            do
            {
                switch resultType
                {
                case .success(let response) :
                    let responseJSON : [ String :  Any ] = response.responseJSON
                    let companyInfoArray = try responseJSON.getArrayOfDictionaries( key : self.getJSONRootKey() )
                    let companyInfo = try self.getZCRMCompanyInfo(companyDetails: companyInfoArray[ 0 ])
                    companyInfo.upsertJSON = [ String : Any? ]()
                    response.setData( data : companyInfo )
                    completion( .success( companyInfo, response ) )
                case .failure(let error) :
                    ZCRMLogger.logError( message : "\( error )" )
                    completion( .failure( typeCastToZCRMError( error ) ) )
                }
            }
            catch{
                ZCRMLogger.logError( message : "\( error )" )
                completion( .failure( typeCastToZCRMError( error ) ) )
            }
        }
    }
    
    internal func createVariables( variables : [ZCRMVariable], completion : @escaping( Result.DataResponse< [ZCRMVariable], BulkAPIResponse > ) -> () )
    {
        setJSONRootKey(key: JSONRootKey.VARIABLES)
        setUrlPath(urlPath: "\( URLPathConstants.settings )/\( URLPathConstants.variables )")
        setRequestMethod(requestMethod: .post)
        
        var reqBodyObj : [String:[[String:Any?]]] = [String:[[String:Any?]]]()
        var dataArray : [[String:Any?]] = [[String:Any?]]()
        for variable in variables
        {
            if variable.isCreate
            {
                dataArray.append( getZCRMVariableAsJSON( variable: variable ) )
            }
        }
        reqBodyObj[getJSONRootKey()] = dataArray
        
        setRequestBody(requestBody: reqBodyObj)
        let request : APIRequest = APIRequest(handler: self)
        ZCRMLogger.logDebug(message: "Request : \(request.toString())")
        
        request.getBulkAPIResponse { ( resultType ) in
            do{
                let bulkResponse = try resultType.resolve()
                let responses : [EntityResponse] = bulkResponse.getEntityResponses()
                var createdVariables : [ZCRMVariable] = variables
                for index in 0..<responses.count
                {
                    let entityResponse = responses[ index ]
                    if  APIConstants.CODE_SUCCESS == entityResponse.getStatus()
                    {
                        let entResponseJSON : [String:Any] = entityResponse.getResponseJSON()
                        let variableJSON : [ String : Any ] = try entResponseJSON.getDictionary( key : APIConstants.DETAILS )
                        if variableJSON.isEmpty == true
                        {
                            ZCRMLogger.logError(message: "\(ErrorCode.responseNil) : \(ErrorMessage.responseJSONNilMsg), \( APIConstants.DETAILS ) : -")
                            completion( .failure( ZCRMError.processingError( code: ErrorCode.responseNil, message: ErrorMessage.responseJSONNilMsg, details : nil ) ) )
                            return
                        }
                        createdVariables[ index ] = try self.getZCRMVariable(variable: createdVariables[ index ], variableJSON: variableJSON)
                        entityResponse.setData(data: createdVariables[ index ])
                    }
                    else
                    {
                        entityResponse.setData(data: nil)
                    }
                }
                bulkResponse.setData(data: createdVariables)
                completion( .success( createdVariables, bulkResponse ) )
            }
            catch{
                ZCRMLogger.logError( message : "\( error )" )
                completion( .failure( typeCastToZCRMError( error ) ) )
            }
        }
    }
    
    internal func createVariable( completion : @escaping( Result.DataResponse< ZCRMVariable, APIResponse > ) -> () )
    {
        if let variable = self.variable
        {
            if !variable.isCreate
            {
                ZCRMLogger.logError(message: "\(ErrorCode.invalidData) : VARIABLE ID must be nil, \( APIConstants.DETAILS ) : -")
                completion( .failure( ZCRMError.processingError( code: ErrorCode.invalidData, message: "VARIABLE ID must be nil", details : nil ) ) )
                return
            }
            setJSONRootKey(key: JSONRootKey.VARIABLES)
            setUrlPath(urlPath: "\( URLPathConstants.settings )/\( URLPathConstants.variables )")
            setRequestMethod(requestMethod: .post)
            
            var reqBodyObj : [ String : [ [ String : Any? ] ] ] = [ String : [ [ String : Any? ] ] ]()
            var dataArray : [ [ String : Any? ] ] = [ [ String : Any? ] ]()
            dataArray.append( getZCRMVariableAsJSON( variable: variable ) )
            reqBodyObj[getJSONRootKey()] = dataArray
            
            setRequestBody(requestBody: reqBodyObj)
            let request : APIRequest = APIRequest(handler: self)
            ZCRMLogger.logDebug(message: "Request : \(request.toString())")
            
            request.getAPIResponse { ( resultType ) in
                do{
                    let response = try resultType.resolve()
                    let responseJSON = response.getResponseJSON()
                    let respDataArr : [ [ String : Any? ] ] = try responseJSON.getArrayOfDictionaries( key : self.getJSONRootKey() )
                    let respData : [String:Any?] = respDataArr[0]
                    let variableJSON : [ String : Any ] = try respData.getDictionary( key : APIConstants.DETAILS )
                    let createdVariable : ZCRMVariable = try self.getZCRMVariable(variable: variable, variableJSON: variableJSON)
                    createdVariable.isCreate = false
                    response.setData(data: createdVariable )
                    completion( .success( createdVariable, response ) )
                }
                catch{
                    ZCRMLogger.logError( message : "\( error )" )
                    completion( .failure( typeCastToZCRMError( error ) ) )
                }
            }
        }
        else
        {
            ZCRMLogger.logError(message: "\(ErrorCode.mandatoryNotFound) : VARIABLE must not be nil, \( APIConstants.DETAILS ) : -")
            completion( .failure( ZCRMError.processingError( code: ErrorCode.mandatoryNotFound, message: "VARIABLE must not be nil", details : nil ) ) )
        }
    }
    
    internal func updateVariables( variables : [ZCRMVariable], completion : @escaping( Result.DataResponse< [ZCRMVariable], BulkAPIResponse > ) -> () )
    {
        setJSONRootKey(key: JSONRootKey.VARIABLES)
        setUrlPath(urlPath: "\( URLPathConstants.settings )/\( URLPathConstants.variables )")
        setRequestMethod(requestMethod: .put)
        
        var reqBodyObj : [ String : [ [ String : Any? ] ] ] = [ String : [ [ String : Any? ] ] ]()
        var dataArray : [ [ String : Any? ] ] = [ [ String : Any? ] ]()
        for variable in variables
        {
             if !variable.isCreate
            {
                dataArray.append( getZCRMVariableAsJSON( variable: variable ) )
            }
        }
        reqBodyObj[getJSONRootKey()] = dataArray
        
        setRequestBody(requestBody: reqBodyObj)
        let request : APIRequest = APIRequest(handler: self)
        ZCRMLogger.logDebug(message: "Request : \(request.toString())")
        
        request.getBulkAPIResponse { ( resultType ) in
            do{
                let bulkResponse = try resultType.resolve()
                let responses : [EntityResponse] = bulkResponse.getEntityResponses()
                var createdVariables : [ZCRMVariable] = variables
                for index in 0..<responses.count
                {
                    let entityResponse = responses[ index ]
                    if  APIConstants.CODE_SUCCESS == entityResponse.getStatus()
                    {
                        let entResponseJSON : [String:Any] = entityResponse.getResponseJSON()
                        let variableJSON : [ String : Any ] = try entResponseJSON.getDictionary( key : APIConstants.DETAILS )
                        if variableJSON.isEmpty == true
                        {
                            ZCRMLogger.logError(message: "\(ErrorCode.responseNil) : \(ErrorMessage.responseJSONNilMsg), \( APIConstants.DETAILS ) : -")
                            completion( .failure( ZCRMError.processingError( code: ErrorCode.responseNil, message: ErrorMessage.responseJSONNilMsg, details : nil ) ) )
                            return
                        }
                        createdVariables[ index ] = try self.getZCRMVariable(variable: createdVariables[ index ], variableJSON: variableJSON)
                        entityResponse.setData(data: createdVariables[ index ])
                    }
                    else
                    {
                        entityResponse.setData(data: nil)
                    }
                }
                bulkResponse.setData(data: createdVariables)
                completion( .success( createdVariables, bulkResponse ) )
            }
            catch{
                ZCRMLogger.logError( message : "\( error )" )
                completion( .failure( typeCastToZCRMError( error ) ) )
            }
        }
    }
    
    internal func updateVariable( completion : @escaping( Result.DataResponse< ZCRMVariable, APIResponse > ) -> () )
    {
        if let variable = self.variable
        {
            if variable.isCreate
            {
                ZCRMLogger.logError(message: "\(ErrorCode.invalidData) : VARIABLE ID must not be nil, \( APIConstants.DETAILS ) : -")
                completion( .failure( ZCRMError.processingError( code: ErrorCode.mandatoryNotFound, message: "VARIABLE ID must not be nil", details : nil ) ) )
                return
            }
            setJSONRootKey(key: JSONRootKey.VARIABLES)
            setUrlPath(urlPath: "\( URLPathConstants.settings )/\( URLPathConstants.variables )")
            setRequestMethod(requestMethod: .put)
            
            var reqBodyObj : [ String : [ [ String : Any? ] ] ] = [ String : [ [ String : Any? ] ] ]()
            var dataArray : [ [ String : Any? ] ] = [ [ String : Any? ] ]()
            dataArray.append( getZCRMVariableAsJSON( variable: variable ) )
            reqBodyObj[getJSONRootKey()] = dataArray

            setRequestBody(requestBody: reqBodyObj)
            let request : APIRequest = APIRequest(handler: self)
            ZCRMLogger.logDebug(message: "Request : \(request.toString())")
            
            request.getAPIResponse { ( resultType ) in
                do{
                    let response = try resultType.resolve()
                    let responseJSON = response.getResponseJSON()
                    let respDataArr : [ [ String : Any? ] ] = try responseJSON.getArrayOfDictionaries( key : self.getJSONRootKey() )
                    let respData : [String:Any?] = respDataArr[0]
                    let variableJSON : [ String : Any ] = try respData.getDictionary( key : APIConstants.DETAILS )
                    let updatedVariable : ZCRMVariable = try self.getZCRMVariable(variable: variable, variableJSON: variableJSON)
                    response.setData(data: updatedVariable )
                    completion( .success( updatedVariable, response ) )
                }
                catch{
                    ZCRMLogger.logError( message : "\( error )" )
                    completion( .failure( typeCastToZCRMError( error ) ) )
                }
            }
        }
        else
        {
            ZCRMLogger.logError(message: "\(ErrorCode.mandatoryNotFound) : VARIABLE must not be nil, \( APIConstants.DETAILS ) : -")
            completion( .failure( ZCRMError.processingError( code: ErrorCode.mandatoryNotFound, message: "VARIABLE must not be nil", details : nil ) ) )
        }
    }
    
    internal func getVariableGroups( completion : @escaping( Result.DataResponse< [ZCRMVariableGroup], BulkAPIResponse > ) -> () )
    {
        var variableGroups : [ZCRMVariableGroup] = [ZCRMVariableGroup]()
        setJSONRootKey(key: JSONRootKey.VARIABLE_GROUPS)
        setUrlPath(urlPath: "\( URLPathConstants.settings )/\( URLPathConstants.variableGroups )")
        setRequestMethod(requestMethod: .get)
        let request : APIRequest = APIRequest(handler: self)
        ZCRMLogger.logDebug(message: "Request : \(request.toString())")
        
        request.getBulkAPIResponse { ( resultType ) in
            do{
                let bulkResponse = try resultType.resolve()
                let responseJSON = bulkResponse.getResponseJSON()
                if responseJSON.isEmpty == false
                {
                    let variableGroupsList :[ [ String : Any ] ] = try responseJSON.getArrayOfDictionaries( key : self.getJSONRootKey() )
                    if( variableGroupsList.isEmpty == true )
                    {
                        ZCRMLogger.logError(message: "\(ErrorCode.responseNil) : \(ErrorMessage.responseJSONNilMsg), \( APIConstants.DETAILS ) : -")
                        completion( .failure( ZCRMError.sdkError( code: ErrorCode.responseNil, message: ErrorMessage.responseJSONNilMsg, details : nil ) ) )
                        return
                    }
                    for variableGroupList in variableGroupsList
                    {
                        variableGroups.append(try self.getZCRMVariableGroup(variableGroupJSON: variableGroupList))
                    }
                }
                bulkResponse.setData(data: variableGroups)
                completion( .success( variableGroups, bulkResponse ) )
            }
            catch{
                ZCRMLogger.logError( message : "\( error )" )
                completion( .failure( typeCastToZCRMError( error ) ) )
            }
        }
    }
    
    internal func getVariableGroup( id : Int64?, apiName : String?, completion : @escaping( Result.DataResponse< ZCRMVariableGroup, APIResponse > ) -> () )
    {
        setJSONRootKey(key: JSONRootKey.VARIABLE_GROUPS)
        if let id = id
        {
            setUrlPath(urlPath: "\( URLPathConstants.settings )/\( URLPathConstants.variableGroups )/\( id )")
        }
        else if let apiName = apiName
        {
            setUrlPath(urlPath: "\( URLPathConstants.settings )/\( URLPathConstants.variableGroups )/\(apiName)")
        }
        setRequestMethod(requestMethod: .get)
        let request : APIRequest = APIRequest(handler: self)
        ZCRMLogger.logDebug(message: "Request : \(request.toString())")
        
        request.getAPIResponse { ( resultType ) in
            do
            {
                let response = try resultType.resolve()
                let responseJSON : [String:Any] = response.getResponseJSON()
                let responseDataArray : [ [ String : Any ] ] = try responseJSON.getArrayOfDictionaries( key : self.getJSONRootKey() )
                let variableGroup : ZCRMVariableGroup = try self.getZCRMVariableGroup(variableGroupJSON: responseDataArray[0])
                response.setData(data: variableGroup)
                completion( .success( variableGroup, response ))
            }
            catch
            {
                ZCRMLogger.logError( message : "\( error )" )
                completion( .failure( typeCastToZCRMError( error ) ) )
            }
        }
    }
    
    internal func getVariables( completion : @escaping( Result.DataResponse< [ZCRMVariable], BulkAPIResponse > ) -> () )
    {
        var variables : [ZCRMVariable] = [ZCRMVariable]()
        setJSONRootKey(key: JSONRootKey.VARIABLES)
        setUrlPath(urlPath: "\( URLPathConstants.settings )/\( URLPathConstants.variables )")
        setRequestMethod(requestMethod: .get)
        let request : APIRequest = APIRequest(handler: self)
        ZCRMLogger.logDebug(message: "Request : \(request.toString())")
        
        request.getBulkAPIResponse { ( resultType ) in
            do{
                let bulkResponse = try resultType.resolve()
                let responseJSON = bulkResponse.getResponseJSON()
                if responseJSON.isEmpty == false
                {
                    let variablesList : [ [ String : Any ] ] = try responseJSON.getArrayOfDictionaries( key : self.getJSONRootKey() )
                    if( variablesList.isEmpty == true )
                    {
                        ZCRMLogger.logError(message: "\(ErrorCode.responseNil) : \(ErrorMessage.responseJSONNilMsg), \( APIConstants.DETAILS ) : -")
                        completion( .failure( ZCRMError.sdkError( code: ErrorCode.responseNil, message: ErrorMessage.responseJSONNilMsg, details : nil ) ) )
                        return
                    }
                    for variableList in variablesList
                    {
                        let variable : ZCRMVariable = ZCRMVariable( id : try variableList.getInt64( key : ResponseJSONKeys.id ) )
                        variables.append(try self.getZCRMVariable(variable: variable, variableJSON: variableList))
                    }
                }
                bulkResponse.setData(data: variables)
                completion( .success( variables, bulkResponse ) )
            }
            catch{
                ZCRMLogger.logError( message : "\( error )" )
                completion( .failure( typeCastToZCRMError( error ) ) )
            }
        }
    }
    
    internal func getVariable( variableId : Int64?, variableAPIName : String?, variableGroupId : Int64?, variableGroupAPIName : String?, completion : @escaping( Result.DataResponse< ZCRMVariable, APIResponse > ) -> () )
    {
        setJSONRootKey(key: JSONRootKey.VARIABLES)
        if let variableId = variableId
        {
            setUrlPath(urlPath: "\( URLPathConstants.settings )/\( URLPathConstants.variables )/\( variableId )")
        }
        else if let variableAPIName = variableAPIName
        {
            setUrlPath(urlPath: "\( URLPathConstants.settings )/\( URLPathConstants.variables )/\(variableAPIName)")
        }
        if let variableGroupId = variableGroupId
        {
            addRequestParam( param : RequestParamKeys.group, value : String( variableGroupId ) )
        }
        else if let variableGroupAPIName = variableGroupAPIName
        {
            addRequestParam( param : RequestParamKeys.group, value : variableGroupAPIName )
        }
        setRequestMethod(requestMethod : .get)
        let request : APIRequest = APIRequest(handler: self)
        ZCRMLogger.logDebug(message: "Request : \(request.toString())")
        
        request.getAPIResponse { ( resultType ) in
            do
            {
                let response = try resultType.resolve()
                let responseJSON : [String:Any] = response.getResponseJSON()
                let responseDataArray : [ [ String : Any ] ] = try responseJSON.getArrayOfDictionaries( key : self.getJSONRootKey() )
                var variable : ZCRMVariable = ZCRMVariable( id : try responseDataArray[ 0 ].getInt64( key : ResponseJSONKeys.id ) )
                variable = try self.getZCRMVariable(variable: variable, variableJSON: responseDataArray[0])
                response.setData(data: variable)
                completion( .success( variable, response ))
            }
            catch
            {
                ZCRMLogger.logError( message : "\( error )" )
                completion( .failure( typeCastToZCRMError( error ) ) )
            }
        }
    }

    internal func deleteVariables( ids : [Int64], completion : @escaping( Result.Response< BulkAPIResponse > ) -> () )
    {
        setUrlPath(urlPath: "\( URLPathConstants.settings )/\( URLPathConstants.variables )")
        setJSONRootKey(key: JSONRootKey.VARIABLES)
        setRequestMethod(requestMethod: .delete)
        addRequestParam( param : RequestParamKeys.ids, value : ids.map{ String( $0 ) }.joined(separator: ",") )
        let request : APIRequest = APIRequest(handler: self)
        ZCRMLogger.logDebug(message: "Request : \(request.toString())")
        
        request.getBulkAPIResponse { ( resultType ) in
            do{
                let response = try resultType.resolve()
                completion( .success( response ) )
            }
            catch{
                ZCRMLogger.logError( message : "\( error )" )
                completion( .failure( typeCastToZCRMError( error ) ) )
            }
        }
    }
    
    internal func deleteVariable( id : Int64, completion : @escaping( Result.Response< APIResponse > ) -> () )
    {
        setJSONRootKey(key: JSONRootKey.VARIABLES)
        setUrlPath(urlPath: "\( URLPathConstants.settings )/\( URLPathConstants.variables )/\( id )")
        setRequestMethod(requestMethod: .delete)
        let request : APIRequest = APIRequest(handler: self)
        ZCRMLogger.logDebug(message: "Request : \(request.toString())")
        
        request.getAPIResponse { ( resultType ) in
            do{
                let response = try resultType.resolve()
                completion( .success( response ) )
            }
            catch{
                ZCRMLogger.logError( message : "\( error )" )
                completion( .failure( typeCastToZCRMError( error ) ) )
            }
        }
    }
    
    internal func update( companyInfo : ZCRMCompanyInfo, completion : @escaping( Result.DataResponse< ZCRMCompanyInfo, APIResponse > ) -> () )
    {
        if !companyInfo.upsertJSON.isEmpty
        {
            setJSONRootKey( key : JSONRootKey.ORG )
            setRequestMethod( requestMethod : .patch )
            setUrlPath( urlPath : "\( URLPathConstants.org )" )
            var reqBodyObj : [ String : [ [ String : Any? ] ] ] = [ String : [ [ String : Any? ] ] ]()
            var dataArray : [ [ String : Any? ] ] = [ [ String : Any? ] ]()
            dataArray.append( companyInfo.upsertJSON )
            reqBodyObj[ getJSONRootKey() ] = dataArray
            setRequestBody( requestBody : reqBodyObj )
            let request = APIRequest( handler : self )
            ZCRMLogger.logDebug(message: "Request : \(request.toString())")
            
            request.getAPIResponse { ( resultType ) in
                switch resultType
                {
                case .success(let response) :
                    companyInfo.upsertJSON = [ String : Any? ]()
                    completion( .success( companyInfo, response ) )
                case .failure(let error) :
                    ZCRMLogger.logError( message : "\( error )" )
                    completion( .failure( typeCastToZCRMError( error ) ) )
                }
            }
        }
        else
        {
            ZCRMLogger.logError(message: "\(ErrorCode.notModified) : No changes have been made on the company details to update, \( APIConstants.DETAILS ) : -")
            completion( .failure( ZCRMError.sdkError( code: ErrorCode.notModified, message: "No changes have been made on the company details to update", details : nil ) ) )
        }
    }
    
    internal func getCurrencies( completion : @escaping( Result.DataResponse< [ ZCRMCurrency ], BulkAPIResponse > ) -> () )
    {
        setIsCacheable( true )
        setJSONRootKey( key : JSONRootKey.CURRENCIES )
        setUrlPath( urlPath : "\( URLPathConstants.org )/\( URLPathConstants.currencies )" )
        setRequestMethod( requestMethod : .get )
        let request : APIRequest = APIRequest( handler : self, cacheFlavour : self.cache )
        ZCRMLogger.logDebug( message : "Request : \( request.toString() )" )
        
        request.getBulkAPIResponse { ( resultType ) in
            do
            {
                let bulkResponse = try resultType.resolve()
                let responseJSON = bulkResponse.getResponseJSON()
                var currencies : [ ZCRMCurrency ] = [ ZCRMCurrency ]()
                if responseJSON.isEmpty == false
                {
                    let currenciesList : [ [ String : Any ] ] = try responseJSON.getArrayOfDictionaries( key : self.getJSONRootKey() )
                    if currenciesList.isEmpty == true
                    {
                        ZCRMLogger.logError( message : "\( ErrorCode.responseNil ) : \( ErrorMessage.responseJSONNilMsg )" )
                        completion( .failure( ZCRMError.sdkError( code : ErrorCode.responseNil, message : ErrorMessage.responseJSONNilMsg, details : nil ) ) )
                        return
                    }
                    currencies = try self.getAllZCRMCurrencies( currenciesDetails : currenciesList )
                }
                bulkResponse.setData( data : currencies )
                completion( .success( currencies, bulkResponse ) )
            }
            catch
            {
                ZCRMLogger.logError( message : "\( error )" )
                completion( .failure( typeCastToZCRMError( error ) ) )
            }
        }
    }
    
    internal func getCurrency( byId id : Int64, completion : @escaping( Result.DataResponse< ZCRMCurrency, APIResponse > ) -> () )
    {
        setIsCacheable( true )
        setJSONRootKey( key : JSONRootKey.CURRENCIES )
        setUrlPath( urlPath : "\( URLPathConstants.org )/\( URLPathConstants.currencies )/\( id )" )
        setRequestMethod( requestMethod : .get )
        let request : APIRequest = APIRequest( handler : self, cacheFlavour : self.cache )
        ZCRMLogger.logDebug( message : "Request : \( request.toString() )" )
        
        request.getAPIResponse { ( resultType ) in
            do
            {
                switch resultType
                {
                case .success(let response) :
                    let responseJSON = response.getResponseJSON()
                    let responseArray = try responseJSON.getArrayOfDictionaries(key: self.getJSONRootKey())
                    if responseArray.isEmpty
                    {
                        ZCRMLogger.logError( message : "\( ErrorCode.responseNil ) : \( ErrorMessage.responseJSONNilMsg )" )
                        completion( .failure( ZCRMError.sdkError( code : ErrorCode.responseNil, message : ErrorMessage.responseJSONNilMsg, details : nil ) ) )
                        return
                    }
                    let currency = try self.getZCRMCurrency(currencyDetails: responseArray[0])
                    response.setData( data : currency )
                    completion( .success( currency, response ) )
                case .failure(let error) :
                    ZCRMLogger.logError( message : "\( error )" )
                    completion( .failure( typeCastToZCRMError( error ) ) )
                }
            }
            catch
            {
                ZCRMLogger.logError( message : "\( error )" )
                completion( .failure( typeCastToZCRMError( error ) ) )
            }
        }
    }
    
    internal func getBaseCurrency( completion : @escaping( Result.Data< ZCRMCurrency > ) -> () )
    {
        self.getCurrencies { ( result ) in
            do
            {
                let resp = try result.resolve()
                let currencies = resp.data
                var baseCurrency : ZCRMCurrency?
                if !currencies.isEmpty {
                    for currency in currencies
                    {
                        if currency.isBase
                        {
                            baseCurrency = currency
                        }
                    }
                    if let baseCurrency = baseCurrency
                    {
                        completion( .success( baseCurrency ) )
                    }
                    else
                    {
                        currencies[0].isBase = true
                        completion( .success( currencies[0] ) )
                    }
                } else {
                    ZCRMLogger.logError( message : "\( ErrorCode.invalidData ) : BASE CURRENCY not found" )
                    completion( .failure( ZCRMError.inValidError( code : ErrorCode.invalidData, message : "BASE CURRENCY not found", details : nil) ) )
                }
            }
            catch
            {
                ZCRMLogger.logError( message : "\( error )" )
                completion( .failure( typeCastToZCRMError( error ) ) )
            }
        }
    }
    
    internal func uploadPhoto( filePath : String?, fileName : String?, fileData : Data?, completion : @escaping(  Result.Response< APIResponse > ) -> () )
    {
        do
        {
            try fileDetailCheck( filePath : filePath, fileData : fileData, maxFileSize: MaxFileSize.profilePhoto )
            try imageTypeValidation( filePath )
        }
        catch
        {
            ZCRMLogger.logError( message : "\( error )" )
            completion( .failure( typeCastToZCRMError( error ) ) )
            return
        }
        setJSONRootKey( key : JSONRootKey.NIL )
        setUrlPath(urlPath: "\( URLPathConstants.org )/\( URLPathConstants.photo )")
        setRequestMethod(requestMethod: .post)
        let request : FileAPIRequest = FileAPIRequest(handler: self)
        ZCRMLogger.logDebug(message: "Request : \(request.toString())")
        
        if let filePath = filePath
        {
            request.uploadFile( filePath : filePath, entity : nil ) { ( resultType ) in
                do
                {
                    let response = try resultType.resolve()
                    completion( .success( response ) )
                }
                catch
                {
                    ZCRMLogger.logError( message : "\( error )" )
                    completion( .failure( typeCastToZCRMError( error ) ) )
                }
            }
        }
        else if let fileName = fileName, let fileData = fileData
        {
            request.uploadFile( fileName : fileName, entity : nil, fileData : fileData ){ ( resultType ) in
                do
                {
                    let response = try resultType.resolve()
                    completion( .success( response ) )
                }
                catch
                {
                    ZCRMLogger.logError( message : "\( error )" )
                    completion( .failure( typeCastToZCRMError( error ) ) )
                }
            }
        }
    }

    internal func downloadPhoto( withOrgID id : Int64?, completion : @escaping (Result.Response< FileAPIResponse >) -> ())
    {
        setJSONRootKey( key : JSONRootKey.NIL )
        setUrlPath(urlPath: "\( URLPathConstants.org )/\( URLPathConstants.photo )")
        setRequestMethod(requestMethod: .get)
        
        if let orgId = id
        {
            addRequestHeader(header: X_CRM_ORG, value: "\( orgId )")
        }
        
        let request : FileAPIRequest = FileAPIRequest(handler: self)
        ZCRMLogger.logDebug(message: "Request : \(request.toString())")
        
        request.downloadFile { ( resultType ) in
            switch resultType
            {
            case .success(let response) :
                completion( .success( response ) )
            case .failure(let error) :
                ZCRMLogger.logError( message : "\( error )" )
                completion( .failure( typeCastToZCRMError( error ) ) )
            }
        }
    }
    
    internal func getZCRMTerritories( completion : @escaping ( Result.DataResponse< [ ZCRMTerritory ], BulkAPIResponse > ) -> () )
    {
        setJSONRootKey( key : JSONRootKey.TERRITORIES )
        setUrlPath(urlPath: "\( URLPathConstants.settings )/\( JSONRootKey.TERRITORIES )")
        setRequestMethod( requestMethod : .get )
        
        let request = APIRequest( handler : self )
        ZCRMLogger.logDebug(message: "Request : \(request.toString())")
        
        request.getBulkAPIResponse() { response in
            do
            {
                switch response
                {
                case .success(let bulkResponse) :
                    let responseJSON = bulkResponse.getResponseJSON()
                    var territories : [ ZCRMTerritory ] = []
                    if responseJSON.isEmpty == false
                    {
                        let territoriesList = try responseJSON.getArrayOfDictionaries( key: JSONRootKey.TERRITORIES )
                        if territoriesList.isEmpty == true
                        {
                            ZCRMLogger.logError(message: "\(ErrorCode.responseNil) : \(ErrorMessage.responseJSONNilMsg), \( APIConstants.DETAILS ) : -")
                            completion( .failure( ZCRMError.sdkError( code: ErrorCode.responseNil, message: ErrorMessage.responseJSONNilMsg, details : nil ) ) )
                            return
                        }
                        territories = try self.getZCRMTerritoriesFrom( territoriesList )
                    }
                    bulkResponse.setData(data: territories)
                    completion( .success( territories, bulkResponse ) )
                case .failure(let error) :
                    ZCRMLogger.logError( message : "\( error )" )
                    completion( .failure( typeCastToZCRMError( error ) ) )
                }
            }
            catch
            {
                ZCRMLogger.logError( message : "\( error )" )
                completion( .failure( typeCastToZCRMError( error ) ) )
            }
        }
    }
    
    internal func getZCRMTerritory( byId id : Int64, completion : @escaping ( Result.DataResponse< ZCRMTerritory, APIResponse > ) -> () )
    {
        setJSONRootKey( key : JSONRootKey.TERRITORIES )
        setUrlPath(urlPath: "\( URLPathConstants.settings )/\( JSONRootKey.TERRITORIES )/\( id )")
        setRequestMethod( requestMethod : .get )
        
        let request = APIRequest( handler : self )
        ZCRMLogger.logDebug(message: "Request : \(request.toString())")
        
        request.getAPIResponse() { response in
            do
            {
                switch response
                {
                case .success(let response) :
                    let responseJSON = response.getResponseJSON()
                    
                    let territoriesList = try responseJSON.getArrayOfDictionaries( key: JSONRootKey.TERRITORIES )
                    if territoriesList.isEmpty == true
                    {
                        ZCRMLogger.logError(message: "\(ErrorCode.responseNil) : \(ErrorMessage.responseJSONNilMsg), \( APIConstants.DETAILS ) : -")
                        completion( .failure( ZCRMError.sdkError( code: ErrorCode.responseNil, message: ErrorMessage.responseJSONNilMsg, details : nil ) ) )
                        return
                    }
                    let territory = try self.getZCRMTerritoriesFrom( territoriesList )[0]
                    response.setData(data: territory)
                    completion( .success( territory, response))
                case .failure(let error) :
                    ZCRMLogger.logError( message : "\( error )" )
                    completion( .failure( typeCastToZCRMError( error ) ) )
                }
            }
            catch
            {
                ZCRMLogger.logError( message : "\( error )" )
                completion( .failure( typeCastToZCRMError( error ) ) )
            }
        }
    }
    
    internal func enableMultiCurrency( _ currency : ZCRMCurrency, completion : @escaping ( Result.DataResponse< ZCRMCurrency, APIResponse > ) -> () )
    {
        setJSONRootKey(key: JSONRootKey.BASE_CURRENCY)
        setUrlPath(urlPath: "\( URLPathConstants.org )/\( URLPathConstants.currencies )/\( URLPathConstants.actions )/\( URLPathConstants.enable )")
        setRequestMethod(requestMethod: .post)
        
        var requestBody : [ String : Any ] = [:]
        var dataArray : [ String : Any? ]
        do
        {
            dataArray = try self.getZCRMCurrencyAsJSON(currency: currency)
        }
        catch
        {
            completion( .failure( typeCastToZCRMError( error ) ))
            return
        }
        requestBody[ getJSONRootKey() ] = dataArray
        setRequestBody(requestBody: requestBody)
        
        let request = APIRequest( handler: self )
        ZCRMLogger.logDebug(message: "Request : \( request.toString() )")
        
        request.getAPIResponse() { result in
            do
            {
                switch result
                {
                case .success( let response ) :
                    let responseJSON = response.getResponseJSON()
                    let responseData = try responseJSON.getDictionary( key: self.getJSONRootKey() )
                    let details = try responseData.getDictionary(key: APIConstants.DETAILS )
                    currency.id = try details.getInt64( key: ResponseJSONKeys.id )
                    
                    response.setData( data: currency )
                    completion( .success( currency, response ))
                case .failure( let error ) :
                    ZCRMLogger.logError( message : "\( error )" )
                    completion( .failure( typeCastToZCRMError( error ) ) )
                }
            }
            catch
            {
                ZCRMLogger.logError( message : "\( error )" )
                completion( .failure( typeCastToZCRMError( error ) ) )
            }
        }
    }
    
    internal func addCurrency( _ currency : ZCRMCurrency, completion : @escaping ( Result.DataResponse< ZCRMCurrency, APIResponse > ) -> () )
    {
        setJSONRootKey(key: JSONRootKey.CURRENCIES)
        setUrlPath(urlPath: "\( URLPathConstants.org )/\( URLPathConstants.currencies )")
        setRequestMethod(requestMethod: .post)
        
        var requestBody : [ String : Any ] = [:]
        var dataArray : [[ String : Any? ]] = []
        
        do
        {
            try dataArray.append( self.getZCRMCurrencyAsJSON(currency: currency) )
        }
        catch
        {
            completion( .failure( typeCastToZCRMError( error ) ) )
            return
        }
        requestBody[ getJSONRootKey() ] = dataArray
        setRequestBody(requestBody: requestBody)
        
        let request = APIRequest(handler: self)
        ZCRMLogger.logInfo(message: "Request : \( request.toString() )")
        
        request.getAPIResponse() { result in
            do
            {
                switch result
                {
                case .success(let response) :
                    let responseJSON = response.getResponseJSON()
                    let responseArray = try responseJSON.getArrayOfDictionaries(key: self.getJSONRootKey())
                    if responseArray.isEmpty
                    {
                        ZCRMLogger.logError(message: "\(ErrorCode.responseNil) : \(ErrorMessage.responseJSONNilMsg), \( APIConstants.DETAILS ) : -")
                        completion( .failure( ZCRMError.sdkError( code: ErrorCode.responseNil, message: ErrorMessage.responseJSONNilMsg, details : nil ) ) )
                        return
                    }
                    let respData : [ String : Any ] = responseArray[0]
                    let details = try respData.getDictionary(key: APIConstants.DETAILS)
                    currency.id = try details.getInt64(key: ResponseJSONKeys.id)
                    
                    response.setData(data: currency)
                    completion( .success( currency, response ) )
                case .failure(let error) :
                    ZCRMLogger.logError( message : "\( error )" )
                    completion( .failure( typeCastToZCRMError( error ) ) )
                }
            }
            catch
            {
                ZCRMLogger.logError( message : "\( error )" )
                completion( .failure( typeCastToZCRMError( error ) ) )
            }
        }
    }
    
    internal func addCurrencies( _ currencies : [ ZCRMCurrency ], completion : @escaping ( Result.DataResponse< [ ZCRMCurrency ], BulkAPIResponse > ) -> () )
    {
        setJSONRootKey(key: JSONRootKey.CURRENCIES)
        setUrlPath(urlPath: "\( URLPathConstants.org )/\( URLPathConstants.currencies )")
        setRequestMethod(requestMethod: .post)
        
        var requestBody : [ String : Any ] = [:]
        var dataArray : [[ String : Any? ]] = []
        
        for currency in currencies
        {
            do
            {
                try dataArray.append( self.getZCRMCurrencyAsJSON(currency: currency) )
            }
            catch
            {
                completion( .failure( typeCastToZCRMError( error ) ) )
                return
            }
        }
        requestBody[ getJSONRootKey() ] = dataArray
        setRequestBody(requestBody: requestBody)
        
        let request = APIRequest(handler: self)
        ZCRMLogger.logDebug(message: "Request : \( request.toString() )")
        
        request.getBulkAPIResponse() { result in
            do
            {
                switch result
                {
                case .success(let bulkResponse) :
                    let responses : [ EntityResponse ] = bulkResponse.getEntityResponses()
                    var addedCurrencies : [ ZCRMCurrency ] = []
                    for ( index , entityResponse ) in responses.enumerated()
                    {
                        if APIConstants.CODE_SUCCESS == entityResponse.getStatus()
                        {
                            let responseJSON = entityResponse.getResponseJSON()
                            let details = try responseJSON.getDictionary(key: APIConstants.DETAILS)
                            currencies[ index ].id = try details.getInt64(key: ResponseJSONKeys.id)
                            addedCurrencies.append( currencies[ index ] )
                            entityResponse.setData(data: currencies[ index ] )
                        }
                        else
                        {
                            entityResponse.setData(data: nil)
                        }
                    }
                    
                    bulkResponse.setData(data: addedCurrencies)
                    completion( .success( addedCurrencies, bulkResponse ) )
                case .failure(let error) :
                    ZCRMLogger.logError( message : "\( error )" )
                    completion( .failure( typeCastToZCRMError( error ) ) )
                }
            }
            catch
            {
                ZCRMLogger.logError( message : "\( error )" )
                completion( .failure( typeCastToZCRMError( error ) ) )
            }
        }
    }
    
    internal func updateBaseCurrency( _ currency : ZCRMCurrency, completion : @escaping ( Result.DataResponse< ZCRMCurrency, APIResponse > ) -> ())
    {
        setJSONRootKey(key: JSONRootKey.BASE_CURRENCY)
        setUrlPath(urlPath: "\( URLPathConstants.org )/\( URLPathConstants.currencies )/\( URLPathConstants.actions )/\( URLPathConstants.enable )")
        setRequestMethod(requestMethod: .patch)
        
        var requestBody : [ String : Any ] = [:]
        do
        {
            requestBody[ getJSONRootKey() ] = try self.getZCRMCurrencyAsJSON(currency: currency)
        }
        catch
        {
            completion( .failure( typeCastToZCRMError( error ) ) )
            return
        }
        setRequestBody(requestBody: requestBody)
        
        let request : APIRequest = APIRequest(handler: self)
        ZCRMLogger.logDebug(message: "Request : \( request.toString() )")
        
        request.getAPIResponse() { result in
            do
            {
                switch result
                {
                case .success(let response) :
                    let responseJSON = response.getResponseJSON()
                    let respData = try responseJSON.getDictionary(key: self.getJSONRootKey())
                    let details = try respData.getDictionary(key: APIConstants.DETAILS)
                    currency.id = try details.getInt64(key: ResponseJSONKeys.id)
                    
                    response.setData(data: currency)
                    completion( .success( currency, response) )
                case .failure(let error) :
                    ZCRMLogger.logError( message : "\( error )" )
                    completion( .failure( typeCastToZCRMError( error ) ) )
                }
            }
            catch
            {
                ZCRMLogger.logError( message : "\( error )" )
                completion( .failure( typeCastToZCRMError( error ) ) )
            }
        }
    }
    
    internal func updateCurrencies( _ currencies : [ ZCRMCurrency ], completion : @escaping ( Result.DataResponse< [ ZCRMCurrency ], BulkAPIResponse > ) -> ())
    {
        setJSONRootKey(key: JSONRootKey.CURRENCIES)
        setUrlPath(urlPath: "\( URLPathConstants.org )/\( URLPathConstants.currencies )")
        setRequestMethod(requestMethod: .patch)
        
        var requestBody : [ String : Any ] = [:]
        var dataArray : [[ String : Any? ]] = []
        
        for currency in currencies
        {
            do
            {
                try dataArray.append( self.getZCRMCurrencyAsJSON(currency: currency) )
            }
            catch
            {
                completion( .failure( typeCastToZCRMError( error ) ) )
                return
            }
        }
        requestBody[ getJSONRootKey() ] = dataArray
        setRequestBody(requestBody: requestBody)
        
        let request = APIRequest(handler: self)
        ZCRMLogger.logDebug(message: "Request : \( request.toString() )")
        
        request.getBulkAPIResponse() { result in
            do
            {
                switch result
                {
                case .success(let bulkResponse) :
                    let entityResponses = bulkResponse.getEntityResponses()
                    var updatedCurrencies : [ ZCRMCurrency ] = []
                    for ( index, entityResponse ) in entityResponses.enumerated()
                    {
                        if APIConstants.CODE_SUCCESS == entityResponse.getStatus()
                        {
                            let responseJSON = entityResponse.getResponseJSON()
                            let details = try responseJSON.getDictionary(key: APIConstants.DETAILS)
                            currencies[ index ].id = try details.getInt64(key: ResponseJSONKeys.id)
                            
                            entityResponse.setData(data: currencies[ index ])
                            updatedCurrencies.append( currencies[ index ] )
                        }
                        else
                        {
                            entityResponse.setData(data: nil)
                        }
                    }
                    
                    bulkResponse.setData(data: updatedCurrencies)
                    completion( .success( updatedCurrencies, bulkResponse) )
                case .failure(let error) :
                    ZCRMLogger.logError( message : "\( error )" )
                    completion( .failure( typeCastToZCRMError( error ) ) )
                }
            }
            catch
            {
                ZCRMLogger.logError( message : "\( error )" )
                completion( .failure( typeCastToZCRMError( error ) ) )
            }
        }
    }
    
    internal func updateCurrency( _ currency : ZCRMCurrency, completion : @escaping ( Result.DataResponse< ZCRMCurrency, APIResponse > ) -> ())
    {
        
        guard let currencyId = currency.id else
        {
            ZCRMLogger.logError(message: "\(ErrorCode.mandatoryNotFound) : Mandatory field not found, \( APIConstants.DETAILS ) : [ \"api_name\" : \"id\" ]")
            completion( .failure( ZCRMError.processingError( code: ErrorCode.mandatoryNotFound, message:
                "Mandatory field not found", details : [ "api_name" : "id" ] ) ) )
            return
        }
        setJSONRootKey(key: JSONRootKey.CURRENCIES)
        setUrlPath(urlPath: "\( URLPathConstants.org )/\( URLPathConstants.currencies )/\( currencyId )")
        setRequestMethod(requestMethod: .patch)
        
        var requestBody : [ String : Any ] = [:]
        var dataArray : [[ String : Any? ]] = []
        do
        {
            try dataArray.append( self.getZCRMCurrencyAsJSON(currency: currency) )
        }
        catch
        {
            completion( .failure( typeCastToZCRMError( error ) ) )
            return
        }
        requestBody[ getJSONRootKey() ] = dataArray
        setRequestBody(requestBody: requestBody)
        
        let request = APIRequest(handler: self)
        ZCRMLogger.logDebug(message: "Request : \( request.toString() )")
        
        request.getAPIResponse() { result in
            do
            {
                switch result
                {
                case .success(let response) :
                    let responseJSON = response.getResponseJSON()
                    let respData = try responseJSON.getArrayOfDictionaries(key: self.getJSONRootKey())
                    if respData.isEmpty == true
                    {
                        ZCRMLogger.logError(message: "\(ErrorCode.responseNil) : \(ErrorMessage.responseJSONNilMsg), \( APIConstants.DETAILS ) : -")
                        completion( .failure( ZCRMError.processingError( code: ErrorCode.responseNil, message: ErrorMessage.responseJSONNilMsg, details : nil ) ) )
                        return
                    }
                    let details = try respData[0].getDictionary(key: APIConstants.DETAILS)
                    currency.id = try details.getInt64(key: ResponseJSONKeys.id)
                    
                    response.setData(data: currency)
                    completion( .success( currency, response) )
                case .failure(let error) :
                    ZCRMLogger.logError( message : "\( error )" )
                    completion( .failure( typeCastToZCRMError( error ) ) )
                }
            }
            catch
            {
                ZCRMLogger.logError( message : "\( error )" )
                completion( .failure( typeCastToZCRMError( error ) ) )
            }
        }
    }
    
    internal func uploadFile( filePath : String?, fileName : String?, fileData : Data?, inline : Bool, completion : @escaping ( Result.DataResponse< String, APIResponse > ) -> ())
    {
        do
        {
            try fileDetailCheck( filePath : filePath, fileData : fileData, maxFileSize: MaxFileSize.notesAttachment )
        }
        catch
        {
            ZCRMLogger.logError( message : "\( error )" )
            completion( .failure( typeCastToZCRMError( error ) ) )
            return
        }
        setJSONRootKey(key: JSONRootKey.DATA)
        setUrlPath(urlPath: "\( URLPathConstants.files )")
        setRequestMethod(requestMethod: .post)
        if inline
        {
            addRequestParam(param: "\( RequestParamKeys.inline )", value: "\( inline )")
        }
        
        let request = FileAPIRequest(handler: self)
        ZCRMLogger.logDebug(message: "Request : \( request.toString() )")
        
        if let filePath = filePath
        {
            request.uploadFile( filePath : filePath, entity : nil, completion: { result in
                do
                {
                    switch result
                    {
                    case .success(let response) :
                        let attachmentId : String = try self.getFileIdFromResponse( response )
                        completion( .success( attachmentId, response ) )
                    case .failure(let error) :
                        ZCRMLogger.logError( message : "\( error )" )
                        completion( .failure( typeCastToZCRMError( error ) ) )
                    }
                }
                catch{
                    ZCRMLogger.logError( message : "\( error )" )
                    completion( .failure( typeCastToZCRMError( error ) ) )
                }
            })
        }
        else  if let fileName = fileName, let fileData = fileData
        {
            request.uploadFile( fileName : fileName, entity : nil, fileData : fileData ) { result in
                do
                {
                    switch result
                    {
                    case .success(let response) :
                        let attachmentId : String = try self.getFileIdFromResponse( response )
                        completion( .success( attachmentId, response ) )
                    case .failure(let error) :
                        ZCRMLogger.logError( message : "\( error )" )
                        completion( .failure( typeCastToZCRMError( error ) ) )
                    }
                }
                catch{
                    ZCRMLogger.logError( message : "\( error )" )
                    completion( .failure( typeCastToZCRMError( error ) ) )
                }
            }
        }
    }
    
    private func getFileIdFromResponse( _ response : APIResponse) throws -> String
    {
        let responseJSON = response.getResponseJSON()
        let responseData = try responseJSON.getArrayOfDictionaries(key: self.getJSONRootKey())
        if responseData.isEmpty
        {
            throw ZCRMError.processingError(code: ErrorCode.responseNil, message: ErrorMessage.responseNilMsg, details: nil)
        }
        let details = try responseData[0].getDictionary(key: APIConstants.DETAILS)
        return try details.getString(key: ResponseJSONKeys.id)
    }
    
    internal func uploadFile( fileRefId : String, filePath : String?, fileName : String?, fileData : Data?, inline : Bool, fileUploadDelegate : ZCRMFileUploadDelegate)
    {
        do
        {
            try fileDetailCheck( filePath : filePath, fileData : fileData, maxFileSize: MaxFileSize.notesAttachment )
        }
        catch
        {
            ZCRMLogger.logError( message : "\( error )" )
            fileUploadDelegate.didFail(fileRefId: fileRefId, typeCastToZCRMError( error ))
            return
        }
        setJSONRootKey(key: JSONRootKey.DATA)
        setUrlPath(urlPath: "\( URLPathConstants.files )")
        setRequestMethod(requestMethod: .post)
        if inline
        {
            addRequestParam(param: "\( RequestParamKeys.inline )", value: "\( inline )")
        }
        
        let request = FileAPIRequest(handler: self, fileUploadDelegate: fileUploadDelegate)
        ZCRMLogger.logDebug(message: "Request : \( request.toString() )")
        
        var orgAPIHandler : OrgAPIHandler? = self
        var fileUploadDelegate : ZCRMFileUploadDelegate? = fileUploadDelegate
        request.uploadFile(fileRefId: fileRefId, filePath: filePath, fileName: fileName, fileData: fileData, entity: nil) { result, response in
            if result
            {
                guard let response = response else {
                    orgAPIHandler = nil
                    return
                }
                do
                {
                    guard let attachmentId = try orgAPIHandler?.getFileIdFromResponse( response ) else { return }
                    fileUploadDelegate?.getAttachmentId( attachmentId, fileRefId: fileRefId )
                }
                catch
                {
                    fileUploadDelegate?.didFail( fileRefId : fileRefId, typeCastToZCRMError( error ) )
                }
            }
            orgAPIHandler = nil
            fileUploadDelegate = nil
        }
    }
    
    internal func downloadFile(byId id : String, completion : @escaping ( Result.Response< FileAPIResponse > ) -> ())
    {
        setUrlPath(urlPath: "\( URLPathConstants.files )")
        addRequestParam(param: "\( RequestParamKeys.id )", value: id)
        setRequestMethod(requestMethod: .get)
        
        let request = FileAPIRequest(handler: self)
        ZCRMLogger.logDebug(message: "Request : \( request.toString() )")
        
        request.downloadFile() { result in
            switch result
            {
            case .success(let fileAPIResponse) :
                completion( .success( fileAPIResponse ) )
            case .failure(let error) :
                ZCRMLogger.logError( message : "\( error )" )
                completion( .failure( typeCastToZCRMError( error ) ) )
            }
        }
    }
    
    internal func downloadFile(byId id : String, fileDownloadDelegate : ZCRMFileDownloadDelegate)
    {
        setUrlPath(urlPath: "\( URLPathConstants.files )")
        addRequestParam(param: "\( RequestParamKeys.id )", value: id)
        setRequestMethod(requestMethod: .get)
        
        let request = FileAPIRequest(handler: self, fileDownloadDelegate: fileDownloadDelegate)
        ZCRMLogger.logDebug(message: "Request : \( request.toString() )")
        
        request.downloadFile(fileRefId: id)
    }
    
    private func getZCRMTerritoriesFrom( _ responseJSON : [ [ String : Any ] ] ) throws -> [ ZCRMTerritory ]
    {
        var territories : [ ZCRMTerritory ] = []
        for territoryJSON in responseJSON
        {
            territories.append( try self.getZCRMTerritory( fromJSON: territoryJSON ) )
        }
        return territories
    }
    
    private func getZCRMTerritory( fromJSON json : [ String : Any ] ) throws -> ZCRMTerritory
    {
        let territory = try ZCRMTerritory( json.getString(key: ResponseJSONKeys.name ) )
        
        territory.id = try json.getInt64(key: ResponseJSONKeys.id )
        
        territory.createdBy = try getUserDelegate(userJSON: json.getDictionary(key: ResponseJSONKeys.createdBy))
        territory.createdTime = try json.getString(key: ResponseJSONKeys.createdTime)
        
        territory.modifiedBy = try getUserDelegate(userJSON: json.getDictionary(key: ResponseJSONKeys.modifiedBy))
        territory.modifiedTime = try json.getString(key: ResponseJSONKeys.modifiedTime)
        
        if json.hasValue(forKey: ResponseJSONKeys.manager)
        {
            let manager = try json.getDictionary(key: ResponseJSONKeys.manager)
            territory.manager = try getUserDelegate(userJSON: manager)
        }
        if let parentId = json.optInt64(key: ResponseJSONKeys.parentId)
        {
            territory.parentId = parentId
        }
        else if let parentDetails = json.optDictionary(key: ResponseJSONKeys.reportingTo)
        {
            territory.parentId = try parentDetails.getInt64(key: ResponseJSONKeys.id)
        }
        if json.hasValue(forKey: ResponseJSONKeys.permissionType)
        {
            territory.permissionType = AccessPermission.getType( rawValue: try json.getString(key: ResponseJSONKeys.permissionType) )
        }
        territory.description = json.optString(key: ResponseJSONKeys.description)
        
        if json.hasValue(forKey: ResponseJSONKeys.criteria)
        {
            if let criteriaJSON = json.optDictionary(key: ResponseJSONKeys.criteria)
            {
                territory.criteria = try CriteriaHandling.setCriteria(criteriaJSON: criteriaJSON)
            }
            else
            {
                territory.criteria = try CriteriaHandling.setCriteria(criteriaArray: json.getArray(key: ResponseJSONKeys.criteria))
            }
        }
        else if json.hasValue(forKey: ResponseJSONKeys.accountRuleCriteria)
        {
            territory.criteria = try CriteriaHandling.setCriteria(criteriaJSON: json.getDictionary(key: ResponseJSONKeys.accountRuleCriteria))
        }
        return territory
    }
    
    private func getZCRMCompanyInfo( companyDetails : [ String : Any ] ) throws -> ZCRMCompanyInfo
    {
        let companyInfo : ZCRMCompanyInfo = ZCRMCompanyInfo()
        companyInfo.id = try companyDetails.getInt64( key : ResponseJSONKeys.id )
        if( companyDetails.hasValue( forKey : ResponseJSONKeys.fax ) )
        {
            companyInfo.fax = try companyDetails.getString( key : ResponseJSONKeys.fax )
        }
        companyInfo.name = companyDetails.optString( key : ResponseJSONKeys.companyName )
        if( companyDetails.hasValue( forKey : ResponseJSONKeys.alias ) )
        {
            companyInfo.alias = try companyDetails.getString( key : ResponseJSONKeys.alias)
        }
        companyInfo.primaryZUID = try companyDetails.getInt64( key : ResponseJSONKeys.primaryZUID )
        companyInfo.zgid = try companyDetails.getInt64( key : ResponseJSONKeys.ZGID )
        if let ziaPortalIdStr = companyDetails.optString( key : ResponseJSONKeys.ziaPortalId )
        {
            if let ziaPortalId = Int64( ziaPortalIdStr )
            {
                companyInfo.ziaPortalId = ziaPortalId
            }
        }
        if( companyDetails.hasValue( forKey : ResponseJSONKeys.phone ) )
        {
            companyInfo.phone = try companyDetails.getString( key : ResponseJSONKeys.phone )
        }
        if( companyDetails.hasValue( forKey : ResponseJSONKeys.mobile ) )
        {
            companyInfo.mobile = try companyDetails.getString( key : ResponseJSONKeys.mobile )
        }
        if( companyDetails.hasValue( forKey : ResponseJSONKeys.website ) )
        {
            companyInfo.website = try companyDetails.getString( key : ResponseJSONKeys.website )
        }
        companyInfo.primaryEmail = try companyDetails.getString( key : ResponseJSONKeys.primaryEmail )
        if( companyDetails.hasValue( forKey : ResponseJSONKeys.employeeCount ) )
        {
            companyInfo.employeeCount = try companyDetails.getString( key : ResponseJSONKeys.employeeCount )
        }
        if( companyDetails.hasValue( forKey : ResponseJSONKeys.description ) )
        {
            companyInfo.description = try companyDetails.getString( key : ResponseJSONKeys.description )
        }
        if( companyDetails.hasValue( forKey : ResponseJSONKeys.timeZone ) )
        {
            companyInfo.timeZone = try companyDetails.getString( key : ResponseJSONKeys.timeZone )
        }
        if( companyDetails.hasValue( forKey : ResponseJSONKeys.ISOCode ) )
        {
            companyInfo.isoCode = try companyDetails.getString( key : ResponseJSONKeys.ISOCode )
        }
        if( companyDetails.hasValue( forKey : ResponseJSONKeys.currencyLocale ) )
        {
            companyInfo.currencyLocale = try companyDetails.getString( key : ResponseJSONKeys.currencyLocale )
        }
        if( companyDetails.hasValue( forKey : ResponseJSONKeys.currencySymbol ) )
        {
            companyInfo.currencySymbol = try companyDetails.getString( key : ResponseJSONKeys.currencySymbol )
        }
        if( companyDetails.hasValue( forKey : ResponseJSONKeys.street ) )
        {
            companyInfo.street = try companyDetails.getString( key : ResponseJSONKeys.street )
        }
        if( companyDetails.hasValue( forKey : ResponseJSONKeys.city ) )
        {
            companyInfo.city = try companyDetails.getString( key : ResponseJSONKeys.city )
        }
        if( companyDetails.hasValue( forKey : ResponseJSONKeys.state ) )
        {
            companyInfo.state = try companyDetails.getString( key : ResponseJSONKeys.state )
        }
        if( companyDetails.hasValue( forKey : ResponseJSONKeys.country ) )
        {
            companyInfo.country = try companyDetails.getString( key : ResponseJSONKeys.country )
        }
        if( companyDetails.hasValue( forKey : ResponseJSONKeys.countryCode ) )
        {
            companyInfo.countryCode = try companyDetails.getString( key : ResponseJSONKeys.countryCode )
        }
        if( companyDetails.hasValue( forKey : ResponseJSONKeys.zip ) )
        {
            companyInfo.zipcode = try companyDetails.getString( key : ResponseJSONKeys.zip )
        }
        if( companyDetails.hasValue( forKey : ResponseJSONKeys.mcStatus ) )
        {
            companyInfo.mcStatus = try companyDetails.getBoolean( key : ResponseJSONKeys.mcStatus )
        }
        if( companyDetails.hasValue( forKey : ResponseJSONKeys.translationEnabled ) )
        {
            companyInfo.isTranslationEnabled = try companyDetails.getBoolean( key : ResponseJSONKeys.translationEnabled )
        }
        if( companyDetails.hasValue( forKey : ResponseJSONKeys.gappsEnabled ) )
        {
            companyInfo.isGappsEnabled = try companyDetails.getBoolean( key : ResponseJSONKeys.gappsEnabled )
        }
        if( companyDetails.hasValue( forKey : ResponseJSONKeys.privacySettings ) )
        {
            companyInfo.isPrivacySettingsEnable = try companyDetails.getBoolean( key : ResponseJSONKeys.privacySettings )
        }
        if companyDetails.hasValue( forKey : ResponseJSONKeys.photoId )
        {
            companyInfo.logoId = try companyDetails.getString( key : ResponseJSONKeys.photoId )
        }
        if companyDetails.hasValue( forKey : ResponseJSONKeys.currency )
        {
            companyInfo.currency = try companyDetails.getString( key : ResponseJSONKeys.currency )
        }
        if companyDetails.hasValue(forKey: ResponseJSONKeys.licenseDetails)
        {
            let licenseDetails = try companyDetails.getDictionary(key: ResponseJSONKeys.licenseDetails)
            var license = ZCRMCompanyInfo.LicenseDetails( licensePlan : try licenseDetails.getString( key : ResponseJSONKeys.paidType ) )
            license.isPaid = try licenseDetails.getBoolean( key : ResponseJSONKeys.paid )
            if licenseDetails.hasValue(forKey: ResponseJSONKeys.paidExpiry)
            {
                license.expiryDate = try licenseDetails.getString(key: ResponseJSONKeys.paidExpiry)
            }
            if licenseDetails.hasValue(forKey: ResponseJSONKeys.trialExpiry)
            {
                license.expiryDate = try licenseDetails.getString(key: ResponseJSONKeys.trialExpiry)
            }
            license.noOfUsersPurchased = try licenseDetails.getInt( key : ResponseJSONKeys.usersLicensePurchased )
            license.trialType = licenseDetails.optString( key : ResponseJSONKeys.trialType )
            license.trialAction = licenseDetails.optString( key : ResponseJSONKeys.trialAction )
            companyInfo.licenseDetails = license
        }
        return companyInfo
    }
    
    private func getZCRMCurrencyAsJSON( currency : ZCRMCurrency ) throws -> [ String : Any? ]
    {
        var currencyJSON : [ String : Any? ] = [:]
        if currency.id != nil
        {
            currencyJSON.updateValue( currency.id, forKey: ResponseJSONKeys.id )
        }
        currencyJSON.updateValue( currency.name, forKey: ResponseJSONKeys.name )
        currencyJSON.updateValue( currency.isoCode, forKey: ResponseJSONKeys.ISOCode )
        currencyJSON.updateValue( currency.symbol, forKey: ResponseJSONKeys.symbol )
        if let exchangeRate = currency.exchangeRate
        {
            currencyJSON.updateValue( "\( exchangeRate )", forKey: ResponseJSONKeys.exchangeRate )
        }
        if let format = currency.format
        {
            currencyJSON.updateValue( try self.getCurrencyFormatJSON( format ), forKey: ResponseJSONKeys.format)
        }
        currencyJSON.updateValue( currency.isActive, forKey: ResponseJSONKeys.isActive )
        currencyJSON.updateValue( currency.prefixSymbol, forKey: ResponseJSONKeys.prefixSymbol )
        currencyJSON.updateValue( currency.isActive, forKey: ResponseJSONKeys.isActive )
        
        return currencyJSON
    }
    
    private func getCurrencyFormatJSON( _ format : ZCRMCurrency.Format ) throws -> [ String : Any ]
    {
        var formatJSON : [ String : Any ] = [:]
        formatJSON.updateValue( try self.getValidSeparator(type: ResponseJSONKeys.decimalSeparator, format.decimalSeparator), forKey: ResponseJSONKeys.decimalSeparator )
        formatJSON.updateValue( try self.getValidSeparator(type: ResponseJSONKeys.thousandSeparator, format.thousandSeparator), forKey: ResponseJSONKeys.thousandSeparator )
        formatJSON.updateValue( "\( format.decimalPlaces )", forKey: ResponseJSONKeys.decimalPlaces )
        return formatJSON
    }
    
    private func getValidSeparator( type : String, _ separator : String ) throws -> String
    {
        if separator.lowercased() == "comma" || separator == ","
        {
            return "Comma"
        }
        else if separator.lowercased() == "period" || separator == "."
        {
            return "Period"
        }
        else if separator.lowercased() == "space" || separator == " "
        {
            return "Space"
        }
        else
        {
            ZCRMLogger.logError(message: "\(ErrorCode.invalidData) : \( type ) given is invalid - \( separator ), \( APIConstants.DETAILS ) : -")
            throw ZCRMError.processingError(code: ErrorCode.invalidData, message: "\( type ) given is invalid - \( separator )", details: nil)
        }
    }
    
    private func getZCRMVariableAsJSON( variable : ZCRMVariable ) -> [ String : Any? ]
    {
        var variableJSON : [ String : Any? ] = [ String : Any? ]()
        variableJSON.updateValue( variable.name, forKey : ResponseJSONKeys.name )
        variableJSON.updateValue( variable.apiName, forKey : ResponseJSONKeys.apiName )
        let requestMethod = getRequestMethod()
        if requestMethod != .patch && requestMethod != .put
        {
            if variable.variableGroup.isApiNameSet || variable.variableGroup.isNameSet
            {
                variableJSON.updateValue( getZCRMVariableGroupAsJSON( variableGroup : variable.variableGroup ), forKey : ResponseJSONKeys.variableGroup )
            }
            variableJSON.updateValue( variable.type, forKey : ResponseJSONKeys.type )
        }
        if !variable.isCreate
        {
            variableJSON.updateValue( variable.id, forKey : ResponseJSONKeys.id )
        }
        variableJSON.updateValue( variable.description, forKey : ResponseJSONKeys.description )
        variableJSON.updateValue( variable.value, forKey : ResponseJSONKeys.value )
        return variableJSON
    }
    
    private func getZCRMVariableGroupAsJSON( variableGroup : ZCRMVariableGroup ) -> [ String : Any? ]
    {
        var variableGroupJSON : [ String : Any? ] = [ String : Any? ]()
        if variableGroup.isNameSet
        {
            variableGroupJSON.updateValue( variableGroup.name, forKey : ResponseJSONKeys.name )
        }
        if variableGroup.isApiNameSet
        {
            variableGroupJSON.updateValue( variableGroup.apiName, forKey : ResponseJSONKeys.apiName )
        }
        variableGroupJSON.updateValue( variableGroup.description, forKey : ResponseJSONKeys.description )
         return variableGroupJSON
    }
    
    private func getZCRMVariable( variable : ZCRMVariable, variableJSON : [String:Any] ) throws -> ZCRMVariable
    {
        if variableJSON.hasValue(forKey: ResponseJSONKeys.id)
        {
            variable.id = try variableJSON.getInt64( key : ResponseJSONKeys.id )
        }
        if variableJSON.hasValue(forKey: ResponseJSONKeys.name)
        {
            variable.name = try variableJSON.getString( key : ResponseJSONKeys.name )
        }
        if variableJSON.hasValue(forKey: ResponseJSONKeys.apiName)
        {
            variable.apiName = try variableJSON.getString( key : ResponseJSONKeys.apiName )
        }
        if variableJSON.hasValue(forKey: ResponseJSONKeys.type)
        {
            variable.type = try variableJSON.getString( key : ResponseJSONKeys.type )
        }
        if variableJSON.hasValue(forKey: ResponseJSONKeys.variableGroup)
        {
            variable.variableGroup = try self.getZCRMVariableGroup( variableGroupJSON : try variableJSON.getDictionary( key : ResponseJSONKeys.variableGroup ) )
        }
        if variableJSON.hasValue(forKey: ResponseJSONKeys.description)
        {
            variable.description = try variableJSON.getString( key : ResponseJSONKeys.description )
        }
        if variableJSON.hasValue(forKey: ResponseJSONKeys.value)
        {
            variable.value = try variableJSON.getString( key : ResponseJSONKeys.value )
        }
        variable.isCreate = false
        return variable
    }
    
    private func getZCRMVariableGroup( variableGroupJSON : [String:Any] ) throws -> ZCRMVariableGroup
    {
        let variableGroup : ZCRMVariableGroup = ZCRMVariableGroup( apiName : try variableGroupJSON.getString( key : ResponseJSONKeys.apiName ), id : try variableGroupJSON.getInt64( key : ResponseJSONKeys.id ) )
        if variableGroupJSON.hasValue(forKey: ResponseJSONKeys.name)
        {
            variableGroup.name = try variableGroupJSON.getString( key : ResponseJSONKeys.name )
        }
        if variableGroupJSON.hasValue(forKey: ResponseJSONKeys.description)
        {
            variableGroup.description = try variableGroupJSON.getString( key : ResponseJSONKeys.description )
        }
        if variableGroupJSON.hasValue(forKey: ResponseJSONKeys.displayLabel)
        {
            variableGroup.displayLabel = try variableGroupJSON.getString( key : ResponseJSONKeys.displayLabel )
        }
        return variableGroup
    }
    
    private func getAllZCRMCurrencies( currenciesDetails : [ [ String : Any ] ] ) throws -> [ ZCRMCurrency ]
    {
        var currencies = [ ZCRMCurrency ]()
        for currencyDetails in currenciesDetails
        {
            let currency = try self.getZCRMCurrency( currencyDetails : currencyDetails )
            currencies.append( currency )
        }
        return currencies
    }
    
    private func getZCRMCurrency( currencyDetails : [ String : Any ] ) throws -> ZCRMCurrency
    {
        let currency = try ZCRMCurrency( name : currencyDetails.getString( key : ResponseJSONKeys.name ), symbol : currencyDetails.getString( key : ResponseJSONKeys.symbol ), isoCode : currencyDetails.getString( key : ResponseJSONKeys.ISOCode ) )
        currency.createdTime = currencyDetails.optString( key : ResponseJSONKeys.createdTime )
        currency.isActive = try currencyDetails.getBoolean( key : ResponseJSONKeys.isActive )
        if currencyDetails.hasValue( forKey : ResponseJSONKeys.exchangeRate )
        {
            currency.exchangeRate = try Double( currencyDetails.getString( key : ResponseJSONKeys.exchangeRate )  )
        }
        if currencyDetails.hasValue( forKey : ResponseJSONKeys.createdBy )
        {
            currency.createdBy = try getUserDelegate( userJSON : currencyDetails.getDictionary( key : ResponseJSONKeys.createdBy ) )
        }
        currency.prefixSymbol = currencyDetails.optBoolean( key : ResponseJSONKeys.prefixSymbol )
        currency.isBase = try currencyDetails.getBoolean( key : ResponseJSONKeys.isBase )
        currency.modifiedTime = try currencyDetails.getString( key : ResponseJSONKeys.modifiedTime )
        if currencyDetails.hasValue( forKey : ResponseJSONKeys.modifiedBy )
        {
            currency.modifiedBy = try getUserDelegate( userJSON : currencyDetails.getDictionary( key : ResponseJSONKeys.modifiedBy ) )
        }
        currency.id = try currencyDetails.getInt64( key : ResponseJSONKeys.id )
        if currencyDetails.hasValue( forKey : ResponseJSONKeys.format )
        {
            let formatDetails : [ String : Any ] = try currencyDetails.getDictionary( key : ResponseJSONKeys.format )
            if let decimalPlaces = Int( try formatDetails.getString( key : ResponseJSONKeys.decimalPlaces  ) )
            {
                currency.format = try ZCRMCurrency.Format( decimalSeparator : ZCRMCurrency.Separator.get(forValue: formatDetails.getString( key : ResponseJSONKeys.decimalSeparator )), thousandSeparator : ZCRMCurrency.Separator.get(forValue: formatDetails.getString( key : ResponseJSONKeys.thousandSeparator )), decimalPlaces : decimalPlaces )
            }
        }
        return currency
    }
}

extension OrgAPIHandler
{
    struct ResponseJSONKeys
    {
        static let id = "id"
        static let fax = "fax"
        static let companyName = "company_name"
        static let alias = "alias"
        static let primaryZUID = "primary_zuid"
        static let ZGID = "zgid"
        static let phone = "phone"
        static let mobile = "mobile"
        static let website = "website"
        static let primaryEmail = "primary_email"
        static let employeeCount = "employee_count"
        static let description = "description"
        static let timeZone = "time_zone"
        static let ISOCode = "iso_code"
        static let currencyLocale = "currency_locale"
        static let currencySymbol = "currency_symbol"
        static let street = "street"
        static let city = "city"
        static let state = "state"
        static let country = "country"
        static let countryCode = "country_code"
        static let zip = "zip"
        static let mcStatus = "mc_status"
        static let gappsEnabled = "gapps_enabled"
        static let privacySettings = "privacy_settings"
        static let translationEnabled = "translation_enabled"
        
        static let name = "name"
        static let apiName = "api_name"
        static let variableGroup = "variable_group"
        static let type = "type"
        static let value = "value"
        static let displayLabel = "display_label"
        static let defaultString = "default"
        
        static let portalSwitch = "portalswitch"
        static let domainName = "domain_name"
        static let webURL = "web_url"
        static let apiURL = "api_url"
        static let administrator = "administrator"
        static let joinedTime = "joined_time"
        static let userStatus = "user_status"
        
        static let paidExpiry = "paid_expiry"
        static let usersLicensePurchased = "users_license_purchased"
        static let trialType = "trial_type"
        static let trialExpiry = "trial_expiry"
        static let paid = "paid"
        static let paidType = "paid_type"
        static let trialAction = "trial_action"
        static let licenseDetails = "license_details"
        static let ziaPortalId = "zia_portal_id"
        
        static let symbol = "symbol"
        static let createdTime = "created_time"
        static let isActive = "is_active"
        static let exchangeRate = "exchange_rate"
        static let format = "format"
        static let decimalSeparator = "decimal_separator"
        static let thousandSeparator = "thousand_separator"
        static let decimalPlaces = "decimal_places"
        static let createdBy = "created_by"
        static let prefixSymbol = "prefix_symbol"
        static let isBase = "is_base"
        static let modifiedTime = "modified_time"
        static let modifiedBy = "modified_by"
        
        static let photoId = "photo_id"
        static let currency = "currency"
        
        static let active = "active"

        static let manager = "manager"
        static let parentId = "parent_id"
        static let reportingTo = "reporting_to"
        static let criteria = "criteria"
        static let field = "field"
        static let comparator = "comparator"
        static let accountRuleCriteria = "account_rule_criteria"
        static let permissionType = "permission_type"
    }
    
    struct URLPathConstants {
        static let org = "org"
        static let orgs = "orgs"
        static let settings = "settings"
        static let variables = "variables"
        static let variableGroups = "variable_groups"
        static let __internal = "__internal"
        static let ignite = "ignite"
        static let switchPortal = "SwitchPortal"
        static let currencies = "currencies"
        static let photo = "photo"
        static let insights = "insights"
        static let emails = "emails"
        static let actions = "actions"
        static let enable = "enable"
        static let files = "files"
    }
}

extension RequestParamKeys
{
    static let group : String = "group"
    static let orgId = "orgid"
    static let inline = "inline"
}
