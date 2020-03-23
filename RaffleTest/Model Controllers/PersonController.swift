//
//  PersonController.swift
//  RaffleTest
//
//  Created by Carson Buckley on 3/23/20.
//  Copyright © 2020 Carson Buckley. All rights reserved.
//

import Foundation
import Firebase

class PersonController {
    
    static let sharedInstance = PersonController()
    
    //Firebase References
    let accountRef = Firestore.firestore().collection("users")
    
    //Source of Truth
    var currentUser: Person?
    var friends: [Person] = []
    
    func createAccount(name: String, username: String, email: String, password: String, completion: @escaping (Bool) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { (authData, error) in
            if let error = error {
                print("THERE WAS AN ERROR: \(error.localizedDescription) ❌")
                completion(false)
                return
            }
            guard let authData = authData else { completion(false); return }
            let userUID = authData.user.uid
            
            let docRef = self.accountRef.document(userUID)
            
            let newPerson = Person(name: name, username: username, email: email, points: 1, address: "", friends: [], firebaseUID: userUID, docRef: docRef, referralCode: "")
            
            self.currentUser = newPerson
            
            self.accountRef.document(userUID).setData(newPerson.dictionary) { error in
                if let error = error {
                    print("ERROR WRITING DOCUMENT: \(error.localizedDescription) ❌")
                    completion(false)
                } else {
                    print("SUCCESS WRITING DOCUMENT ✅")
                    completion(true)
                }
            }
        }
    }
    
    func loginUser(email: String, password: String, completion: @escaping (String?, Error?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { (authData, error) in
            if let error = error {
                print("THERE WAS AN ERROR SIGNING IN \(error.localizedDescription) ❌")
                completion(nil, error)
                return
            }
            guard let authData = authData else { completion(nil, error); return }
            let fireBaseUID = authData.user.uid
            completion(fireBaseUID, nil)
        }
    }
    
    func initializeUser(fireBaseUID: String, completion: @escaping (Bool) -> Void) {
        accountRef.document(fireBaseUID).getDocument { (docSnapshot, error) in
            if let error = error {
                print("THERE WAS AN ERROR FINDING USER WITH THAT USERID: \(error.localizedDescription) ❌")
                completion(false)
                return
            } else {
                guard let docSnapshot = docSnapshot else { completion(false); return }
                if docSnapshot.exists {
                    let user = Person(dictionary: docSnapshot.data()!)
                    self.currentUser = user
                    completion(true)
                    print("SUCCESS FINDING USER WITH USERID ✅")
                }
            }
        }
    }
    
    func signOutUser(completion: @escaping (Bool) -> Void) {
        do {
            try Auth.auth().signOut()
            print("SUCCESS LOGGING OUT USER ✅")
            completion(true)
        } catch let error {
            print("FAILED TO LOG OUT USER: \(error.localizedDescription) ❌")
            completion(false)
        }
    }
    
    func updatePassword(email: String, completion: @escaping (Bool, Error?) -> Void) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                print("FAILED TO SEND EMAIL TO USER: \(error.localizedDescription) ❌")
                completion(false, error)
                return
            } else {
                print("SUCCESS SENDING EMAIL TO USER ✅")
                completion(true, nil)
            }
        }
    }
    
    func deleteUser(user: User, currentUser: Person, completion: @escaping (Bool) -> Void) {
        user.delete { (error) in
            if let error = error {
                print("THERE WAS AN ERROR DELETING THE USER \(error.localizedDescription) ❌")
                completion(false)
                return
            } else {
                currentUser.selfDocRef.delete(completion: { (error) in
                    if let error = error {
                        print("THERE WAS AN ERROR DELETING USER: \(error.localizedDescription) ❌")
                        completion(false)
                        return
                    } else {
                        print("SUCCESS DELETING USER ✅")
                        completion(true)
                    }
                })
            }
        }
    }
    
    func saveUserToFirestore(completion: @escaping (Bool) -> Void) {
        self.currentUser!.selfDocRef.setData(currentUser!.dictionary) { (error) in
            if let error = error {
                print("FAILED TO SAVE USER TO FIRESTORE: \(error.localizedDescription) ❌")
            }
            completion(true)
        }
    }
    
    func addFriendToUser(person: Person, completion: @escaping (Bool) -> Void) {
        if self.currentUser!.friends.contains(person.firebaseUID) {
            completion(false)
            return
        }
        self.currentUser?.friends.append(person.firebaseUID)
        saveUserToFirestore(completion: completion)
    }
    
    func addCurrentUser(to person: Person, completion: @escaping (Bool) -> Void) {
        Firestore.firestore().collection("users").document(person.firebaseUID).updateData(["friends": FieldValue.arrayUnion([currentUser!.firebaseUID])]) { (error) in
            if let error = error {
                print("THERE WAS AN ERROR: \(error.localizedDescription) ❌")
                completion(false)
                return
            } else {
                completion(true)
                print("SUCCESS ✅")
            }
        }
    }
    
    func searchForFriend(username: String, completion: @escaping (Person) -> Void) {
        Firestore.firestore().collection("users").whereField("username", isEqualTo: username).getDocuments { (snapshots, error) in
            if let error = error {
                print("THERE WAS AN ERROR SEARCHING FOR USER: \(error.localizedDescription) ❌")
                return
            }
            for document in snapshots!.documents {
                guard let person = Person(dictionary: document.data()) else {
                    print("❌")
                    return
                }
                completion(person)
            }
        }
    }
    
    func fetchFriends(friend: Person, firebaseUID: String, completion: @escaping (Bool) -> Void) {
        Firestore.firestore().collection("users").whereField("friends", arrayContains: friend.firebaseUID).getDocuments { (snapshots, error) in
            if let error = error {
                print("THERE WAS AN ERROR FETCHING USER: \(error.localizedDescription) ❌")
                completion(false)
                return
            }
            self.friends.removeAll()
            for document in snapshots!.documents {
                guard let friend = Person(dictionary: document.data()) else { print("❌"); return }
//                if friend.blockedUsersFirebase.contains(firebaseUID) {
//                    continue
//                } else {
                    self.friends.append(friend)
                    self.friends.sort(by: { $0.username < $1.username })
                    print("\(document == snapshots?.documents.last)")
//                }
            }
            completion(true)
        }
    }
}
