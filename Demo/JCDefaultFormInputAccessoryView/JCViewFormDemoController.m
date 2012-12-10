#import "JCViewFormDemoController.h"
#import "JCDefaultFormInputAccessoryView.h"
#import "JCDefaultFormInputAccessoryViewResponderItem.h"

@interface JCViewFormDemoController ()

@property (nonatomic, strong) JCDefaultFormInputAccessoryView* inputAccessoryView;

@property (weak, nonatomic) IBOutlet UITextField* textField1;
@property (weak, nonatomic) IBOutlet UITextField* textField2;
@property (weak, nonatomic) IBOutlet UITextField* textField3;
@property (weak, nonatomic) IBOutlet UITextField* textField4;

@end

@implementation JCViewFormDemoController

- (void) viewDidLoad {
  [super viewDidLoad];

  self.inputAccessoryView = [JCDefaultFormInputAccessoryView defaultFormInputAccessoryView];
  self.inputAccessoryView.formView = self.view;

  NSMutableArray* responders = [NSMutableArray new];
  for (NSUInteger i = 1; i <= 4; ++i) {
    UITextField* textField = (UITextField*)[self valueForKey:[NSString stringWithFormat:@"textField%u", i]];
    JCDefaultFormInputAccessoryViewRespondingViewGetter respondingViewGetter = ^UIView *{
      return textField;
    };
    [responders addObject:[JCDefaultFormInputAccessoryViewResponderItem itemWithRespondingViewGetter:respondingViewGetter]];
  }
  self.inputAccessoryView.responders = responders;
}

@end
