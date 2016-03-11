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
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var noCoverLabel: UILabel!
    
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
        imageView.image = nil
        self.noCoverLabel.hidden = true
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
                    do {
                        let json = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableLeaves)
                        let jsonData = json as! NSDictionary
                        if jsonData.count <= 0 {
                            dispatch_sync(dispatch_get_main_queue()) {
                                self.Results.text = "No hay resultados."
                                self.imageView.image = nil
                                self.noCoverLabel.hidden = false
                                self.indicator.stopAnimating()
                                self.ISBN.userInteractionEnabled = true
                            }
                        } else {
                            let elements = jsonData["ISBN:" + self.ISBN.text!] as! NSDictionary
                            let book = elements["title"] as! NSString
                            dispatch_sync(dispatch_get_main_queue()) {
                                self.Results.text = "Libro:\t" + (book as String) + "\n"
                            }
                            if let authors = elements["authors"] {
                                dispatch_sync(dispatch_get_main_queue()) {
                                    if authors.count == 1 {
                                        let author = authors[0] as! NSDictionary
                                        self.Results.text = self.Results.text + "Autor:\t" + (author["name"] as! String) + "\n"
                                    } else if authors.count > 1 {
                                        self.Results.text = self.Results.text + "Autores:\t"
                                        for i in 0..<authors.count {
                                            self.Results.text = self.Results.text + (authors[i]["name"] as! String)
                                            if i < authors.count - 1 {
                                                self.Results.text = self.Results.text + ", "
                                            }
                                        }
                                        self.Results.text = self.Results.text + "\n"
                                    }
                                }
                            }
                            if elements["cover"] != nil {
                                if let url = NSURL(string: elements["cover"]!["medium"] as! String) {
                                    if let data = NSData(contentsOfURL: url) {
                                        self.noCoverLabel.hidden = true
                                        self.imageView.contentMode = .ScaleAspectFit
                                        self.imageView.image = UIImage(data: data)
                                    }
                                } else {
                                    self.imageView.image = nil
                                    self.noCoverLabel.hidden = false
                                }
                            } else {
                                self.noCoverLabel.hidden = false
                            }
                        }
                        dispatch_sync(dispatch_get_main_queue()) {
                            self.indicator.stopAnimating()
                            self.ISBN.userInteractionEnabled = true
                        }
                    } catch _ {}
                } else {
                    dispatch_sync(dispatch_get_main_queue()) {
                        self.Results.text = NSHTTPURLResponse.localizedStringForStatusCode(httpResponse.statusCode)
                        self.imageView.image = nil
                        self.indicator.stopAnimating()
                        self.ISBN.userInteractionEnabled = true
                        self.noCoverLabel.hidden = true
                    }
                }
            } else {
                dispatch_sync(dispatch_get_main_queue()) {
                    self.Results.text = "Error, por favor revisa tu conexión a internet."
                    self.imageView.image = nil
                    self.indicator.stopAnimating()
                    self.ISBN.userInteractionEnabled = true
                    self.noCoverLabel.hidden = true
                }
            }
        }
        let dt = session.dataTaskWithURL(url!, completionHandler: data)
        dt.resume()
    }
}

