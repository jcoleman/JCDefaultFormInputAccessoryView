#import "JCDefaultFormInputAccessoryViewResponderItem.h"

@implementation JCDefaultFormInputAccessoryViewResponderItem

+ (id) itemWithContainingTableView:(UITableView*)tableView
                         indexPath:(NSIndexPath*)indexPath
              respondingViewGetter:(JCDefaultFormInputAccessoryViewRespondingViewGetter)respondingViewGetter {
  JCDefaultFormInputAccessoryViewResponderItem* item = [JCDefaultFormInputAccessoryViewResponderItem new];
  item.containingTableView = tableView;
  item.containingTableViewIndexPath = indexPath;
  item.respondingViewGetter = respondingViewGetter;
  item.responderType = JCDefaultFormInputAccessoryViewResponderTypeUIResponder;
  return item;
}

+ (id) itemWithContainingTableView:(UITableView*)tableView
                         indexPath:(NSIndexPath*)indexPath
              respondingViewGetter:(JCDefaultFormInputAccessoryViewRespondingViewGetter)respondingViewGetter
                   customActivator:(JCDefaultFormInputAccessoryViewCustomActivation)customActivator {
  JCDefaultFormInputAccessoryViewResponderItem* item = [JCDefaultFormInputAccessoryViewResponderItem new];
  item.containingTableView = tableView;
  item.containingTableViewIndexPath = indexPath;
  item.respondingViewGetter = respondingViewGetter;
  item.customActivator = customActivator;
  item.responderType = JCDefaultFormInputAccessoryViewResponderTypeCustom;
  return item;
}

+ (id) itemWithRespondingViewGetter:(JCDefaultFormInputAccessoryViewRespondingViewGetter)respondingViewGetter {
  JCDefaultFormInputAccessoryViewResponderItem* item = [JCDefaultFormInputAccessoryViewResponderItem new];
  item.respondingViewGetter = respondingViewGetter;
  item.responderType = JCDefaultFormInputAccessoryViewResponderTypeUIResponder;
  return item;
}

+ (id) itemWithRespondingViewGetter:(JCDefaultFormInputAccessoryViewRespondingViewGetter)respondingViewGetter
                    customActivator:(JCDefaultFormInputAccessoryViewCustomActivation)customActivator {
  JCDefaultFormInputAccessoryViewResponderItem* item = [JCDefaultFormInputAccessoryViewResponderItem new];
  item.respondingViewGetter = respondingViewGetter;
  item.customActivator = customActivator;
  item.responderType = JCDefaultFormInputAccessoryViewResponderTypeCustom;
  return item;
}

- (BOOL) isEqual:(id)other {
  if (other == self) {
    return YES;
  } else if (!other || ![other isKindOfClass:[self class]]) {
    return NO;
  } else {
    return [self isEqualToResponderItem:other];
  }
}

- (BOOL) isEqualToResponderItem:(JCDefaultFormInputAccessoryViewResponderItem*)item {
  if (self == item) {
    return YES;
  } else if (!item) {
    return NO;
  } else if (self.containingTableView == item.containingTableView
             && [self.containingTableViewIndexPath isEqual:item.containingTableViewIndexPath]) {
    return YES;
  } else if (self.respondingViewGetter && item.respondingViewGetter
             && self.respondingViewGetter() == item.respondingViewGetter()) {
    return YES;
  }

  return NO;
}

-(NSUInteger) hash {
  NSUInteger result = 1;
  NSUInteger prime = 31;

  if (self.containingTableView) {
    result = prime * result + [self.containingTableView hash];
  }

  if (self.containingTableViewIndexPath) {
    result = prime * result + [self.containingTableViewIndexPath hash];
  }

  if (self.respondingViewGetter) {
    result = prime * result + [self.respondingViewGetter() hash];
  }

  return result;
}

- (void) activate {
  if (self.containingTableView && self.containingTableViewIndexPath) {
    [self.containingTableView scrollToRowAtIndexPath:self.containingTableViewIndexPath
                                    atScrollPosition:UITableViewScrollPositionNone
                                            animated:YES];
  }

  switch (self.responderType) {
    case JCDefaultFormInputAccessoryViewResponderTypeUIResponder:
      if (self.respondingViewGetter) {
        UIView* respondingView = self.respondingViewGetter();
        [respondingView becomeFirstResponder];
      }
      break;
    case JCDefaultFormInputAccessoryViewResponderTypeCustom:
      if (self.customActivator) {
        self.customActivator();
      }
      break;
  }
}

@end
