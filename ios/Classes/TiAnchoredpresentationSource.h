#import <TitaniumKit/TiViewProxy.h>
#import <UIKit/UIKit.h>
// Resolve the *existing* bar item before requesting a native view. The Titanium
// barButtonItem getter creates an item, so it must only run for attached items.
@interface TiAnchoredpresentationSource : NSObject
@property (nonatomic, strong) TiViewProxy *proxy;
@property (nonatomic, strong) UIView *view;
@property (nonatomic, strong) UIBarButtonItem *item;
@property (nonatomic, strong) UIViewController *presenter;
@property (nonatomic, copy) NSString *kind;
+ (instancetype)resolve:(TiViewProxy *)proxy;
+ (instancetype)resolve:(TiViewProxy *)proxy excluding:(UIViewController *)excluded;
- (UIView *)nativeSourceView;
- (void)configure:(UIPopoverPresentationController *)popover rect:(NSDictionary *)rect;
@end
