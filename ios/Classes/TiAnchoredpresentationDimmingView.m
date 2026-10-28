#import "TiAnchoredpresentationDimmingView.h"
#import <QuartzCore/QuartzCore.h>

@implementation TiAnchoredpresentationDimmingExclusion
@end

@class TiAnchoredpresentationDimmingView;
@interface TiAnchoredpresentationDimmingTick : NSObject
@property (nonatomic, weak) TiAnchoredpresentationDimmingView *view;
- (void)tick:(CADisplayLink *)link;
@end

@interface TiAnchoredpresentationDimmingView ()
@property (nonatomic, assign) CGFloat dimmingOpacity;
@property (nonatomic, copy) NSArray<TiAnchoredpresentationDimmingExclusion *> *exclusions;
@property (nonatomic, copy) NSArray<NSArray<UIBezierPath *> *> *cutouts;
@property (nonatomic, strong) CADisplayLink *displayLink;
- (void)updateCutouts;
@end

@implementation TiAnchoredpresentationDimmingTick
- (void)tick:(CADisplayLink *)link
{
  TiAnchoredpresentationDimmingView *view = self.view;
  if (view == nil) [link invalidate];
  else [view updateCutouts];
}
@end

@implementation TiAnchoredpresentationDimmingView
- (instancetype)initWithWindow:(UIWindow *)window opacity:(CGFloat)opacity excludedViews:(NSArray<UIView *> *)views
{
  NSMutableArray *exclusions = [NSMutableArray array];
  for (UIView *view in views) {
    TiAnchoredpresentationDimmingExclusion *exclusion = [TiAnchoredpresentationDimmingExclusion new];
    exclusion.view = view;
    exclusion.shapeView = view;
    exclusion.shape = @"auto";
    [exclusions addObject:exclusion];
  }
  return [self initWithWindow:window opacity:opacity exclusions:exclusions];
}
- (instancetype)initWithWindow:(UIWindow *)window opacity:(CGFloat)opacity exclusions:(NSArray<TiAnchoredpresentationDimmingExclusion *> *)exclusions
{
  self = [super initWithFrame:window.bounds];
  if (self) {
    self.backgroundColor = UIColor.clearColor;
    self.opaque = NO;
    self.userInteractionEnabled = NO;
    self.accessibilityElementsHidden = YES;
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.contentMode = UIViewContentModeRedraw;
    self.dimmingOpacity = opacity;
    self.exclusions = exclusions ?: @[];
  }
  return self;
}
- (void)didMoveToWindow
{
  [super didMoveToWindow];
  [self.displayLink invalidate];
  self.displayLink = nil;
  [self updateCutouts];
  if (self.window != nil && self.exclusions.count > 0) {
    // A weak forwarding target avoids a display-link/view ownership cycle.
    // Track scrolling and UIKit animations without observing private view state.
    TiAnchoredpresentationDimmingTick *target = [TiAnchoredpresentationDimmingTick new];
    target.view = self;
    self.displayLink = [CADisplayLink displayLinkWithTarget:target selector:@selector(tick:)];
    [self.displayLink addToRunLoop:NSRunLoop.mainRunLoop forMode:NSRunLoopCommonModes];
  }
}
- (void)layoutSubviews
{
  [super layoutSubviews];
  [self updateCutouts];
}
// Derive an affine conversion from public layer coordinates. This preserves
// ordinary translation, scale and rotation rather than rounding a bounding box.
- (CGAffineTransform)transformFromLayer:(CALayer *)layer
{
  CALayer *destination = self.layer.presentationLayer ?: self.layer;
  CGPoint origin = [layer convertPoint:CGPointZero toLayer:destination];
  CGPoint x = [layer convertPoint:CGPointMake(1, 0) toLayer:destination];
  CGPoint y = [layer convertPoint:CGPointMake(0, 1) toLayer:destination];
  return CGAffineTransformMake(x.x-origin.x, x.y-origin.y, y.x-origin.x, y.y-origin.y, origin.x, origin.y);
}
- (UIBezierPath *)roundedPathForLayer:(CALayer *)layer radius:(CGFloat)radius
{
  UIRectCorner corners = 0;
  if (layer.maskedCorners & kCALayerMinXMinYCorner) corners |= UIRectCornerTopLeft;
  if (layer.maskedCorners & kCALayerMaxXMinYCorner) corners |= UIRectCornerTopRight;
  if (layer.maskedCorners & kCALayerMinXMaxYCorner) corners |= UIRectCornerBottomLeft;
  if (layer.maskedCorners & kCALayerMaxXMaxYCorner) corners |= UIRectCornerBottomRight;
  radius = MIN(radius, MIN(layer.bounds.size.width, layer.bounds.size.height) / 2);
  return [UIBezierPath bezierPathWithRoundedRect:layer.bounds byRoundingCorners:corners cornerRadii:CGSizeMake(radius, radius)];
}
- (UIBezierPath *)automaticPathForLayer:(CALayer *)layer
{
  // Titanium uses CAShapeLayer masks for per-corner borderRadius values. A mask
  // is not a sublayer: convert its bounds/anchor/position into its owner's space.
  CALayer *maskLayer = layer.mask;
  if ([maskLayer isKindOfClass:CAShapeLayer.class] && ((CAShapeLayer *)maskLayer).path != nil) {
    CAShapeLayer *mask = (CAShapeLayer *)maskLayer;
    UIBezierPath *path = [UIBezierPath bezierPathWithCGPath:mask.path];
    path.usesEvenOddFillRule = [mask.fillRule isEqualToString:kCAFillRuleEvenOdd];
    CGPoint anchor = CGPointMake(CGRectGetMinX(mask.bounds) + mask.bounds.size.width * mask.anchorPoint.x,
                                CGRectGetMinY(mask.bounds) + mask.bounds.size.height * mask.anchorPoint.y);
    CGAffineTransform transform = CGAffineTransformMakeTranslation(-anchor.x, -anchor.y);
    transform = CGAffineTransformConcat(transform, mask.affineTransform);
    transform = CGAffineTransformConcat(transform, CGAffineTransformMakeTranslation(mask.position.x, mask.position.y));
    [path applyTransform:transform];
    return path;
  }
  return [self roundedPathForLayer:layer radius:layer.cornerRadius];
}
- (UIBezierPath *)pathForExclusion:(TiAnchoredpresentationDimmingExclusion *)exclusion layer:(CALayer *)layer
{
  CGRect bounds = layer.bounds;
  CGFloat shortest = MIN(bounds.size.width, bounds.size.height);
  if ([exclusion.shape isEqualToString:@"circle"]) {
    CGRect circle = CGRectMake(CGRectGetMidX(bounds)-shortest/2, CGRectGetMidY(bounds)-shortest/2, shortest, shortest);
    return [UIBezierPath bezierPathWithOvalInRect:circle];
  }
  if ([exclusion.shape isEqualToString:@"capsule"]) {
    return [UIBezierPath bezierPathWithRoundedRect:bounds cornerRadius:shortest/2];
  }
  if ([exclusion.shape isEqualToString:@"roundedRect"]) {
    return [UIBezierPath bezierPathWithRoundedRect:bounds cornerRadius:MIN(exclusion.cornerRadius, shortest/2)];
  }
  // UIKit configurations can provide a capsule without setting layer.cornerRadius.
  if (layer.cornerRadius == 0 && layer.mask == nil && [exclusion.view isKindOfClass:UIButton.class]) {
    UIButton *button = (UIButton *)exclusion.view;
    if (button.configuration != nil && button.configuration.cornerStyle == UIButtonConfigurationCornerStyleCapsule) {
      return [UIBezierPath bezierPathWithRoundedRect:bounds cornerRadius:shortest/2];
    }
  }
  return [self automaticPathForLayer:layer];
}
- (BOOL)cutoutsEqual:(NSArray<NSArray<UIBezierPath *> *> *)cutouts
{
  if (cutouts.count != self.cutouts.count) return NO;
  for (NSUInteger index = 0; index < cutouts.count; index++) {
    NSArray *paths = cutouts[index], *previous = self.cutouts[index];
    if (paths.count != previous.count) return NO;
    for (NSUInteger part = 0; part < paths.count; part++) {
      UIBezierPath *path = paths[part], *old = previous[part];
      if (path.usesEvenOddFillRule != old.usesEvenOddFillRule || !CGPathEqualToPath(path.CGPath, old.CGPath)) return NO;
    }
  }
  return YES;
}
- (void)updateCutouts
{
  if (self.window == nil) return;
  NSMutableArray *cutouts = [NSMutableArray array];
  for (TiAnchoredpresentationDimmingExclusion *exclusion in self.exclusions) {
    UIView *view = exclusion.view;
    UIView *shapeView = exclusion.shapeView;
    if (view == nil || shapeView == nil || view.window != self.window || shapeView.window != self.window) continue;
    if (view != shapeView && ![view isDescendantOfView:shapeView]) continue;
    BOOL visible = YES;
    for (UIView *ancestor = view; ancestor != nil; ancestor = ancestor.superview) {
      CALayer *layer = ancestor.layer.presentationLayer ?: ancestor.layer;
      if (ancestor.hidden || layer.opacity <= 0.01) { visible = NO; break; }
    }
    if (!visible || CGRectIsEmpty(shapeView.bounds)) continue;
    CALayer *layer = shapeView.layer.presentationLayer ?: shapeView.layer;
    UIBezierPath *path = [self pathForExclusion:exclusion layer:layer];
    [path applyTransform:[self transformFromLayer:layer]];
    NSMutableArray *paths = [NSMutableArray arrayWithObject:path];
    for (UIView *ancestor = shapeView.superview; ancestor != nil; ancestor = ancestor.superview) {
      CALayer *clipLayer = ancestor.layer.presentationLayer ?: ancestor.layer;
      if (ancestor.clipsToBounds || clipLayer.mask != nil) {
        UIBezierPath *clip = [self automaticPathForLayer:clipLayer];
        [clip applyTransform:[self transformFromLayer:clipLayer]];
        [paths addObject:clip];
      }
    }
    [cutouts addObject:paths];
  }
  if (![self cutoutsEqual:cutouts]) {
    self.cutouts = cutouts;
    [self setNeedsDisplay];
  }
}
- (void)drawRect:(CGRect)rect
{
  CGContextRef context = UIGraphicsGetCurrentContext();
  CGContextSetFillColorWithColor(context, [UIColor colorWithWhite:0 alpha:self.dimmingOpacity].CGColor);
  CGContextFillRect(context, self.bounds);
  // Clear each hole separately so overlapping pass-through views remain clear.
  CGContextSetBlendMode(context, kCGBlendModeClear);
  for (NSArray<UIBezierPath *> *paths in self.cutouts) {
    CGContextSaveGState(context);
    for (NSUInteger index = 1; index < paths.count; index++) {
      UIBezierPath *clip = paths[index];
      CGContextAddPath(context, clip.CGPath);
      if (clip.usesEvenOddFillRule) CGContextEOClip(context); else CGContextClip(context);
    }
    UIBezierPath *path = paths.firstObject;
    CGContextAddPath(context, path.CGPath);
    if (path.usesEvenOddFillRule) CGContextEOFillPath(context); else CGContextFillPath(context);
    CGContextRestoreGState(context);
  }
}
- (void)removeOverlay
{
  [self.displayLink invalidate];
  self.displayLink = nil;
  [self removeFromSuperview];
}
- (void)dealloc
{
  [_displayLink invalidate];
}
@end
