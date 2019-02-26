//
//  FA_TokenInputView.swift
//  Pods
//
//  Created by Pierre LAURAC on 29/06/2015.
//
//

import Foundation

@objc public protocol FA_TokenInputViewDelegate: class {
  
  /**
   *  Called to check whether a token can be selected
   */
  @objc optional func tokenInputView(_ view: FA_TokenInputView, canSelect token: FA_Token) -> Bool
  
  /**
   *  Called when a token is selected
   */
  @objc optional func tokenInputView(_ view: FA_TokenInputView, didSelect token: FA_Token)
  
  /**
   *  Called when a token is tapped
   */
  @objc optional func tokenInputView(_ view: FA_TokenInputView, didTap token: FA_Token)

  /**
   *  Called when the text field begins editing
   */
  @objc optional func tokenInputViewDidEndEditing(_ view: FA_TokenInputView)
  
  /**
   *  Called when the text field ends editing
   */
  @objc optional func tokenInputViewDidBeginEditing(_ view: FA_TokenInputView)
  
  /**
   * Called when the text field text has changed. You should update your autocompleting UI based on the text supplied.
   */
  @objc optional func tokenInputView(_ view: FA_TokenInputView, didChangeText text: String?)
  
  /**
   * Called when a token has been added. You should use this opportunity to update your local list of selected items.
   */
  @objc optional func tokenInputView(_ tokenView: FA_TokenInputView, didAdd token: FA_Token)
  
  /**
   * Called when a token has been removed. You should use this opportunity to update your local list of selected items.
   */
  @objc optional func tokenInputView(_ tokenView: FA_TokenInputView, didRemove token: FA_Token)
  
  /**
   * Called when the user attempts to press the Return key with text partially typed.
   * @return A CLToken for a match (typically the first item in the matching results),
   * or nil if the text shouldn't be accepted.
   */
  @objc optional func tokenInputView(_ view: FA_TokenInputView, tokenForText text: String) -> FA_Token?
  
  /**
   * Called when the view has updated its own height. If you are
   * not using Autolayout, you should use this method to update the
   * frames to make sure the token view still fits.
   */
  @objc optional func tokenInputView(_ view: FA_TokenInputView, didChangeHeightTo height: CGFloat)
  
  /**
   * Called when the view has received a double tap gesture. If you want to display a menu above
   * the `FA_TokenView` return true.
   * In order to display the items, you should also implement `tokenInputViewMenuItems`
   *
   * @return true if you want to display a UIMenuController element
   */
  @objc optional func tokenInputViewShouldDisplayMenuItems(_ view: FA_TokenInputView) -> Bool
  
  /**
   * Called if the `tokenInputViewShouldDisplayMenuItems` returned true.
   * Return the UIMenuItem you want to display above or below the `FA_Token`
   *
   * @return the array of `UIMenuItem`
   */
  @objc optional func tokenInputView(_ view: FA_TokenInputView, menuItemsFor token: FA_Token) -> [UIMenuItem]
  
  //MARK: Deprecations
  @available(*, unavailable, renamed: "tokenInputView(_:didTap:)")
  @objc optional func tokenInputViewWasClicked(_ view: FA_TokenInputView, token: FA_Token)
  
  @available(*, unavailable, renamed: "tokenInputView(_:didChangeText:)")
  @objc optional func tokenInputViewDidChangeText(_ view: FA_TokenInputView, text theNewText: String)
  
  @available(*, unavailable, renamed: "tokenInputView(_:didAdd:)")
  @objc optional func tokenInputViewDidAddToken(_ view: FA_TokenInputView, token theNewToken: FA_Token)
  
  @available(*, unavailable, renamed: "tokenInputView(_:didRemove:)")
  @objc optional func tokenInputViewDidRemoveToken(_ view: FA_TokenInputView, token removedToken: FA_Token)
  
  @available(*, unavailable, renamed: "tokenInputView(_:didChangeText:)")
  @objc optional func tokenInputViewTokenForText(_ view: FA_TokenInputView, text searchToken: String) -> FA_Token?
  
  @available(*, unavailable, renamed: "tokenInputView(_:didChangeHeightTo:)")
  @objc optional func tokenInputViewDidChangeHeight(_ view: FA_TokenInputView,  height newHeight:CGFloat)
  
  @available(*, unavailable, renamed: "tokenInputView(_:menuItemsFor:)")
  @objc optional func tokenInputViewMenuItems(_ view: FA_TokenInputView, token: FA_Token) -> [UIMenuItem]
}

public enum FA_TokenInputViewMode {
  case view
  case edit
}

open class FA_TokenInputView: UIView {
  
  @IBOutlet weak open var delegate: FA_TokenInputViewDelegate?
  var _fieldView: UIView?
  var _accessoryView: UIView?
  
  @IBInspectable var _fieldName: String?
  @IBInspectable var _placeholderText: String?
  @IBInspectable var _keyboardType: UIKeyboardType = .default
  @IBInspectable var _autocapitalizationType: UITextAutocapitalizationType = .none
  @IBInspectable var _autocorrectionType: UITextAutocorrectionType = .no
  @IBInspectable var _drawBottomBorder: Bool = false
  
  open var allTokens: [FA_Token] {
    return self.tokens.map { $0 }
  }
  
  open var shouldForceRepositionning = false
  
  var text: String {
    return self.textField.text!
  }
  
  var editing: Bool {
    return self.textField.isEditing
  }
  
  var tokenizeOnEndEditing = true
  open var tokenizationCharacters : Set<String> = [","]
  
  open var font: UIFont! {
    didSet {
      self.textField?.font = self.font
      for view in tokenViews {
        view.font = self.font
        view.sizeToFit()
      }
    }
  }
  
  open var fieldNameFont: UIFont! {
    didSet {
      self.fieldLabel?.font = self.fieldNameFont
    }
  }
  
  open var fieldNameColor: UIColor! {
    didSet {
      self.fieldLabel?.textColor = self.fieldNameColor
    }
  }
  
  fileprivate var tokens: [FA_Token] = []
  fileprivate var tokenViews: [FA_TokenView] = []
  fileprivate var textField: FA_BackspaceDetectingTextField!
  fileprivate var fieldLabel: UILabel!
  fileprivate var intrinsicContentHeight: CGFloat!
  fileprivate var displayMode: FA_TokenInputViewMode = .edit
  fileprivate var heightZeroConstraint: NSLayoutConstraint!
  
  fileprivate var textColor: UIColor?
  fileprivate var selectedTextColor: UIColor?
  fileprivate var selectedBackgroundColor: UIColor?
  fileprivate var separatorColor: UIColor = UIColor.white
  
  open var editable: Bool = true {
    didSet {
      displayMode = editable ? .edit : .view
      tokenViews.forEach { $0.displayMode = displayMode }
    }
  }
  
  open var HSPACE: CGFloat = 0.0
  open var textFieldHSpace: CGFloat = 4.0 {
    didSet { repositionViews() }
  }
  
  /// The space betwen each rows
  open var rowsSpacing: CGFloat = 4.0 {
    didSet { repositionViews() }
  }
  
  /// The minimum space the textfield should be. If the space cannot be allocated, then a new line will be created
  open var minimumTextFieldWidth: CGFloat = 10.0 {
    didSet { repositionViews() }
  }
  open var standardRowHeight: CGFloat = 25.0 {
    didSet { repositionViews() }
  }
  open var fieldMarginX: CGFloat = 4.0 {
    didSet { repositionViews() }
  }
  open var padding : UIEdgeInsets = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8) {
    didSet { repositionViews() }
  }
  
  /// Minimum height size for the view if empty
  open var minHeight: CGFloat = 45.0 {
    didSet { invalidateIntrinsicContentSize() }
  }
  
  public convenience init() {
    self.init(mode: .edit)
  }
  
  public init(mode: FA_TokenInputViewMode) {
    super.init(frame: CGRect.zero)
    self.commonInit(mode)
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    self.commonInit()
  }
  
  required public init?(coder aDecoder: NSCoder) {
    
    super.init(coder: aDecoder)
    self.commonInit()
  }
  
  func commonInit(_ mode: FA_TokenInputViewMode = .edit) {
    
    self.font = UIFont.systemFont(ofSize: 17.0)
    self.textField = FA_BackspaceDetectingTextField(frame: self.bounds)
    self.textField.backgroundColor = UIColor.clear
    self.textField.keyboardType = self.keyboardType;
    self.textField.autocorrectionType = self.autocorrectionType;
    self.textField.autocapitalizationType = self.autocapitalizationType;
    self.textField.delegate = self
    self.textField.addTarget(self, action: #selector(FA_TokenInputView.onTextFieldDidChange(_:)), for: .editingChanged)
    self.textField.addTarget(self, action: #selector(FA_TokenInputView.onTextFieldDidEndEditing(_:)), for: .editingDidEnd)
    self.textField.isUserInteractionEnabled = false
    self.addSubview(self.textField)
    
    self.fieldLabel = UILabel(frame: CGRect.zero)
    self.fieldLabel.textColor = UIColor.lightGray
    self.addSubview(self.fieldLabel)
    self.fieldLabel.isHidden = true
    
    self.backgroundColor = UIColor.clear
    self.intrinsicContentHeight = self.standardRowHeight
    
    self.clipsToBounds = true
    self.displayMode = mode
    self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(FA_TokenInputView.viewWasTapped)))
    self.heightZeroConstraint = NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 0.0)
    
    self.repositionViews()
  }
  
  override open var intrinsicContentSize : CGSize {
    return CGSize(width: UIView.noIntrinsicMetric, height: max(self.minHeight, self.intrinsicContentHeight))
  }
  open override func tintColorDidChange() {
    super.tintColorDidChange()
    self.setColors(textColor, selectedTextColor: selectedTextColor, selectedBackgroundColor: selectedBackgroundColor)
  }
  open func setColors(_ textColor: UIColor?, selectedTextColor: UIColor?, selectedBackgroundColor: UIColor?) {
    
    self.textColor = textColor
    self.selectedTextColor = selectedTextColor
    self.selectedBackgroundColor = selectedBackgroundColor
    
    self.tokenViews.forEach { (tokenView) in
      tokenView.setColors(textColor, selectedTextColor: selectedTextColor, selectedBackgroundColor: selectedBackgroundColor)
    }
  }
  
  open func add(_ token: FA_Token) {
    if self.tokens.contains(token) {
      return
    }
    
    self.tokens.append(token)
    let tokenView = FA_TokenView(token: token, displayMode: self.displayMode)
    tokenView.font = self.font
    tokenView.delegate = self;
    tokenView.setColors(token.textColor ?? self.textColor,
                        selectedTextColor: token.selectedTextColor ?? self.selectedTextColor,
                        selectedBackgroundColor: token.selectedBackgroundColor ?? self.selectedBackgroundColor)
    
    let intrinsicSize = tokenView.intrinsicContentSize
    tokenView.frame = CGRect(x: 0, y: 0, width: intrinsicSize.width, height: intrinsicSize.height)
    self.tokenViews.append(tokenView)
    self.addSubview(tokenView)
    self.textField.text = ""
    self.delegate?.tokenInputView?(self, didAdd: token)
    
    // Clearing text programmatically doesn't call this automatically
    self.onTextFieldDidChange(self.textField)
    
    self.updatePlaceholderTextVisibility()
    self.repositionViews()
  }
  
  open func setHeightToZero() {
    self.addConstraint(self.heightZeroConstraint)
  }
  
  open func setHeightToAuto() {
    self.removeConstraint(self.heightZeroConstraint)
  }
  
  /**
   * This method removes all tokens of the `FA_TokenInputView`.
   *
   * For each token removed, the delegate method `tokenInputViewDidRemoveToken` will be called if implemented.
   */
  open func removeAllTokens() {
    let tokens = self.tokens
    let tokenViews = self.tokenViews
    self.tokens = []
    self.tokenViews = []
    
    tokens.forEach {
      self.delegate?.tokenInputView?(self, didRemove: $0)
    }
    
    tokenViews.forEach {
      $0.removeFromSuperview()
    }
    
    self.repositionViews()
  }
  
  open func remove(_ token: FA_Token) {
    if let index = self.tokens.firstIndex(of: token) {
      self.removeTokenAtIndex(index)
    }
  }
  open func replace(_ previousToken: FA_Token, by newToken: FA_Token) {
    guard let index = self.tokens.firstIndex(of: previousToken) else {
      return
    }
    UIView.animate(withDuration: CATransaction.animationDuration(), animations: {
      let tokenView = self.tokenViews[index]
      tokenView.setColors(newToken.textColor, selectedTextColor: newToken.selectedTextColor, selectedBackgroundColor: newToken.selectedBackgroundColor)
    })
  }
  
  open func setInputAccessoryView(_ view: UIView?) {
    self.textField.inputAccessoryView = view
  }
  
  open func forceTokenizeCurrentText() {
    self.tokenizeTextFieldText()
  }
  
  fileprivate func removeTokenAtIndex(_ index: Int) {
    let tokenView = self.tokenViews[index]
    tokenView.removeFromSuperview()
    self.tokenViews.remove(at: index)
    
    let removedToken = self.tokens.remove(at: index)
    self.delegate?.tokenInputView?(self, didRemove: removedToken)
    
    self.updatePlaceholderTextVisibility()
    self.repositionViews()
  }
  
  /**
   * Returns the editable textfield view.
   */
  open func getTextFieldView() -> UITextField {
    return self.textField
  }
  
  @discardableResult fileprivate func tokenizeTextFieldText() -> FA_Token? {
    guard let text = self.textField.text, !text.isEmpty,
      let token = self.delegate?.tokenInputView?(self, tokenForText: text) else {
        return nil
    }
    self.add(token)
    self.onTextFieldDidChange(self.textField)
    return token
  }
  
  fileprivate func textFieldDisplayOffset() -> CGFloat {
    // Essentially the textfield's y with PADDING_TOP
    return self.textField.frame.minY - self.padding.top
  }
  
  fileprivate func repositionViews() {
    let bounds = self.bounds
    
    if bounds.height == 0 && !shouldForceRepositionning {
      self.repositionViewZeroHeight()
      return
    }
    
    self.shouldForceRepositionning = false
    
    let rightBoundary = bounds.width - self.padding.right
    var firstLineRightBoundary = rightBoundary
    
    var curX = self.padding.left
    var curY = self.padding.top
    var yPositionForLastToken: CGFloat = 0.0
    
    // Position field view (if set)
    if let fieldView = self.fieldView {
      fieldView.sizeToFit()
      var fieldViewRect = fieldView.frame
      fieldViewRect.origin.x = curX + self.fieldMarginX
      fieldViewRect.origin.y = curY + ((self.standardRowHeight - fieldViewRect.height)/2.0)
      fieldView.frame = fieldViewRect
      
      curX = fieldViewRect.maxX + self.fieldMarginX
    }
    
    // Position field label (if field name is set)
    if !self.fieldLabel.isHidden {
      self.fieldLabel.sizeToFit()
      var fieldLabelRect = self.fieldLabel.frame
      fieldLabelRect.origin.x = curX + self.fieldMarginX
      fieldLabelRect.origin.y = curY + ((self.standardRowHeight-fieldLabelRect.height)/2.0)
      self.fieldLabel.frame = fieldLabelRect
      
      curX = fieldLabelRect.maxX + self.fieldMarginX
    }
    
    // Position accessory view (if set)
    if let accessoryView = self.accessoryView {
      accessoryView.sizeToFit()
      var accessoryRect = accessoryView.frame
      accessoryRect.origin.x = bounds.width - self.padding.right - accessoryRect.width
      accessoryRect.origin.y = curY
      accessoryView.frame = accessoryRect
      
      firstLineRightBoundary = accessoryRect.minX - self.HSPACE
    }
    
    // Position token views
    var tokenRect = CGRect.null
    var tokensByLine: [Int: Int] = [0:0]
    var currentLine = 0
    
    for view in self.tokenViews {
      view.sizeToFit()
      tokenRect = view.frame
      
      let tokenBoundary = currentLine == 0 ? firstLineRightBoundary : rightBoundary
      let hasOtherToken = (tokensByLine[currentLine] ?? 0) != 0
      if (curX + tokenRect.width > tokenBoundary && hasOtherToken) {
        // Need a new line
        currentLine += 1
        tokensByLine[currentLine] = 0
        curX = self.padding.left
        curY += self.standardRowHeight+self.rowsSpacing
      }
      
      tokensByLine[currentLine] = tokensByLine[currentLine]! + 1
      
      tokenRect.origin.x = curX
      // Center our tokenView vertially within STANDARD_ROW_HEIGHT
      tokenRect.origin.y = curY + ((self.standardRowHeight-tokenRect.height)/2.0)
      if tokenRect.width > self.getMaxLineWidth() {
        tokenRect.size.width = self.getMaxLineWidth()
      }
      view.frame = tokenRect
      
      curX = tokenRect.maxX + self.HSPACE
      yPositionForLastToken = tokenRect.origin.y
      view.setSeparatorVisibility(view != self.tokenViews.last || self.editing)
    }
    
    
    
    // Always indent textfield by a little bit
    curX += self.textFieldHSpace
    let textBoundary = currentLine == 0 ? firstLineRightBoundary : rightBoundary
    var availableWidthForTextField = textBoundary - curX
    if (availableWidthForTextField < self.minimumTextFieldWidth) {
      curX = self.padding.left + self.textFieldHSpace
      curY += self.standardRowHeight+self.rowsSpacing
      // Adjust the width
      availableWidthForTextField = rightBoundary - curX
    }
    
    if (!self.editing && curY > yPositionForLastToken && !self.tokens.isEmpty) {
      // check if there is another token on the line and if not we should remove the line height
      curY -= self.standardRowHeight+self.rowsSpacing
    }
    
    self.textField.frame = CGRect(x: curX, y: curY, width: availableWidthForTextField, height: self.standardRowHeight)
    
    if self.displayMode == .view {
      self.textField.frame = CGRect.zero
    }
    
    let oldContentHeight = self.intrinsicContentHeight
    self.intrinsicContentHeight = self.getIntrinsincContentHeightAfterReposition()
    self.invalidateIntrinsicContentSize()
    
    if (oldContentHeight != self.intrinsicContentHeight) {
      self.delegate?.tokenInputView?(self, didChangeHeightTo: self.intrinsicContentSize.height)
    }
    self.setNeedsDisplay()
    
  }
  
  fileprivate func getMaxLineWidth() -> CGFloat {
    return self.frame.width - self.padding.right - self.padding.left
  }
  
  fileprivate func getIntrinsincContentHeightAfterReposition() -> CGFloat {
    if self.editing {
      return self.textField.frame.maxY+self.padding.bottom
    }
    
    guard let view = self.tokenViews.last else {
      return 0
    }
    
    return view.frame.maxY+self.padding.bottom
  }
  
  fileprivate func repositionViewZeroHeight() {
    if let fieldView = self.fieldView {
      let frame = fieldView.frame
      fieldView.frame = CGRect(x: frame.origin.x, y: frame.origin.y, width: frame.width, height: 0)
    }
    if let accessoryView = self.accessoryView {
      let frame = accessoryView.frame
      accessoryView.frame = CGRect(x: frame.origin.x, y: frame.origin.y, width: frame.width, height: 0)
    }
    let flFrame = fieldLabel.frame
    fieldLabel.frame = CGRect(x: flFrame.origin.x, y: flFrame.origin.y, width: flFrame.width, height: 0)
    
    let tfFrame = textField.frame
    textField.frame = CGRect(x: tfFrame.origin.x, y: tfFrame.origin.y, width: tfFrame.width, height: 0)
    
    for view in self.tokenViews {
      let frame = view.frame
      view.frame = CGRect(x: frame.origin.x, y: frame.origin.y, width: frame.width, height: 0)
    }
  }
  
  override open func layoutSubviews() {
    self.repositionViews()
    super.layoutSubviews()
  }
  
  fileprivate func updatePlaceholderTextVisibility() {
    if self.tokens.isEmpty {
      self.textField.placeholder = self.placeholderText
    } else {
      self.textField.placeholder = nil
    }
  }
  
  @objc func onTextFieldDidChange(_ textfield: UITextField) {
    delegate?.tokenInputView?(self, didChangeText: textField.text)
  }
  
  @objc func onTextFieldDidEndEditing(_ textfield: UITextField) {
    self.repositionViews()
  }
  
  @objc func viewWasTapped() {
    self.unselectAllTokenViewsAnimated()
    if self.displayMode == .view {
      return
    }
    self.beginEditing()
  }
}

// MARK: - Token Selection
extension FA_TokenInputView {
  func selectTokenView(tokenView theView: FA_TokenView) {
    theView.selected = true
    for view in self.tokenViews {
      if view != theView {
        view.selected = false
      }
    }
  }
  
  func unselectAllTokenViewsAnimated() {
    for view in self.tokenViews {
      view.selected = false
    }
  }
}

// MARK: - Editing
extension FA_TokenInputView {
  
  public func beginEditing() {
    
    if self.displayMode == .view {
      return
    }
    self.textField.isUserInteractionEnabled = true
    self.textField.becomeFirstResponder()
    UIView.performWithoutAnimation {
      self.unselectAllTokenViewsAnimated()
      self.repositionViews()
    }
  }
  
  public func endEditing() {
    self.resignFirstResponder()
    self.repositionViews()
    self.textField.isUserInteractionEnabled = false
  }
}

// MARK: - UItextField delegate method
extension FA_TokenInputView: UITextFieldDelegate  {
  
  public func textFieldDidBeginEditing(_ textField: UITextField) {
    self.accessoryView?.isHidden = false
    self.delegate?.tokenInputViewDidBeginEditing?(self)
    self.unselectAllTokenViewsAnimated()
  }
  
  public func textFieldDidEndEditing(_ textField: UITextField) {
    self.accessoryView?.isHidden = true
    self.delegate?.tokenInputViewDidEndEditing?(self)
    if self.tokenizeOnEndEditing {
      self.tokenizeTextFieldText()
    }
  }
  
  public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    self.tokenizeTextFieldText()
    return false
  }
  
  public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    if !string.isEmpty && tokenizationCharacters.contains(string) {
      tokenizeTextFieldText()
      // Never allow the change if it matches at token
      return false
    }
    return true
  }
}

// MARK: - TextField customazation
extension FA_TokenInputView {
  var keyboardType: UIKeyboardType {
    get { return self._keyboardType }
    set {
      self._keyboardType = newValue
      self.textField.keyboardType = _keyboardType
    }
  }
  
  var autocapitalizationType: UITextAutocapitalizationType {
    get { return self._autocapitalizationType }
    set {
      self._autocapitalizationType = newValue
      self.textField.autocapitalizationType = _autocapitalizationType
    }
  }
  
  var autocorrectionType: UITextAutocorrectionType {
    get { return self._autocorrectionType }
    set {
      self._autocorrectionType = newValue
      self.textField.autocorrectionType = _autocorrectionType
    }
  }
}

// MARK: - Optional views
extension FA_TokenInputView {
  
  public var fieldName: String? {
    get { return self._fieldName }
    set {
      if _fieldName == newValue {
        return
      }
      let previous = _fieldName
      
      let showField = !(newValue?.isEmpty ?? true)
      self._fieldName = newValue
      self.fieldLabel.text = _fieldName
      self.fieldLabel.sizeToFit()
      self.fieldLabel.isHidden = !showField
      
      if showField && !(self.fieldLabel.superview != nil) {
        self.addSubview(self.fieldLabel)
      } else if !showField && (self.fieldLabel.superview != nil) {
        self.fieldLabel.removeFromSuperview()
      }
      
      if previous == nil || !(previous == _fieldName) {
        self.repositionViews()
      }
    }
  }
  
  public var fieldView: UIView? {
    get { return self._fieldView }
    set {
      if _fieldView == newValue {
        return
      }
      _fieldView?.removeFromSuperview()
      _fieldView = newValue
      if let _fieldView = _fieldView {
        self.addSubview(_fieldView)
      }
      self.repositionViews()
    }
  }
  
  public var placeholderText: String? {
    get { return _placeholderText }
    set {
      if _placeholderText == newValue {
        return
      }
      _placeholderText = newValue
      self.updatePlaceholderTextVisibility()
    }
  }
  
  public var accessoryView: UIView? {
    get { return _accessoryView }
    set {
      if _accessoryView == newValue {
        return
      }
      _accessoryView?.removeFromSuperview()
      _accessoryView = newValue
      _accessoryView?.isHidden = true
      if let _accessoryView = _accessoryView {
        self.addSubview(_accessoryView)
      }
      self.repositionViews()
    }
  }
  
}

// Mark: Drawing
extension FA_TokenInputView {
  public var drawBottomBorder: Bool {
    get { return _drawBottomBorder }
    set {
      if _drawBottomBorder == newValue {
        return
      }
      _drawBottomBorder = newValue
      self.setNeedsDisplay()
    }
  }
  
  // Only override drawRect: if you perform custom drawing.
  // An empty implementation adversely affects performance during animation.
  override open func draw(_ rect: CGRect) {
    super.draw(rect)
    if self.drawBottomBorder {
      
      let context = UIGraphicsGetCurrentContext()
      let bounds = self.bounds
      context?.setStrokeColor(UIColor.lightGray.cgColor)
      context?.setLineWidth(0.5)
      
      context?.move(to: CGPoint(x: 0, y: bounds.size.height))
      context?.addLine(to: CGPoint(x: bounds.width, y: bounds.size.height))
      context?.strokePath()
    }
  }
}


// MARK: - FA_TokenViewDelegate
extension FA_TokenInputView: FA_TokenViewDelegate {
  func tokenViewWasTapped(_ tokenView: FA_TokenView) {
    self.delegate?.tokenInputView?(self, didSelect: tokenView.token)
  }
  
  func tokenViewDidRequestDelete(_ tokenView: FA_TokenView, replaceWithText theText: String?) {
    if self.displayMode == .view {
      return
    }
    // First, refocus the text field
    self.textField.becomeFirstResponder()
    if !(theText?.isEmpty ?? true) {
      self.textField.text = theText
    }
    // Then remove the view from our data
    if let index = self.tokenViews.index(of: tokenView) {
      self.removeTokenAtIndex(index)
    }
  }
  
  func tokenViewDidRequestSelection(_ tokenView: FA_TokenView) {
    if self.delegate?.tokenInputView?(self, canSelect: tokenView.token) ?? true {
      self.selectTokenView(tokenView: tokenView)
      self.delegate?.tokenInputView?(self, didSelect: tokenView.token)
    }
  }
  
  func tokenViewShouldDisplayMenu(_ tokenView: FA_TokenView) -> Bool {
    guard let should = self.delegate?.tokenInputViewShouldDisplayMenuItems?(self) else { return false }
    return should
  }
  
  func tokenViewMenuItems(_ tokenView: FA_TokenView) -> [UIMenuItem] {
    guard let items = self.delegate?.tokenInputView?(self, menuItemsFor: tokenView.token) else { return [] }
    return items
  }
}

// MARK: FA_BackspceDetectingTextfield delegate
extension FA_TokenInputView: FA_BackspaceDetectingTextFieldDelegate {
  func textFieldDidDeleteBackward(_ textField: UITextField) {
    // Delay selecting the next token slightly, so that on iOS 8
    // the deleteBackward on CLTokenView is not called immediately,
    // causing a double-delete
    DispatchQueue.main.async(execute: {
      if textField.text?.isEmpty ?? true {
        
        if let tokenView = self.tokenViews.last {
          self.selectTokenView(tokenView: tokenView)
          self.textField.resignFirstResponder()
        }
      }
    })
  }
}

//MARK: Deprecations
extension FA_TokenInputView {
  @available(*, deprecated, renamed: "minHeight")
  open var MINIMUM_VIEW_HEIGHT: CGFloat { get { return minHeight } set { minHeight = newValue }}
  @available(*, deprecated, message: "use padding.top instead")
  open var PADDING_TOP: CGFloat { get { return padding.top } set { padding.top = newValue }}
  @available(*, deprecated, message: "use padding.bottom instead")
  open var PADDING_BOTTOM: CGFloat { get { return padding.bottom } set { padding.bottom = newValue }}
  @available(*, deprecated, message: "use padding.left instead")
  open var PADDING_LEFT: CGFloat { get { return padding.left } set { padding.left = newValue }}
  @available(*, deprecated, message: "use padding.right instead")
  open var PADDING_RIGHT: CGFloat { get { return padding.right } set { padding.right = newValue }}
  
  @available(*, deprecated, renamed: "minimumTextFieldWidth")
  open var MINIMUM_TEXTFIELD_WIDTH: CGFloat { get { return minimumTextFieldWidth } set { minimumTextFieldWidth = newValue } }
  
  @available(*, deprecated, renamed: "standardRowHeight")
  open var STANDARD_ROW_HEIGHT: CGFloat { get { return standardRowHeight} set { standardRowHeight = newValue }}
  
  @available(*, deprecated, renamed: "rowsSpacing")
  open var VERTICAL_SPACE_BETWEEN_ROWS: CGFloat { get { return rowsSpacing } set { rowsSpacing = newValue }}
  
  @available(*, deprecated, renamed: "fieldMarginX")
  open var FIELD_MARGIN_X: CGFloat { get { return fieldMarginX } set { fieldMarginX = newValue }}
  
  @available(*, deprecated, renamed: "textFieldHSpace")
  open var TEXT_FIELD_HSPACE: CGFloat { get { return textFieldHSpace } set { textFieldHSpace = newValue }}
  
  @available(*, deprecated, renamed: "add(_:)")
  open func addToken(token theToken: FA_Token) {
    add(theToken)
  }
  @available(*, deprecated, renamed: "remove(_:)")
  open func remove(token theToken: FA_Token) {
    remove(theToken)
  }
}
