import UIKit

@objc open class FA_Token: NSObject {
    
    open var displayText: String
    open var context: Any
    open var textColor: UIColor?
    open var selectedTextColor: UIColor?
    open var selectedBackgroundColor: UIColor?
    
    public init(displayText: String, context: Any, textColor: UIColor? = nil, selectedTextColor: UIColor? = nil, selectedBackgroundColor: UIColor? = nil) {
        self.displayText = displayText
        self.context = context
        self.textColor = textColor
        self.selectedBackgroundColor = selectedBackgroundColor
        self.selectedTextColor = selectedTextColor
    }
    
    @available(*, deprecated, renamed: "context")
    open var baseObject: AnyObject { get { return context as AnyObject } set { context = newValue }}
}

public func ==(lhs: FA_Token, rhs: FA_Token) -> Bool {
    return lhs.displayText == rhs.displayText
}
