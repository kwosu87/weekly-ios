//
//  TodoPointCell.swift
//  Weekly
//
//  Created by YunSeungyong on 2015. 8. 2..
//  Copyright © 2015년 Wooseong Kim. All rights reserved.
//

import UIKit
import Foundation

@objc protocol TodoPointCellDelegate {
    func doneStateChange(state: NSNumber, section:Int, row: Int)
}

class TodoPointCell: UITableViewCell {
    
    var delegate : TodoPointCellDelegate?
    
    var currentSection : Int?
    var currentRow : Int?
    var currentState : NSNumber?
    var state : NSNumber {
        get {
            return currentState!
        }
        set(newState) {
            if newState == 0 {
                changeToUndone()
            } else {
                changeToDone()
            }
            currentState = newState
        }
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        selectionStyle = UITableViewCellSelectionStyle.None
        
        let tapGestureRecognizer = UITapGestureRecognizer(target:self, action:"imageTapped:")
        tapGestureRecognizer.numberOfTapsRequired = 1;
        imageView?.userInteractionEnabled = true
        imageView!.addGestureRecognizer(tapGestureRecognizer)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func imageTapped(sender: AnyObject) {
        if currentState == 0 {
            changeToDone()
        } else {
            changeToUndone()
        }
        
        delegate?.doneStateChange(state, section: currentSection!, row: currentRow!)
    }
    
    func changeToDone() {
        currentState = 1
        let doneIcon = UIImage(named: "TodoDoneIcon")
        imageView?.image = doneIcon
        textLabel?.textColor = UIColor.lightGrayColor()
        
        delegate?.doneStateChange(state, section: currentSection!, row: currentRow!)
        
        strikeLabel()
    }
    
    func changeToUndone() {
        currentState = 0
        let undoneIcon = UIImage(named: "TodoUndoneIcon")
        imageView?.image = undoneIcon
        textLabel?.textColor = UIColor.blackColor()
        
        
        unstrikeLabel()
    }
    
    func strikeLabel() {
        let targetString = textLabel != nil ? textLabel?.text : ""
        let attributedString:NSMutableAttributedString = NSMutableAttributedString(string: targetString!)
        attributedString.addAttribute(NSStrikethroughColorAttributeName, value: UIColor.lightGrayColor(), range: NSMakeRange(0, attributedString.length))
        
        let attributes = [NSStrikethroughStyleAttributeName : NSUnderlineStyle.StyleSingle.rawValue]
        attributedString.addAttributes(attributes, range: NSMakeRange(0, attributedString.length))
        
        textLabel?.attributedText = attributedString
    }
    
    func unstrikeLabel() {
        let targetString = textLabel != nil ? textLabel?.text : ""
        let attributedString:NSMutableAttributedString = NSMutableAttributedString(string: targetString!)
        attributedString.removeAttribute(NSStrikethroughColorAttributeName, range: NSMakeRange(0, attributedString.length))
        attributedString.removeAttribute(NSStrikethroughStyleAttributeName, range: NSMakeRange(0, attributedString.length))
        textLabel?.attributedText = attributedString
    }
}
