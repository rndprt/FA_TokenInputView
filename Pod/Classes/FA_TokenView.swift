//
//  FA_TokenView.swift
//  Pods
//
//  Created by Pierre LAURAC on 29/06/2015.
//
//

import Foundation

protocol FA_TokenViewDelegate: class {
  func tokenViewDidRequestDelete(_ tokenView: FA_TokenView, replaceWithText theText: String?)
  func tokenViewWasTapped(_ tokenView: FA_TokenView)
  func tokenViewDidRequestSelection(_ tokenView: FA_TokenView)
  func tokenViewShouldDisplayMenu(_ tokenView: FA_TokenView) -> Bool
  func tokenViewMenuItems(_ tokenView: FA_TokenView) -> [UIMenuItem]
}

class FA_TokenView: UIView {
  
  var token: FA_Token!
  var displayText: String
  var autocorrectionType: UITextAutocorrectionType = .no
  var displayMode: FA_TokenInputViewMode = .view
  
  weak var delegate: FA_TokenViewDelegate?
  var selected = false {
    didSet {
      guard selected != oldValue else { return }
      
      if (selected && self.displayMode == .edit) {
        self.becomeFirstResponder()
      }
      
      let selectedAlpha: CGFloat = self.selected ? 1.0 : 0.0
      if self.selected {
        self.selectedBackgroundView.alpha = 0.0
        self.selectedBackgroundView.isHidden = false
        self.selectedLabel.alpha = 0.0
        self.selectedLabel.isHidden = false
      }
      UIView.animate(withDuration: CATransaction.animationDuration(), animations: {
        self.selectedBackgroundView.alpha = selectedAlpha
        self.selectedLabel.alpha = selectedAlpha
      }, completion: { (_) in
        if !self.selected {
          self.selectedBackgroundView.isHidden = true
          self.selectedLabel.isHidden = true
        }
      })
    }
  }
  
  fileprivate static let PADDING_X: CGFloat = 4.0
  fileprivate static let PADDING_Y: CGFloat = 2.0
  fileprivate var label: FA_TokenLabel!
  fileprivate var selectedBackgroundView: UIView!
  fileprivate var selectedLabel: UILabel!
  
  fileprivate var textColor: UIColor?
  fileprivate var selectedTextColor: UIColor?
  fileprivate var selectedBackgroundColor: UIColor?
  fileprivate var separatorColor: UIColor!
  
  var font: UIFont! {
    didSet {
      self.label.font = self.font
      self.selectedLabel.font = self.font
      self.invalidateIntrinsicContentSize()
    }
  }
  
  init(token theToken: FA_Token, displayMode: FA_TokenInputViewMode = .edit) {
    self.displayText = theToken.displayText
    
    super.init(frame: CGRect.zero)
    
    self.displayMode = displayMode
    self.separatorColor = UIColor.lightGray
    self.selectedTextColor = UIColor.white
    
    self.token = theToken
    var tintColor = UIColor(red: 0.0823, green: 0.4941, blue: 0.9843, alpha: 1.0)
    if let tint = self.tintColor {
      tintColor = tint
    }
    self.label = FA_TokenLabel(frame: CGRect(x: FA_TokenView.PADDING_X, y: FA_TokenView.PADDING_Y, width: 0, height: 0))
    self.label.textColor = tintColor
    self.label.backgroundColor = UIColor.clear
    self.addSubview(label)
    
    self.selectedBackgroundView = UIView(frame: CGRect.zero)
    self.selectedBackgroundView.backgroundColor = tintColor
    self.selectedBackgroundView.layer.cornerRadius = 3.0
    self.selectedBackgroundView.isHidden = true
    self.addSubview(self.selectedBackgroundView)
    
    self.selectedLabel = UILabel(frame: CGRect(x: FA_TokenView.PADDING_X, y: FA_TokenView.PADDING_Y, width: 0, height: 0))
    self.selectedLabel.textColor = UIColor.white
    self.selectedLabel.backgroundColor = UIColor.clear
    self.selectedLabel.isHidden = true
    self.addSubview(self.selectedLabel)
    
    
    // Configure for the token, unselected shows "[displayText]," and selected is "[displayText]"
    let labelString = "\(self.displayText),"
    let attrString = NSMutableAttributedString(string: labelString, attributes: [
      .font : self.label.font,
      .foregroundColor : UIColor.lightGray
      ])
    let tintRange = (labelString as NSString).range(of: self.displayText)
    
    // Make the name part the system tint color
    attrString.setAttributes([.foregroundColor : tintColor], range: tintRange)
    
    self.label.attributedText = attrString
    self.selectedLabel.text = self.displayText
    
    // Listen for taps
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(FA_TokenView.handleTapGestureRecognizer(_:)))
    let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(FA_TokenView.handleLongPressGestureRecognizer(_:)))
    longPressGesture.minimumPressDuration = 0.5
    tapGesture.require(toFail: longPressGesture)
    
    self.addGestureRecognizer(tapGesture)
    self.addGestureRecognizer(longPressGesture)
    self.setNeedsLayout()
    
  }
  
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func tintColorDidChange() {
    super.tintColorDidChange()
    updateColors()
  }
  
  override var intrinsicContentSize : CGSize {
    let size = self.selectedLabel.intrinsicContentSize
    return CGSize(width: size.width+(2.0*FA_TokenView.PADDING_X), height: size.height+(2.0*FA_TokenView.PADDING_Y))
  }
  
  override func sizeThatFits(_ size: CGSize) -> CGSize {
    let fittingSize = CGSize(width: size.width-(2.0*FA_TokenView.PADDING_X), height: size.height-(2.0*FA_TokenView.PADDING_Y))
    let labelSize = self.selectedLabel.sizeThatFits(fittingSize)
    return CGSize(width: labelSize.width+(2.0*FA_TokenView.PADDING_X), height: labelSize.height+(2.0*FA_TokenView.PADDING_Y))
  }
  
  func setSeparatorVisibility(_ visible: Bool) {
    self.displayText = self.token.displayText
    let labelString = "\(self.displayText),"
    let attrString = NSMutableAttributedString(string: labelString, attributes: [
      .font : self.label.font,
      .foregroundColor : visible ? UIColor.lightGray : UIColor.clear
      ])
    let tintRange = (labelString as NSString).range(of: self.displayText)
    
    // Make the name part the system tint color
    attrString.setAttributes([.foregroundColor : self.textColor ?? self.tintColor!], range: tintRange)
    self.label.attributedText = attrString
  }
  
  
  func setColors(_ textColor: UIColor?, selectedTextColor: UIColor?, selectedBackgroundColor: UIColor?) {
    self.textColor = textColor
    self.selectedTextColor = selectedTextColor
    self.selectedBackgroundColor = selectedBackgroundColor
    self.updateColors()
  }
  
  func updateColors() {
    
    self.label.textColor = self.textColor ?? self.tintColor
    self.selectedBackgroundView.backgroundColor = self.selectedBackgroundColor ?? self.tintColor
    self.selectedLabel.textColor = self.selectedTextColor ?? UIColor.white
    
    let attrString: AnyObject = self.label.attributedText!.mutableCopy() as AnyObject
    let tintRange = NSMakeRange(0, self.displayText.count)
    // Make the overall text color gray
    attrString.setAttributes([.foregroundColor: self.separatorColor], range:NSMakeRange(attrString.length - 1, 1))
    // Make the name part the system tint color
    attrString.setAttributes([.foregroundColor : self.textColor ?? self.tintColor!], range:tintRange)
    if let attrString = attrString as? NSAttributedString {
      self.label.attributedText = attrString
    }
  }
  
  @objc func handleTapGestureRecognizer(_ recognizer: UITapGestureRecognizer) {
    self.delegate?.tokenViewWasTapped(self)
    self.delegate?.tokenViewDidRequestSelection(self)
  }
  
  @objc func handleLongPressGestureRecognizer(_ recognizer: UITapGestureRecognizer) {
    guard let delegate = self.delegate else { return }
    if recognizer.state != .began {
      return
    }
    
    if !delegate.tokenViewShouldDisplayMenu(self) {
      return
    }
    
    let items = delegate.tokenViewMenuItems(self)
    if items.isEmpty {
      return
    }
    self.label.becomeFirstResponder()
    delegate.tokenViewDidRequestSelection(self)
    let menu = UIMenuController.shared
    menu.menuItems = items
    menu.setTargetRect(self.bounds, in: self)
    menu.setMenuVisible(true, animated: true)
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    
    let bounds = self.bounds
    
    //self.backgroundView.frame = bounds
    self.selectedBackgroundView.frame = bounds
    
    var labelFrame = bounds.insetBy(dx: FA_TokenView.PADDING_X, dy: FA_TokenView.PADDING_Y)
    self.selectedLabel.frame = labelFrame;
    labelFrame.size.width += FA_TokenView.PADDING_X*2.0;
    self.label.frame = labelFrame;
    
  }
  
  override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
    return false
  }
  
  override var canBecomeFirstResponder : Bool {
    return true
  }
  
}

extension FA_TokenView: UIKeyInput {
  var hasText : Bool {
    return true
  }
  
  func insertText(_ text: String) {
    self.delegate?.tokenViewDidRequestDelete(self, replaceWithText: text)
  }
  
  func deleteBackward() {
    self.delegate?.tokenViewDidRequestDelete(self, replaceWithText: nil)
  }
  
}
