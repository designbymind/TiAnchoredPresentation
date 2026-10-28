#import <UIKit/UIKit.h>

// Separate UIKit's touch target from Titanium's visual wrapper. Neither is owned
// by the dimmer, so detached/recycled content is not retained by cutout tracking.
@interface TiAnchoredpresentationDimmingExclusion : NSObject
@property (nonatomic, weak) UIView *view;
@property (nonatomic, weak) UIView *shapeView;
@property (nonatomic, copy) NSString *shape;
@property (nonatomic, assign) CGFloat cornerRadius;
@end

// A noninteractive visual layer. UIPopoverPresentationController owns all touches.
@interface TiAnchoredpresentationDimmingView : UIView
- (instancetype)initWithWindow:(UIWindow *)window opacity:(CGFloat)opacity excludedViews:(NSArray<UIView *> *)views;
- (instancetype)initWithWindow:(UIWindow *)window opacity:(CGFloat)opacity exclusions:(NSArray<TiAnchoredpresentationDimmingExclusion *> *)exclusions;
- (void)removeOverlay;
@end
