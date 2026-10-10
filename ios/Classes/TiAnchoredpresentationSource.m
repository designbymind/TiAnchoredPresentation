#import "TiAnchoredpresentationSource.h"
#import <TitaniumKit/TiApp.h>
#import <TitaniumKit/TiUtils.h>
#import <TitaniumKit/TiUIView.h>
#import <math.h>

// Titanium wraps ordinary UIButtons in TiUIView. Anchor to the actual control
// for UIKit to recognize its system glass appearance, while sub-rectangles stay
// in the Titanium wrapper's coordinate space.
@interface TiUIView (TiAnchoredButtonSource)
- (UIButton *)button;
@end

@implementation TiAnchoredpresentationSource
+ (UIView *)barContainingItem:(UIBarButtonItem *)item inView:(UIView *)view
{
  if ([view isKindOfClass:UIToolbar.class] && [((UIToolbar *)view).items containsObject:item]) return view;
  if ([view isKindOfClass:UINavigationBar.class]) {
    UINavigationItem *top = ((UINavigationBar *)view).topItem;
    if ([top.leftBarButtonItems containsObject:item] || [top.rightBarButtonItems containsObject:item]) return view;
  }
  for (UIView *child in view.subviews) {
    UIView *bar = [self barContainingItem:item inView:child];
    if (bar != nil) return bar;
  }
  return nil;
}
+ (instancetype)resolve:(TiViewProxy *)proxy
{
  return [self resolve:proxy excluding:nil];
}
+ (instancetype)resolve:(TiViewProxy *)proxy excluding:(UIViewController *)excluded
{
  TiAnchoredpresentationSource *source = [self new];
  source.proxy = proxy;
  UIView *anchor = nil;
  if ([proxy isUsingBarButtonItem]) {
    source.item = [proxy barButtonItem];
    anchor = source.item.customView;
    UIWindow *window = anchor.window ?: [[TiApp app] controller].view.window;
    UIView *bar = [self barContainingItem:source.item inView:window];
    if (bar == nil || bar.hidden || bar.alpha == 0) return nil;
    anchor = bar;
    source.kind = @"barButtonItem";
  } else {
    source.view = [proxy view];
    anchor = source.view;
    source.kind = @"view";
  }
  if (anchor.window == nil || CGRectIsEmpty(anchor.bounds)) return nil;
  for (UIView *ancestor = anchor; ancestor != nil; ancestor = ancestor.superview) {
    if (ancestor.hidden || ancestor.alpha == 0) return nil;
  }
  // Titanium can attach a NavigationWindow's native view without making its
  // UINavigationController a UIKit child. The UIWindow root is the actual
  // attached presentation owner; do not present from a responder-chain child.
  UIViewController *presenter = anchor.window.rootViewController;
  while (presenter.presentedViewController != nil && presenter.presentedViewController != excluded) presenter = presenter.presentedViewController;
  if (presenter == nil || presenter.isBeingDismissed || presenter.isBeingPresented || presenter.view.window != anchor.window) return nil;
  if (![anchor isDescendantOfView:presenter.view]) return nil;
  source.presenter = presenter;
  return source;
}
- (void)configure:(UIPopoverPresentationController *)popover rect:(NSDictionary *)rect
{
  if (self.item != nil) {
    popover.sourceItem = self.item;
  } else if (rect != nil) {
    // A sub-rectangle uses sourceView/sourceRect; the full view uses sourceItem.
    popover.sourceView = self.view;
    popover.sourceRect = [TiUtils rectValue:rect];
  } else {
    popover.sourceItem = [self nativeSourceView];
  }
}
- (UIView *)nativeSourceView
{
  UIView *view = self.view;
  Class buttonClass = NSClassFromString(@"TiUIButton");
  if (buttonClass != Nil && [view isKindOfClass:buttonClass] && [view respondsToSelector:@selector(button)]) {
    UIButton *button = [(TiUIView *)view button];
    if (button.window != nil) return button;
  }
  return view;
}
@end
