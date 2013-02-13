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
