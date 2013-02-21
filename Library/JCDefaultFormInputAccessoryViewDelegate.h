#import <Foundation/Foundation.h>
@class JCDefaultFormInputAccessoryView;

@protocol JCDefaultFormInputAccessoryViewDelegate <NSObject>

@required
- (NSArray*) toolbarItemsForDefaultFormInputAccessoryView:(JCDefaultFormInputAccessoryView*)accessoryView;

@end
