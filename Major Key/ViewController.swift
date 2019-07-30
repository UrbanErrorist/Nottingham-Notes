//
//  ViewController.swift
//  Major Key
//
//  Created by Rishabh Goswami on 11/26/18.
//  Copyright © 2018 Rishabh Goswami. All rights reserved.
//

import UIKit
import SwiftMessages

class ViewController: UIViewController {
    @IBOutlet weak var majorTextView: UITextView!
    
    let apiKey = ""
    let apiSecret = ""
    let fromAddress = "rishabhgoswami@icloud.com"
    
    let defaultsForHistory = "MajorKeys"
    let defaultsForEmail = "MajorKeyEmail"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.majorTextView.text = ""
        self.majorTextView.delegate = self

        let majorView = MajorKeyView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 92))
        majorView.delegate = self
        self.majorTextView.inputAccessoryView = majorView
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.majorTextView.becomeFirstResponder()
        
        if UserDefaults.standard.string(forKey: defaultsForEmail) == nil {
            self.didPressSettingsButton(button: nil)
        }
    }

    func didPressMajorKey() {
        guard let text = self.majorTextView.text, text.count > 0 else {
            return
        }

        var oldKeys = UserDefaults.standard.stringArray(forKey: defaultsForHistory) ?? []
        oldKeys.append(text)
        UserDefaults.standard.set(oldKeys, forKey: defaultsForHistory)

        triggerEmail(text: text)
    }
    
    func showAlert(title: String, body: String, theme: Theme) {
        let view = MessageView.viewFromNib(layout: .cardView)
        view.configureTheme(theme)
        view.configureDropShadow()
        view.button?.removeFromSuperview()
        view.configureContent(title: title, body: body, iconText: "🔑")
        
        var config = SwiftMessages.Config()
        config.presentationStyle = .top
        config.interactiveHide = true
        config.preferredStatusBarStyle = .lightContent
        SwiftMessages.show(config: config, view: view)
    }
    
    func triggerEmail(text: String) {
        let url = URL(string: "https://api.mailjet.com/v3.1/send")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Auth code
        // code via https://stackoverflow.com/questions/24379601/how-to-make-an-http-request-basic-auth-in-swift
        let loginString = String(format: "%@:%@", apiKey, apiSecret)
        let loginData = loginString.data(using: String.Encoding.utf8)!
        let base64LoginString = loginData.base64EncodedString()
        request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        
        // Subject allows 255 chars maximum
        let truncatedTextForSubject = text.suffix(200)
        
        let emailAddress = UserDefaults.standard.string(forKey: defaultsForEmail)!
        let postContent = [
            "Messages": [
                [
                    "From": [
                        "Email": fromAddress,
                        "Name": "New MajorKey"
                    ],
                    "To": [
                        [
                            "Email": emailAddress,
                            "Name": "Name"
                        ]
                    ],
                    "Subject": "[Major 🔑] \(truncatedTextForSubject)",
                    "TextPart": text
                ]
            ]
        ]
        do {
            let postString = try JSONSerialization.data(withJSONObject: postContent, options: .prettyPrinted)
            
            // Request body
            request.httpBody = postString //postString.data(using: .utf8)
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async {
                    guard let data = data, error == nil else {                                                 // check for fundamental networking error
                        print("error=\(String(describing: error))")
                        self.showAlert(title: "Error", body: String(describing: error), theme: .error);
                        return
                    }

                    if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {           // check for http errors
                        print("statusCode should be 200, but is \(httpStatus.statusCode)")
                        print("response = \(String(describing: response) )")
                        self.showAlert(title: "Error", body: String(describing: response), theme: .error);
                        return
                    }

                    let responseString = String(data: data, encoding: .utf8)
                    print("responseString = \(String(describing: responseString))")
                    self.showAlert(title: "Major Key", body: "Never forget dat major key", theme: .success);

                    self.majorTextView.text = ""
                }
            }
            task.resume()
        } catch {
            print(error.localizedDescription)
        }
    }

    func didTapOldKeys() {
        self.majorTextView.text = UserDefaults.standard.stringArray(forKey: defaultsForHistory)?.reversed().joined(separator: "\n")
    }
    
    func didPressSettingsButton(message: String) {
        let alert = UIAlertController(
            title: "Choose your email address",
            message: message,
            preferredStyle: .alert
        )
        
        alert.addTextField { (textField) in
            textField.placeholder = "Your email address"
            textField.keyboardType = .emailAddress
            textField.textContentType = UITextContentType.emailAddress
            textField.text = UserDefaults.standard.string(forKey: self.defaultsForEmail);
        }
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
            guard let textField = alert?.textFields?[0] else {
                print("Couldn't find alert text field")
                return
            }

            if let text = textField.text, text.contains("@") {
                UserDefaults.standard.set(text, forKey: self.defaultsForEmail)
            } else {
                self.didPressSettingsButton(message: "Please enter a valid email address");
            }
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
}

extension ViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if (text == "\n") {
            self.didPressMajorKey()
            return false
        }
        return true
    }
}

extension ViewController: MajorKeyViewDelegate {
    func didPressKeyButton(button: UIButton) {
        didPressMajorKey()
    }

    func didPressPackageButton(button: UIButton) {
        didPressMajorKey()
        didTapOldKeys()
    }
    
    func didPressSettingsButton(button: UIButton?) {
        didPressSettingsButton(message: "This is where all major keys will be sent to");
    }
}
