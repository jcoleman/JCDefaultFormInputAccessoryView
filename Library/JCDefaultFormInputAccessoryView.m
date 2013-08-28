#import "JCDefaultFormInputAccessoryView.h"
#import "JCDefaultFormInputAccessoryViewResponderItem.h"

CGAffineTransform affineTransformForInterfaceOrientationAndWindow(UIInterfaceOrientation orientation, UIWindow* window) {
  CGAffineTransform transform;

  switch (orientation) {
    case UIInterfaceOrientationPortrait:
      transform = CGAffineTransformIdentity;
      break;

    case UIInterfaceOrientationPortraitUpsideDown:
      transform = CGAffineTransformMake(-1, 0, 0, -1, 0, 0);
      transform = CGAffineTransformTranslate(transform, -window.frame.size.width, -window.frame.size.height);
      break;

    case UIInterfaceOrientationLandscapeLeft:
      transform = CGAffineTransformMake(0, 1, -1, 0, 0, 0);
      transform = CGAffineTransformTranslate(transform, 0, -window.frame.size.height);
      break;

    case UIInterfaceOrientationLandscapeRight:
      transform = CGAffineTransformMake(0, -1, 1, 0, 0, 0);
      transform = CGAffineTransformTranslate(transform, -window.frame.size.width, 0);
      break;
  }

  return transform;
}

@interface JCDefaultFormInputAccessoryView ()

@property (weak, nonatomic) JCDefaultFormInputAccessoryViewResponderItem* currentlySelectedResponder;
@property (weak, nonatomic) JCDefaultFormInputAccessoryViewResponderItem* responderSelectedOnWillHideKeyboard;

@property (nonatomic) JCDefaultFormInputAccessoryViewDirectionButton lastDirectionButtonTapped;

@property (nonatomic) CGRect originalFormViewFrame;
@property (nonatomic) CGFloat keyboardHeight;
@property (nonatomic) CGFloat keyboardAnimationDuration;
@property (nonatomic) CGRect keyboardDisplayedFrame;
@property (nonatomic) UIViewAnimationCurve keyboardAnimationCurve;
@property (nonatomic) BOOL keyboardShown;

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
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(keyboardDidHide:)
                                               name:UIKeyboardDidHideNotification
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
    // Re-beginning editing on the currently selected input. Ignore.
    return;
  } else {
    if (self.currentlySelectedResponder) {
      // Transition from one input to a different one.
      __weak JCDefaultFormInputAccessoryView* weakSelf = self;
      dispatch_async(dispatch_get_main_queue(), ^{
        // We can't trust the ordering of notifications (in current iOS
        // the UITextFieldTextDidBeginEditingNotification is sent before
        // UIKeyboardWillShowNotification but UITextViewTextDidBeginEditingNotification
        // is sent after UIKeyboardWillShowNotification.
        // So here we just use dispatch_async to ensure we get fired after
        // everything's happened.
        [weakSelf ensureCurrentResponderIsVisible];
      });
    }

    [self setCurrentlySelectedResponderForInputView:respondingView];
  }
}

- (void) keyboardWillShow:(NSNotification*)notification {
  self.keyboardShown = YES;

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
  self.responderSelectedOnWillHideKeyboard = self.currentlySelectedResponder;

  if (self.formView.window) {
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

  self.keyboardShown = NO;
}

- (void) keyboardDidHide:(NSNotification*)notification {
  UIResponder* firstResponder = [self findFirstResponderInView:self.formView];
  if (!firstResponder && self.responderSelectedOnWillHideKeyboard == self.currentlySelectedResponder) {
    self.currentlySelectedResponder = nil;
  }
  self.responderSelectedOnWillHideKeyboard = nil;
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
  if (self.self.keyboardShown && self.formView && self.formView.window) {
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

// We assume that this method is called to act an unmodified containingView
// frame. That is, it shouldn't be called when the current containingView frame
// is currently the result of this method's calculations.
- (void) ensureResponderView:(UIView*)responder
  isVisibleForKeyboardHeight:(CGFloat)keyboardHeight
               bySlidingView:(UIView*)containingView {

  UIWindow* window = containingView.window;
  UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
  CGAffineTransform orientationTransform = affineTransformForInterfaceOrientationAndWindow(orientation, window);

  CGRect responderRect = CGRectApplyAffineTransform([window convertRect:responder.bounds fromView:responder], orientationTransform);
  CGRect containingRect = CGRectApplyAffineTransform([window convertRect:containingView.bounds fromView:containingView], orientationTransform);
  CGRect keyboardRect = CGRectApplyAffineTransform(self.keyboardDisplayedFrame, orientationTransform);

  // Calculate where the responding view would sit exactly halfway between the
  // top of the containing view and the top of the keyboard view.
  CGFloat midline = (keyboardRect.origin.y - containingRect.origin.y) / 2.0;
  CGFloat calculatedResponderY = midline - floorf(responderRect.size.height / 2.0);
  CGFloat dy = calculatedResponderY - responderRect.origin.y;    

  // Bound the calculated d-y  value so that it doesn't cause the containing
  // view to be positioned in such a way that it would leave empty space on
  // the screen.
  if (dy > 0.0) {
    // Since we assume that we're never acting on an already adjusted frame,
    // then we will never have a postive d-y value since that would move the
    // containing view down past where it already begins.
    dy = 0.0;
  } else if ((containingRect.origin.y + containingRect.size.height + dy) < keyboardRect.origin.y) {
    // The containing view should never be moved up in such a way that its
    // bottom would be above the top of the keyboard.
    dy = keyboardRect.origin.y - (containingRect.origin.y + containingRect.size.height);
  }

  CGPoint dOrigin = CGPointApplyAffineTransform(CGPointMake(0.0, dy), containingView.transform);

  CGRect containingFrame = containingView.frame;
  containingFrame.origin.x += dOrigin.x;
  containingFrame.origin.y += dOrigin.y;

  [UIView beginAnimations:nil context:NULL];
  [UIView setAnimationBeginsFromCurrentState:YES];
  [UIView setAnimationCurve:self.keyboardAnimationCurve];
  [UIView setAnimationDuration:self.keyboardAnimationDuration];
  [containingView setFrame:containingFrame];
  [UIView commitAnimations];
}

@end
