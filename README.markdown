Why?
----

I needed to add Previous/Next/Done buttons in the input accessory view for most text fields/views. While I found several projects that already do this, none of them appeared to automatically adjust the positioning of the view or work correctly with a UITableView instance (since they depended on all of the input views being available on view load while a table view's cells are lazily loaded.)

What?
-----

JCDefaultFormInputAccessoryView allows to add an input accessory view to your view controllers that contains Previous/Next/Done buttons. Once configured with a list of responding items, the JCDefaultFormInputAccessoryView instance allows the user to cycle through the inputs (as Safari allows in a web form) and automatically ensures that the view is positioned so that the keyboard doesn't hide the input's view.

![Sample application screenshot with keyboard hidden](https://github.com/jcoleman/JCDefaultFormInputAccessoryView/raw/master/screenshot-keyboard-hidden.png "Screenshot of sample application on iPhone with keyboard hidden")

![Sample application screenshot with keyboard shown](https://github.com/jcoleman/JCDefaultFormInputAccessoryView/raw/master/screenshot-keyboard-shown.png "Screenshot of sample application on iPhone with keyboard shown")

Example Code?
-------------

A working sample iOS Xcode project is available in the `Demo` directory.

Usage?
----

Note: If you'd like to configure your own toolbar buttons (say, for example, to take advantage of this projects view scrolling code without the next/previous buttons), you can configure the accessory view via its `delegate`. The accessory view itself adopts the delegate protocol and is the default delegate so that a custom delegate is not necessary.

    #import "JCDefaultFormInputAccessoryView.h"
    #import "JCDefaultFormInputAccessoryViewResponderItem.h"
    
    @interface MyTableViewController : UITableViewController
    
    @property (strong, nonatomic) JCDefaultFormInputAccessoryView* inputAccessoryView;
    
    @end
    
    @implementation MyTableViewController
    
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
    

Help! The Keyboard Doesn't Dismiss: Modal Form Sheets on the iPad
-------------------------------------------------------

iOS intentionally does not hide the keyboard on the iPad when a modal form sheet is displayed even if the text input has resigned first responder status. This is by design according to filed RADARs. However, there is a way to override this behavior: the presented UIViewController in the modal form sheet needs to return `NO` from `- (BOOL) disablesAutomaticKeyboardDismissal`. This is not a settable property, so you can override it on all UIViewController instances via a category, or use the category shown below to allow setting the value on a per-instance level. Note: if you use this category, make sure you set the overridden value on the base controller being presented in the modal, even if that base controller is a navigation controller.

UIViewController+JCViewControllerHelpers.h

    #import <UIKit/UIKit.h>
    
    @interface UIViewController (JCViewControllerHelpers)
    
    - (void) setDisablesAutomaticKeyboardDismissal:(BOOL)disableDismissal;
    
    @end

UIViewController+JCViewControllerHelpers.m

    #import "UIViewController+KCViewControllerHelpers.h"
    #import <objc/runtime.h>
    
    @implementation UIViewController (JCViewControllerHelpers)
    
    + (void) load {
      // Swizzling code from http://stackoverflow.com/a/5372042/1114761
      SEL originalSelector = @selector(disablesAutomaticKeyboardDismissal);
      SEL overrideSelector = @selector(JC_disablesAutomaticKeyboardDismissal);
      Method originalMethod = class_getInstanceMethod(self, originalSelector);
      Method overrideMethod = class_getInstanceMethod(self, overrideSelector);
      if (class_addMethod(self, originalSelector, method_getImplementation(overrideMethod), method_getTypeEncoding(overrideMethod))) {
        class_replaceMethod(self, overrideSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
      } else {
        method_exchangeImplementations(originalMethod, overrideMethod);
      }
    }
    
    static char disablesAutomaticKeyboardDismissalKey;
    - (void) setDisablesAutomaticKeyboardDismissal:(BOOL)disableDismissal {
      objc_setAssociatedObject(self, &disablesAutomaticKeyboardDismissalKey, @(disableDismissal), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    - (BOOL) JC_disablesAutomaticKeyboardDismissal {
      NSNumber* overriddenValue = objc_getAssociatedObject(self, &disablesAutomaticKeyboardDismissalKey);
      if (overriddenValue) {
        return [overriddenValue boolValue];
      } else {
        return self.disablesAutomaticKeyboardDismissal;
      }
    }
    
    @end

Installation?
-------------

This project includes a `podspec` for usage with [CocoaPods](http://http://cocoapods.org/). Simply add

    pod 'JCDefaultFormInputAccessoryView'

to your `Podfile` and run `pod install`.

Alternately, you can add all of the files contained in this project's `Library` directory to your Xcode project. If your project does not use ARC, you will need to enable ARC on these files. You can enable ARC per-file by adding the -fobjc-arc flag, as described on [a common StackOverflow question](http://stackoverflow.com/questions/6646052/how-can-i-disable-arc-for-a-single-file-in-a-project).

Acknowledgements
----------------

This project was inspired by Cédric Luthi's XCDFormInputAccessoryView project which can be found at https://github.com/0xced/XCDFormInputAccessoryView/

License
-------

This project is licensed under the MIT license. All copyright rights are retained by myself.

Copyright (c) 2012 James Coleman

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
