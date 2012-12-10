#import <Foundation/Foundation.h>

typedef enum JCDefaultFormInputAccessoryViewResponderType {
  JCDefaultFormInputAccessoryViewResponderTypeUIResponder,
  JCDefaultFormInputAccessoryViewResponderTypeCustom
} JCDefaultFormInputAccessoryViewResponderType;

typedef void (^JCDefaultFormInputAccessoryViewCustomActivation)();
typedef UIView* (^JCDefaultFormInputAccessoryViewRespondingViewGetter)();

@interface JCDefaultFormInputAccessoryViewResponderItem : NSObject

+ (id) itemWithContainingTableView:(UITableView*)tableView
                         indexPath:(NSIndexPath*)indexPath
              respondingViewGetter:(JCDefaultFormInputAccessoryViewRespondingViewGetter)respondingViewGetter;

+ (id) itemWithContainingTableView:(UITableView*)tableView
                         indexPath:(NSIndexPath*)indexPath
              respondingViewGetter:(JCDefaultFormInputAccessoryViewRespondingViewGetter)respondingViewGetter
                   customActivator:(JCDefaultFormInputAccessoryViewCustomActivation)customActivator;

+ (id) itemWithRespondingViewGetter:(JCDefaultFormInputAccessoryViewRespondingViewGetter)respondingViewGetter;

+ (id) itemWithRespondingViewGetter:(JCDefaultFormInputAccessoryViewRespondingViewGetter)respondingViewGetter
                    customActivator:(JCDefaultFormInputAccessoryViewCustomActivation)customActivator;

/** Table view ancestor of the responding item.

 If this is set, and the containingTableViewIndexPath is set, then it is
 guaranteed that the table view will scroll such that the cell at the
 containingTableViewIndexPath is visible before this responder item is
 activated.

 @see containingTableViewIndexPath

 */
@property (weak, nonatomic) UITableView* containingTableView;
@property (strong, nonatomic) NSIndexPath* containingTableViewIndexPath;

/** Defines how the item is activated.

 For example, JCDefaultFormInputAccessoryViewResponderTypeUIResponder
 would mean that the item will be activate by calling becomeFirstResponder
 on the item's view.

 Alternatively, JCDefaultFormInputAccessoryViewResponderTypeCustom means
 you can set a custom block action that will be triggered on activation.

 */
@property JCDefaultFormInputAccessoryViewResponderType responderType;

@property (copy, nonatomic) JCDefaultFormInputAccessoryViewCustomActivation customActivator;

@property (copy, nonatomic) JCDefaultFormInputAccessoryViewRespondingViewGetter respondingViewGetter;

- (void) activate;

@end
