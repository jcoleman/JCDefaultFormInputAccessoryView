#import "JCDefaultFormInputAccessoryView.h"
#import "JCDefaultFormInputAccessoryViewResponderItem.h"

@interface JCDefaultFormInputAccessoryView ()

@property (weak, nonatomic) JCDefaultFormInputAccessoryViewResponderItem* currentlySelectedResponder;

@property (nonatomic) JCDefaultFormInputAccessoryViewDirectionButton lastDirectionButtonTapped;

@property (nonatomic) CGRect originalFormViewFrame;
@property (nonatomic) CGFloat keyboardHeight;
@property (nonatomic) CGFloat keyboardAnimationDuration;
@property (nonatomic) CGRect keyboardDisplayedFrame;
@property (nonatomic) UIViewAnimationCurve keyboardAnimationCurve;

@end

@implementation JCDefaultFormInputAccessoryView

+ (id) defaultFormInputAccessoryView {
  return [JCDefaultFormInputAccessoryView new];
}

- (id) init {
  return [self initWithDelegate:self];
}

- (id) initWithDelegate:(id<JCDefaultFormInputAccessoryViewDelegate>)delegate {
  self = [super init];
  if (self) {
    [self setup];
    self.delegate = delegate;
  }
  return self;
}

- (void) setup {
  self.responders = [NSMutableArray new];

  self.toolbar = [UIToolbar new];
  self.toolbar.barStyle = UIBarStyleBlack;
  self.toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth;

  [self addSubview:self.toolbar];

  CGSize size = [self.toolbar sizeThatFits:CGSizeZero];
  self.frame = self.toolbar.frame = CGRectMake(0, 0, size.width, size.height);

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(textFieldOrTextViewDidBeginEditing:)
                                               name:UITextFieldTextDidBeginEditingNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(textFieldOrTextViewDidBeginEditing:)
                                               name:UITextViewTextDidBeginEditingNotification
                                             object:nil];

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(keyboardWillShow:)
                                               name:UIKeyboardWillShowNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(keyboardWillHide:)
                                               name:UIKeyboardWillHideNotification
                                             object:nil];

  self.originalFormViewFrame = CGRectZero;
}

- (void) dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) setDelegate:(id<JCDefaultFormInputAccessoryViewDelegate>)delegate {
  _delegate = delegate;
  if (delegate) {
    self.toolbar.items = [delegate toolbarItemsForDefaultFormInputAccessoryView:self];
  } else {
    self.toolbar.items = @[];
  }
}

- (NSArray*) toolbarItemsForDefaultFormInputAccessoryView:(JCDefaultFormInputAccessoryView*)accessoryView {
  UISegmentedControl* previousNextControl = [[UISegmentedControl alloc] initWithItems:@[@"Previous", @"Next"]];
  previousNextControl.segmentedControlStyle = UISegmentedControlStyleBar;
  previousNextControl.momentary = YES;
  [previousNextControl addTarget:accessoryView action:@selector(previousNextControlValueChanged:) forControlEvents:UIControlEventValueChanged];

  return @[
    [[UIBarButtonItem alloc] initWithCustomView:previousNextControl],
    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:accessoryView action:@selector(doneButtonTapped:)]
   ];
}

- (void) textFieldOrTextViewDidBeginEditing:(NSNotification*)notification {
  UIView* respondingView = notification.object;

  if (self.currentlySelectedResponder.respondingViewGetter
      && self.currentlySelectedResponder.respondingViewGetter() == respondingView) {
    return;
  } else {
    [self setCurrentlySelectedResponderForInputView:respondingView];
  }
}

- (void) keyboardWillShow:(NSNotification*)notification {
  if (!self.formView.window) {
    return;
  }

  UIView* firstResponder;
  if (!self.currentlySelectedResponder
      && (firstResponder = [self findFirstResponderInView:self.formView])) {
    [self setCurrentlySelectedResponderForInputView:firstResponder];
  }

  if (CGRectEqualToRect(self.originalFormViewFrame, CGRectZero)) {
    self.originalFormViewFrame = self.formView.frame;
  }

  CGRect keyboardFrame = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
  self.keyboardDisplayedFrame = keyboardFrame;
  UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
  if (UIInterfaceOrientationIsPortrait(orientation)) {
    self.keyboardHeight = keyboardFrame.size.height;
  } else {
    self.keyboardHeight = keyboardFrame.size.width;
  }
  self.keyboardAnimationDuration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
  self.keyboardAnimationCurve = (UIViewAnimationCurve)[[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] unsignedIntegerValue];

  [self ensureCurrentResponderIsVisible];
}

- (void) keyboardWillHide:(NSNotification*)notification {
  if (!self.formView.window) {
    return;
  }

  if (self.formView && !CGRectEqualToRect(self.originalFormViewFrame, CGRectZero)) {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationCurve:self.keyboardAnimationCurve];
    [UIView setAnimationDuration:self.keyboardAnimationDuration];
    [self.formView setFrame:self.originalFormViewFrame];
    [UIView commitAnimations];
  }

  self.originalFormViewFrame = CGRectZero;
}

- (void) previousNextControlValueChanged:(UISegmentedControl*)previousNextControl {
  if (previousNextControl.selectedSegmentIndex == 0) {
    self.lastDirectionButtonTapped = JCDefaultFormInputAccessoryViewDirectionButtonPrevious;
    [self selectPreviousResponder];
  } else if (previousNextControl.selectedSegmentIndex == 1) {
    self.lastDirectionButtonTapped = JCDefaultFormInputAccessoryViewDirectionButtonNext;
    [self selectNextResponder];
  }

  [self updatePreviousNextButtonStatus];
}

- (UIView*) findFirstResponderInView:(UIView*)view {
  if (view) {
    if (view.isFirstResponder) {
      return view;
    } else {
      for (UIView* subview in view.subviews) {
        UIView* firstResponder = [self findFirstResponderInView:subview];
        if (firstResponder) {
          return firstResponder;
        }
      }
      return nil;
    }
  } else {
    return nil;
  }
}

- (void) setCurrentlySelectedResponderForInputView:(UIView*)respondingView {
  NSUInteger indexOfSelectedResponder;
  BOOL indexFound = NO;
  if ([self.formView isKindOfClass:[UITableView class]]) {
    for (UITableViewCell* cell in [(UITableView*)self.formView visibleCells]) {
      if ([respondingView isDescendantOfView:cell]) {
        NSIndexPath* cellIndexPath = [(UITableView*)self.formView indexPathForCell:(UITableViewCell*)respondingView];
        indexOfSelectedResponder = [self.responders indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
          return [cellIndexPath isEqual:((JCDefaultFormInputAccessoryViewResponderItem*)obj).containingTableViewIndexPath];
        }];
        indexFound = (indexOfSelectedResponder != NSNotFound);
      }
    }
  }

  if (!indexFound) {
    indexOfSelectedResponder = [self.responders indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
      JCDefaultFormInputAccessoryViewResponderItem* item = (JCDefaultFormInputAccessoryViewResponderItem*)obj;
      return item.respondingViewGetter && item.respondingViewGetter() == respondingView;
    }];
    indexFound = (indexOfSelectedResponder != NSNotFound);
  }

  if (indexFound) {
    self.currentlySelectedResponder = [self.responders objectAtIndex:indexOfSelectedResponder];
    [self updatePreviousNextButtonStatus];
  }
}

- (void) doneButtonTapped:(UIBarButtonItem*)doneButton {
  [[UIApplication sharedApplication] sendAction:@selector(resignFirstResponder) to:nil from:nil forEvent:nil];
}

- (BOOL) hasPreviousResponder {
  if (self.currentlySelectedResponder) {
    NSUInteger index = [self.responders indexOfObject:self.currentlySelectedResponder];
    if (index == NSNotFound) {
      return NO;
    } else {
      return index > 0;
    }
  } else {
    return NO;
  }
}

- (BOOL) hasNextResponder {
  if (self.currentlySelectedResponder) {
    NSUInteger index = [self.responders indexOfObject:self.currentlySelectedResponder];
    if (index == NSNotFound) {
      return YES;
    } else {
      return index < (self.responders.count - 1);
    }
  } else {
    return YES;
  }
}

- (void) selectPreviousResponder {
  NSUInteger index = [self.responders indexOfObject:self.currentlySelectedResponder];
  if (index == NSNotFound) {
    if (self.responders.count > 0) {
      [self selectResponderAtIndex:(self.responders.count - 1)];
    } else {
      NSLog(@"JCDefaultFormInputAccessoryView: Error (called selectPreviousResponder but none exists.)");
    }
  } else if (index > 0) {
    [self selectResponderAtIndex:(index - 1)];
  } else {
    if (self.responders.count > 0) {
      [self selectResponderAtIndex:(self.responders.count - 1)];
    } else {
      // Do nothing. (No need to re-select the currently selected responder index.)
    }
  }
}

- (void) selectNextResponder {
  NSUInteger index = [self.responders indexOfObject:self.currentlySelectedResponder];
  if (index == NSNotFound) {
    if (self.responders.count > 0) {
      [self selectResponderAtIndex:0];
    } else {
      NSLog(@"JCDefaultFormInputAccessoryView: Error (called selectNextResponder but none exists.)");
    }
  } else if (index < (self.responders.count - 1)) {
    [self selectResponderAtIndex:(index + 1)];
  } else {
    if (self.responders.count > 0) {
      [self selectResponderAtIndex:0];
    } else {
      // Do nothing. (No need to re-select the currently selected responder index.)
    }
  }
}

- (void) selectNextResponderInCurrentDirection {
  switch (self.lastDirectionButtonTapped) {
    case JCDefaultFormInputAccessoryViewDirectionButtonPrevious:
      [self selectPreviousResponder];
      break;
    case JCDefaultFormInputAccessoryViewDirectionButtonNext:
      [self selectNextResponder];
      break;
    default:
      NSLog(@"JCDefaultFormInputAccessoryView: Error (called selectNextResponderInCurrentDirection but previous/next button hasn't yet been triggered.)");
      break;
  }
}

- (void) selectResponderAtIndex:(NSUInteger)index {
  self.currentlySelectedResponder = [self.responders objectAtIndex:index];
  [self.currentlySelectedResponder activate];
  [self ensureCurrentResponderIsVisible];
  [self updatePreviousNextButtonStatus];
}

- (void) updatePreviousNextButtonStatus {
  UISegmentedControl* previousNextControl = (UISegmentedControl*)[[self.toolbar.items objectAtIndex:0] customView];
  [previousNextControl setEnabled:[self hasPreviousResponder] forSegmentAtIndex:0];
  [previousNextControl setEnabled:[self hasNextResponder] forSegmentAtIndex:1];
}

- (void) ensureCurrentResponderIsVisible {
  if (self.formView && self.formView.window) {
    UIView* respondingView;
    if (self.currentlySelectedResponder.respondingViewGetter) {
      respondingView = self.currentlySelectedResponder.respondingViewGetter();
    }

    if (respondingView) {
      if (!CGRectEqualToRect(self.originalFormViewFrame, CGRectZero)) {
        self.formView.frame = self.originalFormViewFrame;
      }
      [self ensureResponderView:respondingView
     isVisibleForKeyboardHeight:self.keyboardHeight
                  bySlidingView:self.formView];
    }
  }
}

static const CGFloat MINIMUM_SCROLL_FRACTION = 0.2;
static const CGFloat MAXIMUM_SCROLL_FRACTION = 0.8;

- (void) ensureResponderView:(UIView*)responder
  isVisibleForKeyboardHeight:(CGFloat)keyboardHeight
               bySlidingView:(UIView*)containingView {
  // Code adapted from http://www.cocoawithlove.com/2008/10/sliding-uitextfields-around-to-avoid.html
  UIWindow* window = containingView.window;
  CGRect responderRect = [window convertRect:responder.bounds fromView:responder];
  CGRect containingRect = [window convertRect:containingView.bounds fromView:containingView];

  CGFloat midline = responderRect.origin.y + (responderRect.size.height / 2);
  CGFloat numerator = midline - containingRect.origin.y - (MINIMUM_SCROLL_FRACTION * containingRect.size.height);
  CGFloat denominator = (MAXIMUM_SCROLL_FRACTION - MINIMUM_SCROLL_FRACTION) * containingRect.size.height;
  CGFloat heightFraction = numerator / denominator;

  if (heightFraction < 0.0) {
    heightFraction = 0.0;
  } else if (heightFraction > 1.0) {
    heightFraction = 1.0;
  }

  CGFloat windowHeight;
  UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
  if (UIInterfaceOrientationIsPortrait(orientation)) {
    windowHeight = window.frame.size.height;
  } else {
    windowHeight = window.frame.size.width;
  }

  CGFloat containingViewHeightFromWindowTop = (containingRect.size.height + containingRect.origin.y);
  CGFloat containingViewBottomOffset = 0;
  if (containingViewHeightFromWindowTop < windowHeight) {
    containingViewBottomOffset = windowHeight - containingViewHeightFromWindowTop;
  }
  CGFloat animatedDistance = (keyboardHeight - containingViewBottomOffset) * heightFraction;

  CGRect containingFrame = containingView.frame;
  containingFrame.origin.y -= animatedDistance;

  [UIView beginAnimations:nil context:NULL];
  [UIView setAnimationBeginsFromCurrentState:YES];
  [UIView setAnimationCurve:self.keyboardAnimationCurve];
  [UIView setAnimationDuration:self.keyboardAnimationDuration];
  [containingView setFrame:containingFrame];
  [UIView commitAnimations];
}

@end
