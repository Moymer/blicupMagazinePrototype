//
//  BlicupServicesTestCase.m
//  Blicup
//
//  Created by Moymer on 19/04/16.
//  Copyright © 2016 Moymer. All rights reserved.
//
import XCTest
@testable import Blicup

class BlicupServicesTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    
    
    func testCreateUser() {
        
        let username:String? = randomStringWithLength(9)
        let userJsonObject: [String: AnyObject] = [
            "userId": 1,
            "username":username!,
            "facebookId" : "vhamFBId",
            "twitterId" : "vhamTwitterId",
            "photoUrl": "http://www.site.com",
            "tagList": ["futebol", "basquete"]
            
            
        ]
        
        LDTProtocolImpl.sharedInstance.createUserAccount(userJsonObject) { (success, newUser) in
            
            XCTAssertTrue(success)
            
            XCTAssertEqual(newUser!["username"] as? String, username)
         
        }
        
    }
    
    func testChangeUser() {
        
        let userJsonObject: [String: AnyObject] = [
            "userId": "vham1461102585454",
            "username":"vham",
            "facebookId" : "vhamFBId",
            "twitterId" : "vhamTwitterId",
            "photoUrl": "http://www.site.com",
            "tagList": ["futebolC", "basqueteC"]
            
        ]
        
        
        LDTProtocolImpl.sharedInstance.changeUserAccount(userJsonObject)  { (success, changed) in
            
            XCTAssertTrue(success)
            XCTAssertTrue(changed)
        }
        
        
    }

    func randomStringWithLength (len : Int) -> String {
        
        let letters : String = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        
        var randomString : String = " "
        
        for _ in 0 ... len {
            let length = UInt32 (letters.length)
            let rand = arc4random_uniform(length)
            randomString = randomString + letters[Int(rand)]
        }
        
        return randomString
    }
    
    func testCreateUserThatExists() {
        
        let userJsonObject: [String: AnyObject] = [
            "userId": 1,
            "username": "vham",
            "facebookId" : "vhamFBId",
            "twitterId" : "vhamTwitterId",
            "photoUrl": "http://www.site.com",
            "tagList": ["futebol", "basquete"]
            
            
        ]
        
        LDTProtocolImpl.sharedInstance.createUserAccount(userJsonObject) { (success, newUser) in
        
            XCTAssertTrue(success)
            //volta user nil
            XCTAssertNil(newUser)
        }
        
    }
    
    func testUsernameAvailable() {
        
        LDTProtocolImpl.sharedInstance.isUsernameAvailable("vhamFaceTfdsfwitter") { (success, available) in
            
             XCTAssertTrue(success)
             XCTAssertTrue(available)
        }
    }
    
    func testUsernameUnavailable ()  {
       
        LDTProtocolImpl.sharedInstance.isUsernameAvailable("vham") { (success, available) in
            
            XCTAssertTrue(success)
            XCTAssertFalse(available)
        }

    }
    
    func testRestoreFromFacebook()  {
        
         LDTProtocolImpl.sharedInstance.restoreUserAccountWithFacebookId("vhamFBId") { (success, restoredUser) in
            XCTAssertTrue(success)
            XCTAssertEqual(restoredUser!["facebookId"] as? String, "vhamFBId")

        }
    }
    
    func testRestoreFromTwitter()  {
        LDTProtocolImpl.sharedInstance.restoreUserAccountWithTwitterId("vhamTwitterId") { (success, restoredUser) in
            XCTAssertTrue(success)
            XCTAssertEqual(restoredUser!["twitterId"] as? String, "vhamTwitterId")
            
        }

    }
    
    
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}

