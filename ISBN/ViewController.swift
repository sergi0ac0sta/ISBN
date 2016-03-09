//
//  ViewController.swift
//  ISBN
//
//  Created by Sergio A Acosta Lozano on 3/8/16.
//  Copyright © 2016 Sergio A Acosta Lozano. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var ISBN: UITextField!
    @IBOutlet weak var Results: UITextView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!

    @IBAction func backgroundTap(sender: UIControl) {
        ISBN.resignFirstResponder()
    }
    
    @IBAction func textFieldDidEndEditing(textField: UITextField) {
        textField.resignFirstResponder()
        if textField.text != "" {
            indicator.startAnimating()
            textField.userInteractionEnabled = false
            search()
        }
    }
    
    func textFieldShouldClear(textField: UITextField) -> Bool {
        Results.text = ""
        return true;
    }
    
    override func viewDidAppear(animated: Bool) {
        indicator.stopAnimating()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ISBN.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func search() {
        ISBN.resignFirstResponder()
        
        let url = NSURL(string: "https://openlibrary.org/api/books?jscmd=data&format=json&bibkeys=ISBN:" + ISBN.text!)
        let session = NSURLSession.sharedSession()
        let data = { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            if let httpResponse = response as? NSHTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    dispatch_sync(dispatch_get_main_queue()) {
                        let text = String(data: data!, encoding: NSUTF8StringEncoding)
                        if text == "{}" {
                            self.Results.text = "No hay resultados."
                        } else {
                            self.Results.text = text
                        }
                        self.indicator.stopAnimating()
                        self.ISBN.userInteractionEnabled = true
                    }
                } else {
                    dispatch_sync(dispatch_get_main_queue()) {
                        self.Results.text = "Error, por favor revisa tu conexión a internet."
                        self.indicator.stopAnimating()
                        self.ISBN.userInteractionEnabled = true
                    }
                }
            } else {
                dispatch_sync(dispatch_get_main_queue()) {
                    self.Results.text = "Error, por favor revisa tu conexión a internet."
                    self.indicator.stopAnimating()
                    self.ISBN.userInteractionEnabled = true
                }
            }
        }
        let dt = session.dataTaskWithURL(url!, completionHandler: data)
        dt.resume()
    }
}

