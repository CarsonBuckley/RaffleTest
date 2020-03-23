//
//  Person.swift
//  RaffleTest
//
//  Created by Carson Buckley on 3/23/20.
//  Copyright © 2020 Carson Buckley. All rights reserved.
//

import Foundation
import Firebase

class Person {
    
    var name: String
    var username: String
    var email: String
    var points: Int
    var address: String?
    var friends: [String] = []
    let firebaseUID: String
    var selfDocRef: DocumentReference
    var referralCode: String
    //var profileImage: UIImage?
    
    init(name: String, username: String, email: String, points: Int, address: String?, friends: [String], firebaseUID: String, docRef: DocumentReference, referralCode: String) {
        self.name = name
        self.username = username
        self.email = email
        self.points = points
        self.friends = friends
        self.firebaseUID = firebaseUID
        self.selfDocRef = docRef
        self.referralCode = referralCode
    }
    
    var dictionary: [String: Any] {
        return [
            "name" : name,
            "username" : username,
            "email" : email,
            "points" : points,
            "address" : address,
            "friends" : friends,
            "firebaseUID" : firebaseUID,
            "selfDocRef" : selfDocRef,
            "referralCode" : referralCode
            //"profileImage" : profileImage
        ]
    }
}

extension Person {
    convenience init?(dictionary: [String: Any]) {
        guard let name = dictionary["name"] as? String,
            let username = dictionary["username"] as? String,
            let email = dictionary["email"] as? String,
            let points = dictionary["points"] as? Int,
            let friends = dictionary["friends"] as? [String],
            let firebaseUID = dictionary["firebaseUID"] as? String,
            let selfDocRef = dictionary["selfDocRef"] as? DocumentReference,
            let referralCode = dictionary["referralCode"] as? String
            
            else { return nil }
        
        let address = dictionary["address"] as? String
        
        self.init(name: name, username: username, email: email, points: points, address: address, friends: friends, firebaseUID: firebaseUID, docRef: selfDocRef, referralCode: referralCode)
    }
}
