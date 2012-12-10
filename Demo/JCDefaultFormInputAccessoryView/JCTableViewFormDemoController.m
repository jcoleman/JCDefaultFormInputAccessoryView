#import "JCTableViewFormDemoController.h"
#import "JCDefaultFormInputAccessoryView.h"
#import "JCDefaultFormInputAccessoryViewResponderItem.h"

@interface JCTableViewFormDemoController ()
@property (nonatomic, strong) JCDefaultFormInputAccessoryView* inputAccessoryView;
@end

@implementation JCTableViewFormDemoController

- (void) viewDidLoad {
  [super viewDidLoad];

  self.inputAccessoryView = [JCDefaultFormInputAccessoryView defaultFormInputAccessoryView];

  NSMutableArray* responders = [NSMutableArray new];
  NSUInteger sectionCount = [self.tableView.dataSource numberOfSectionsInTableView:self.tableView];
  for (NSInteger section = 0; section < sectionCount; ++section) {
    NSUInteger rowCount = [self.tableView.dataSource tableView:self.tableView numberOfRowsInSection:section];
    for (NSInteger row = 0; row < rowCount; ++row) {
      NSIndexPath* indexPath = [NSIndexPath indexPathForRow:row inSection:section];
      JCDefaultFormInputAccessoryViewRespondingViewGetter respondingViewGetter = ^UIView *{
        UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];
        UITextField* textField;
        for (UIView* subview in cell.contentView.subviews) {
          if ([subview isKindOfClass:[UITextField class]]) {
            textField = (UITextField*)subview;
            break;
          }
        }
        return textField;
      };
      [responders addObject:[JCDefaultFormInputAccessoryViewResponderItem itemWithContainingTableView:self.tableView
                                                                                            indexPath:indexPath
                                                                                 respondingViewGetter:respondingViewGetter]];
    }
  }
  self.inputAccessoryView.responders = responders;
}

@end
