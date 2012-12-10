#import <UIKit/UIKit.h>

@interface JCDefaultFormInputAccessoryView : UIView

+ (id) defaultFormInputAccessoryView;

/** List of input views/descriptors.

 It is acceptable to directly manipuate the list instead of reassigning
 a new list when the list of valid responders changes.

 Each item in the list is expected to be one of the following types:
   - UIResponder (subclass) instance such as UITextField or UITextView.
   - 

 */
@property (strong, nonatomic) NSMutableArray* responders;

/** Parent view of all form elements.

 If set, this view will have its frame adjusted to ensure field visibility
 when the previous/next controls are used. When the input view is dismissed
 (either by the field resigning first responder or the done control being
 used) this view's frame will be returned to its original state.

 @discussion DO NOT set this property if the form view is an instance of UITableView
 that is managed by a UITableViewController instance. UITableViewController
 already adjusts the content inset of its table view automatically to ensure
 that the cell/input is visible.
 
 @discussion If your view is an instance of UITableView, you'll also want to configure
 your responder items with containingTableView and containingTableViewIndexPath
 properties. The responder item will then guarantee that the table view instance
 scrolls to the correct index path before attempting to retrieve the input view
 and call becomeFirstResponder on that input view. This is important for
 for the previous/next buttons to work properly since a table view automatically
 unloads cells that are not currently visible.

 */
@property (weak, nonatomic) UIView* formView;

@property (strong, nonatomic) UIToolbar* toolbar;

- (BOOL) hasPreviousResponder;
- (BOOL) hasNextResponder;

- (void) selectPreviousResponder;
- (void) selectNextResponder;
- (void) selectResponderAtIndex:(NSUInteger)index;

@end
