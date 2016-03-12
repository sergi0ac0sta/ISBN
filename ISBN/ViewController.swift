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
    
    func parse(data: NSDictionary) -> (title: String, authors: [String]?, cover: NSURL?){
        var bookTitle = ""
        var bookAuthors: [String] = []
        var bookCover: NSURL? = nil
        
        let elements = data["ISBN:" + self.ISBN.text!] as! NSDictionary
        if let t = elements["title"] {
            bookTitle = t as! String
        }
        if let auth = elements["authors"] {
            for a in auth as! NSArray {
                if let n = a["name"] {
                    bookAuthors.append(n as! String)
                }
            }
        }
        if let c = elements["cover"] {
            if let m = c["medium"] {
                bookCover = NSURL(string: m as! String)
            }
        }
        return (bookTitle, bookAuthors, bookCover)
    }
    
    var temp = ""
    
    func search() {
        ISBN.resignFirstResponder()
        let url = NSURL(string: "https://openlibrary.org/api/books?jscmd=data&format=json&bibkeys=ISBN:" + ISBN.text!)
        let session = NSURLSession.sharedSession()
        let data = { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            if let httpResponse = response as? NSHTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    do {
                        let json = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableLeaves) as! NSDictionary
                        if json.count > 0 {
                            let bookData = self.parse(json)
                            dispatch_sync(dispatch_get_main_queue()) {
                                self.Results.text = "Libro:\t" + (bookData.title) + "\n"
                                
                                if let authors = bookData.authors {
                                    if authors.count == 1 {
                                        self.Results.text = self.Results.text + "Autor:\t" + authors[0] + "\n"
                                    } else if authors.count > 1 {
                                        self.Results.text = self.Results.text + "Autores:\t"
                                        for author in authors {
                                            self.Results.text = self.Results.text + author
                                            if author != authors.last {
                                                self.Results.text = self.Results.text + ", "
                                            }
                                        }
                                        self.Results.text = self.Results.text + "\n"
                                    }
                                }
                                if let cover = bookData.cover {
                                    if let data = NSData(contentsOfURL: cover) {
                                        self.noCoverLabel.hidden = true
                                        self.imageView.contentMode = .ScaleAspectFit
                                        self.imageView.image = UIImage(data: data)
                                    }
                                    self.indicator.stopAnimating()
                                    self.ISBN.userInteractionEnabled = true
                                } else {
                                    self.imageView.image = nil
                                    self.noCoverLabel.hidden = false
                                    self.indicator.stopAnimating()
                                    self.ISBN.userInteractionEnabled = true
                                }
                            }
                        } else {
                            dispatch_sync(dispatch_get_main_queue()) {
                                self.Results.text = "No hay resultados."
                                self.imageView.image = nil
                                self.noCoverLabel.hidden = false
                                self.indicator.stopAnimating()
                                self.ISBN.userInteractionEnabled = true
                            }
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

