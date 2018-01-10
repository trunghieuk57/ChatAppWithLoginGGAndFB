//
//  Copyright (c) 2015 Google Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import UIKit
import FBSDKLoginKit
import Firebase
import GoogleSignIn
import TwitterKit

@objc(SignInViewController)
class SignInViewController: UIViewController, GIDSignInUIDelegate, FBSDKLoginButtonDelegate {
    
  @IBOutlet weak var signInButton: GIDSignInButton!
  var handle: AuthStateDidChangeListenerHandle?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupFacebookButton()
        setupGoogleButton()
        setupTwitterButton()
    }
    
    deinit {
        if let handle = handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    fileprivate func setupFacebookButton(){
        let loginButton = FBSDKLoginButton()
        view.addSubview(loginButton)
        loginButton.frame = CGRect(x: 16, y: 400, width: view.frame.width - 48, height: 40)
        let newCenter = CGPoint(x: self.view.frame.width / 2, y: self.view.frame.height - 320)
        loginButton.center = newCenter
        loginButton.delegate = self
    }
    
    fileprivate func setupGoogleButton(){
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().signInSilently()
        handle = Auth.auth().addStateDidChangeListener() { (auth, user) in
            if user != nil {
                MeasurementHelper.sendLoginEvent()
                self.performSegue(withIdentifier: Constants.Segues.SignInToFp, sender: nil)
            }
        }
    }
    
    fileprivate func setupTwitterButton(){
        let twitterButton = TWTRLogInButton{ (session, error) in
            if let err = error {
                print("Falled to login via Twitter: ", err)
                return
            }
            guard let token = session?.authToken else {return}
            guard let secret = session?.authTokenSecret else {return}
            let credential = TwitterAuthProvider.credential(withToken: token, secret: secret)
            Auth.auth().signIn(with: credential, completion: { (user, error) in
                if error != nil {
                    print("Failed to login using Firebase:", error)
                    return
                }
            })
            print("Successfully logged in under Twitter...")
        }
        
        view.addSubview(twitterButton)
        twitterButton.frame = CGRect(x: 16, y: 400, width: view.frame.width - 48, height: 40)
        let newCenter = CGPoint(x: self.view.frame.width / 2, y: self.view.frame.height - 270)
        twitterButton.center = newCenter
    }
    
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        if error != nil{
            print(error)
            return
        }
        let credential = FacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
        Auth.auth().signIn(with: credential) { (user, error) in
            if let error = error {
                print(error)
                return
            }
            // User is signed in
            // ...
        }
        print(Auth.auth())
        print("Successfully logged in with Facebook")
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        print("Did log out Facebook")
    }
}
