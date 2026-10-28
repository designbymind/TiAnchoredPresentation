#import "TiAnchoredpresentationPresentationProxy.h"
#import "TiAnchoredpresentationSource.h"
#import "TiAnchoredpresentationDimmingView.h"
#import <TitaniumKit/TiUtils.h>
#import <TitaniumKit/TiColor.h>
#import <TitaniumKit/TiViewController.h>
#import <TitaniumKit/TiWindowProxy.h>
#import <math.h>

@interface TiAnchoredpresentationContentController : TiViewController
@property (nonatomic, copy) void (^willAppear)(UIViewController *controller);
@property (nonatomic, copy) void (^willDisappear)(UIViewController *controller);
@property (nonatomic, copy) void (^didDisappear)(UIViewController *controller);
@property (nonatomic, assign) BOOL disableAutomaticScrollInsets;
@property (nonatomic, strong) NSMapTable<UIScrollView *, NSNumber *> *originalInsetPolicies;
@property (nonatomic, strong) NSHashTable<UITableView *> *presentationLayoutTables;
- (void)applyInsetPolicyToView:(UIView *)view;
- (void)restoreInsetPolicy;
@end
@implementation TiAnchoredpresentationContentController
- (void)applyInsetPolicyToView:(UIView *)view
{
  if (!self.disableAutomaticScrollInsets) return;
  if ([view isKindOfClass:UIScrollView.class]) {
    UIScrollView *scroll = (UIScrollView *)view;
    if (self.originalInsetPolicies == nil) self.originalInsetPolicies = [NSMapTable weakToStrongObjectsMapTable];
    if ([self.originalInsetPolicies objectForKey:scroll] == nil) {
      [self.originalInsetPolicies setObject:@(scroll.contentInsetAdjustmentBehavior) forKey:scroll];
    }
    if (scroll.contentInsetAdjustmentBehavior != UIScrollViewContentInsetAdjustmentNever) {
      scroll.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
  }
  for (UIView *child in view.subviews) [self applyInsetPolicyToView:child];
}
- (void)refreshInitialTableLayoutInView:(UIView *)view
{
  if ([view isKindOfClass:UITableView.class]) {
    UITableView *table = (UITableView *)view;
    if (self.presentationLayoutTables == nil) self.presentationLayoutTables = [NSHashTable weakObjectsHashTable];
    if (![self.presentationLayoutTables containsObject:table]) {
      // A table laid out before attachment can cache grouped-section spacing
      // for its previous presentation context. Recalculate once in this window.
      // Record it first: the update can synchronously reenter controller layout.
      [self.presentationLayoutTables addObject:table];
      [UIView performWithoutAnimation:^{
        [table beginUpdates];
        [table endUpdates];
        [table layoutIfNeeded];
      }];
    }
  }
  for (UIView *child in view.subviews) [self refreshInitialTableLayoutInView:child];
}
- (void)restoreInsetPolicy
{
  self.disableAutomaticScrollInsets = NO;
  NSMapTable<UIScrollView *, NSNumber *> *policies = self.originalInsetPolicies;
  self.originalInsetPolicies = nil;
  for (UIScrollView *scroll in policies.keyEnumerator) {
    scroll.contentInsetAdjustmentBehavior = [[policies objectForKey:scroll] integerValue];
  }
}
- (void)viewDidLayoutSubviews
{
  [super viewDidLayoutSubviews];
  TiViewProxy *proxy = [self proxy];
  proxy.sandboxBounds = self.view.bounds;
  [proxy reposition];
  [proxy layoutChildrenIfNeeded];
  [self applyInsetPolicyToView:self.view];
}
- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  if (self.willAppear != nil) self.willAppear(self);
}
- (void)viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];
  if (self.isBeingDismissed && self.willDisappear != nil) self.willDisappear(self);
}
- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  // Initial layout can precede the final presentation context even with a window.
  // Refresh section geometry once after Titanium and UIKit finish appearance.
  [self refreshInitialTableLayoutInView:self.view];
}
- (void)viewDidDisappear:(BOOL)animated
{
  [super viewDidDisappear:animated];
  // Appearance callbacks can precede UIKit removal or belong to a cancelled
  // interactive dismissal. Report the controller; never release content here.
  if (self.didDisappear != nil) self.didDisappear(self);
}
@end

typedef NS_ENUM(NSUInteger, TiAnchoredpresentationState) {
  TiAnchoredpresentationStateIdle,
  TiAnchoredpresentationStatePresenting,
  TiAnchoredpresentationStatePresented,
  TiAnchoredpresentationStateDismissing
};

@interface TiAnchoredpresentationPresentationProxy ()
@property (nonatomic, strong) TiAnchoredpresentationDimmingView *dimmingOverlay;
@property (nonatomic, strong) UIViewController *presentation;
@property (nonatomic, strong) TiAnchoredpresentationSource *source;
@property (nonatomic, strong) TiViewProxy *content;
@property (nonatomic, copy) NSDictionary *selectedAction;
@property (nonatomic, copy) NSString *dismissReason;
@property (nonatomic, assign) TiAnchoredpresentationState state;
@property (nonatomic, assign) BOOL remembered;
@property (nonatomic, assign) BOOL contentOpened;
@property (nonatomic, assign) BOOL pendingHide;
@property (nonatomic, assign) BOOL zoomRequested;
@property (nonatomic, assign) BOOL pendingHideAnimated;
@end

@implementation TiAnchoredpresentationPresentationProxy
- (BOOL)isPopover { return [self isKindOfClass:TiAnchoredpresentationPopoverProxy.class]; }
- (void)fail:(NSString *)reason detail:(NSString *)detail
{
  [self throwException:reason subreason:detail location:CODELOCATION];
}
- (NSDictionary *)options:(id)args
{
  if ([args isKindOfClass:NSArray.class] && [args count] == 0) return @{};
  ENSURE_SINGLE_ARG_OR_NIL(args, NSDictionary);
  return args ?: @{};
}
- (CGSize)validatedSize:(NSDictionary *)options
{
  double width = [TiUtils doubleValue:[options objectForKey:@"width"] def:320];
  double height = [TiUtils doubleValue:[options objectForKey:@"height"] def:240];
  if (!isfinite(width) || !isfinite(height) || width <= 0 || height <= 0) {
    [self fail:@"invalid_content_size" detail:@"width and height must be positive finite numbers in points"];
  }
  return CGSizeMake(width, height);
}
- (UIColor *)validatedBackgroundColor
{
  id value = [self valueForUndefinedKey:@"backgroundColor"];
  if (value == nil || value == [NSNull null]) return nil;
  TiColor *color = [TiUtils colorValue:value];
  if (color == nil) {
    [self fail:@"invalid_background_color" detail:@"backgroundColor must be a Titanium color value or null for the UIKit default"];
  }
  return color.color;
}
- (NSArray<UIView *> *)validatedPassthroughViewsForSource:(TiAnchoredpresentationSource *)source
{
  id value = [self valueForUndefinedKey:@"passthroughViews"];
  if (value == nil || value == [NSNull null]) return nil;
  if (![value isKindOfClass:NSArray.class]) {
    [self fail:@"invalid_passthrough_views" detail:@"passthroughViews must be an array of visible Titanium views"];
  }
  NSMutableArray<UIView *> *views = [NSMutableArray array];
  for (id proxy in value) {
    if (![proxy isKindOfClass:TiViewProxy.class]) {
      [self fail:@"invalid_passthrough_view" detail:@"Each passthroughViews entry must be a visible Titanium view"];
    }
    // Re-resolve on every show; never cache a view from a recycled row or a
    // previous presentation. Standard bar items do not expose a native UIView.
    TiAnchoredpresentationSource *resolved = [TiAnchoredpresentationSource resolve:proxy];
    UIView *view = [resolved nativeSourceView];
    if (view == nil || view.window != source.presenter.view.window) {
      [self fail:@"invalid_passthrough_view" detail:@"Pass-through views must be visible ordinary views in the source window; detached views and bar items are not supported"];
    }
    if (![views containsObject:view]) [views addObject:view];
  }
  return views;
}
- (NSArray<TiAnchoredpresentationDimmingExclusion *> *)validatedDimmingExclusions
{
  NSArray *proxies = [self valueForUndefinedKey:@"passthroughViews"];
  if ((id)proxies == [NSNull null]) proxies = nil;
  id overrides = [self valueForUndefinedKey:@"dimmingCutoutShapes"];
  if (overrides == nil || overrides == [NSNull null]) overrides = @[];
  if (![overrides isKindOfClass:NSArray.class]) {
    [self fail:@"invalid_dimming_cutout_shapes" detail:@"dimmingCutoutShapes must be an array of { view, shape, cornerRadius? } dictionaries"];
  }
  NSMapTable *shapes = [NSMapTable strongToStrongObjectsMapTable];
  for (id entry in overrides) {
    if (![entry isKindOfClass:NSDictionary.class]) {
      [self fail:@"invalid_dimming_cutout_shape" detail:@"Each dimmingCutoutShapes entry must be a dictionary"];
    }
    id proxy = entry[@"view"];
    id shape = entry[@"shape"];
    if (![proxy isKindOfClass:TiViewProxy.class] || ![proxies containsObject:proxy] || [shapes objectForKey:proxy] != nil) {
      [self fail:@"invalid_dimming_cutout_view" detail:@"Each cutout override must reference a unique view in passthroughViews"];
    }
    if (![shape isKindOfClass:NSString.class] || ![@[@"auto", @"circle", @"capsule", @"roundedRect"] containsObject:shape]) {
      [self fail:@"invalid_dimming_cutout_shape" detail:@"shape must be auto, circle, capsule, or roundedRect"];
    }
    id radius = entry[@"cornerRadius"];
    if (([shape isEqualToString:@"roundedRect"] && radius == nil) ||
        (radius != nil && (![radius isKindOfClass:NSNumber.class] || !isfinite([radius doubleValue]) || [radius doubleValue] < 0))) {
      [self fail:@"invalid_dimming_cutout_radius" detail:@"roundedRect requires a finite nonnegative cornerRadius in points"];
    }
    [shapes setObject:entry forKey:proxy];
  }
  NSMutableArray *exclusions = [NSMutableArray array];
  for (TiViewProxy *proxy in proxies) {
    // Native pass-through targets have already been validated. Keep their UIKit
    // touch routing, while drawing the cutout around the Titanium visual wrapper.
    UIView *view = [[TiAnchoredpresentationSource resolve:proxy] nativeSourceView];
    TiAnchoredpresentationDimmingExclusion *exclusion = [TiAnchoredpresentationDimmingExclusion new];
    exclusion.view = view;
    exclusion.shapeView = [proxy view];
    NSDictionary *entry = [shapes objectForKey:proxy];
    exclusion.shape = entry[@"shape"] ?: @"auto";
    exclusion.cornerRadius = [entry[@"cornerRadius"] doubleValue];
    [exclusions addObject:exclusion];
  }
  return exclusions;
}
- (CGFloat)validatedDimmingOpacity
{
  id value = [self valueForUndefinedKey:@"dimmingOpacity"];
  double opacity = value == nil ? 0.35 : [TiUtils doubleValue:value def:NAN];
  if (!isfinite(opacity) || opacity < 0 || opacity > 1) {
    [self fail:@"invalid_dimming_opacity" detail:@"dimmingOpacity must be a finite number between 0 and 1"];
  }
  return opacity;
}
- (void)animateDimmingForController:(UIViewController *)controller visible:(BOOL)visible
{
  if (self.presentation != controller || self.dimmingOverlay == nil) return;
  TiAnchoredpresentationDimmingView *overlay = self.dimmingOverlay;
  CGFloat target = visible ? 1 : 0;
  if (overlay.alpha == target) return;
  id<UIViewControllerTransitionCoordinator> coordinator = controller.transitionCoordinator;
  BOOL joined = [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
    overlay.alpha = target;
  } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
    // UIKit reverses its animation on cancellation; restore the matching model
    // value too. Capture this overlay, never a later presentation's overlay.
    overlay.alpha = context.isCancelled ? 1 - target : target;
  }];
  if (!joined) overlay.alpha = target;
}
- (NSArray *)validatedActions
{
  id value = [self valueForUndefinedKey:@"actions"];
  if (![value isKindOfClass:NSArray.class] || [value count] == 0) {
    [self fail:@"invalid_actions" detail:@"actions must be a nonempty array"];
  }
  NSMutableArray *actions = [NSMutableArray array];
  NSMutableSet *identifiers = [NSMutableSet set];
  BOOL hasCancel = NO;
  for (id entry in value) {
    if (![entry isKindOfClass:NSDictionary.class]) [self fail:@"invalid_action" detail:@"Each action must be a dictionary"];
    NSString *title = [entry objectForKey:@"title"];
    NSString *style = [entry objectForKey:@"style"] ?: @"default";
    id identifier = [entry objectForKey:@"id"] ?: [NSString stringWithFormat:@"%lu", (unsigned long)actions.count];
    if (![title isKindOfClass:NSString.class] || title.length == 0 ||
        ![identifier isKindOfClass:NSString.class] || ![style isKindOfClass:NSString.class] ||
        ![@[@"default", @"destructive", @"cancel"] containsObject:style] || [identifiers containsObject:identifier]) {
      [self fail:@"invalid_action" detail:@"Actions require a title, unique string id, and default/destructive/cancel style"];
    }
    if ([style isEqualToString:@"cancel"] && hasCancel) [self fail:@"invalid_action" detail:@"Only one cancel action is allowed"];
    hasCancel |= [style isEqualToString:@"cancel"];
    [identifiers addObject:identifier];
    [actions addObject:@{@"id":identifier, @"title":title, @"style":style,
      @"enabled":@([TiUtils boolValue:[entry objectForKey:@"enabled"] def:YES]), @"index":@(actions.count)}];
  }
  return actions;
}
- (void)configureTransitionForController:(UIViewController *)controller
{
  if (!self.zoomRequested) return;
  __weak __typeof__(self) weakSelf = self;
  __weak UIViewController *weakController = controller;
  UIZoomTransitionOptions *options = [UIZoomTransitionOptions new];
  options.interactiveDismissShouldBegin = ^BOOL(UIZoomTransitionInteractionContext *context) {
    __typeof__(self) strongSelf = weakSelf;
    UIViewController *current = weakController;
    return strongSelf != nil && current != nil && strongSelf.presentation == current &&
        !current.modalInPresentation && context.willBegin;
  };
  if (self.source.item != nil) {
    controller.preferredTransition = [UIViewControllerTransition zoomWithOptions:options sourceBarButtonItemProvider:^UIBarButtonItem *(UIZoomTransitionSourceViewProviderContext *context) {
      __typeof__(self) strongSelf = weakSelf;
      UIViewController *current = weakController;
      if (strongSelf == nil || current == nil || strongSelf.presentation != current) return nil;
      TiAnchoredpresentationSource *source = [TiAnchoredpresentationSource resolve:strongSelf.source.proxy excluding:current];
      return source.item;
    }];
  } else {
    controller.preferredTransition = [UIViewControllerTransition zoomWithOptions:options sourceViewProvider:^UIView *(UIZoomTransitionSourceViewProviderContext *context) {
      __typeof__(self) strongSelf = weakSelf;
      UIViewController *current = weakController;
      if (strongSelf == nil || current == nil || strongSelf.presentation != current) return nil;
      TiAnchoredpresentationSource *source = [TiAnchoredpresentationSource resolve:strongSelf.source.proxy excluding:current];
      return [source nativeSourceView];
    }];
  }
}
- (void)show:(id)args
{
  ENSURE_UI_THREAD(show, args);
  NSDictionary *options = [self options:args];
  // Repeated taps during either transition do not create another controller.
  if (self.presentation != nil) return;
  id proxy = [options objectForKey:@"sourceView"] ?: [self valueForUndefinedKey:@"sourceView"];
  if (![proxy isKindOfClass:TiViewProxy.class]) [self fail:@"invalid_source" detail:@"show requires a visible Titanium sourceView"];
  TiAnchoredpresentationSource *source = [TiAnchoredpresentationSource resolve:proxy];
  if (source == nil) [self fail:@"source_not_visible" detail:@"Attach the source to a visible window/navigation bar/toolbar before show"];
  id rect = [options objectForKey:@"sourceRect"];
  if (rect != nil) {
    if (![rect isKindOfClass:NSDictionary.class] || source.item != nil) [self fail:@"invalid_source_rect" detail:@"sourceRect requires a normal view source and a rectangle dictionary"];
    for (NSString *key in @[@"x", @"y", @"width", @"height"]) {
      id number = [rect objectForKey:key];
      if (![number isKindOfClass:NSNumber.class] || !isfinite([number doubleValue])) [self fail:@"invalid_source_rect" detail:@"sourceRect needs finite x, y, width and height numbers"];
    }
    if ([rect[@"width"] doubleValue] <= 0 || [rect[@"height"] doubleValue] <= 0) [self fail:@"invalid_source_rect" detail:@"sourceRect must have positive width and height"];
  }
  NSInteger arrows = [TiUtils intValue:[self valueForUndefinedKey:@"arrowDirections"] def:UIPopoverArrowDirectionAny];
  if (arrows < 0 || (arrows & ~UIPopoverArrowDirectionAny) != 0) [self fail:@"invalid_arrow_directions" detail:@"Use none/up/down/left/right arrow bit flags (0, 1, 2, 4, 8)"];
  id transition = [self valueForUndefinedKey:@"transition"] ?: @"system";
  if (![transition isKindOfClass:NSString.class] || ![@[@"system", @"zoom"] containsObject:transition]) {
    [self fail:@"invalid_transition" detail:@"transition must be system or zoom"];
  }
  if (![self isPopover] && [transition isEqual:@"zoom"]) {
    [self fail:@"unsupported_transition" detail:@"The zoom transition is for custom-content popovers"];
  }
  CGFloat dimmingOpacity = [self validatedDimmingOpacity];
  BOOL dimmingEnabled = [TiUtils boolValue:[self valueForUndefinedKey:@"dimmingEnabled"] def:NO];
  BOOL excludesPassthrough = [TiUtils boolValue:[self valueForUndefinedKey:@"dimmingExcludesPassthroughViews"] def:NO];
  UIColor *backgroundColor = [self validatedBackgroundColor];
  NSArray<UIView *> *passthroughViews = [self validatedPassthroughViewsForSource:source];
  NSArray<TiAnchoredpresentationDimmingExclusion *> *dimmingExclusions = [self validatedDimmingExclusions];
  UIViewController *controller;
  TiViewProxy *content = nil;
  __weak __typeof__(self) weakSelf = self;
  if ([self isPopover]) {
    id value = [self valueForUndefinedKey:@"contentView"];
    if (![value isKindOfClass:TiViewProxy.class] || [value isKindOfClass:TiWindowProxy.class]) {
      [self fail:@"invalid_content" detail:@"contentView must be a Titanium view tree, not a Window or NavigationWindow"];
    }
    content = value;
    if (content.parent != nil || content.view.superview != nil || content.windowHasOpened) {
      [self fail:@"content_already_attached" detail:@"Use a dedicated unattached contentView for each popover"];
    }
    CGSize size = [self validatedSize:@{@"width":[self valueForUndefinedKey:@"width"] ?: @320,
                                       @"height":[self valueForUndefinedKey:@"height"] ?: @240}];
    TiAnchoredpresentationContentController *host = [[TiAnchoredpresentationContentController alloc] initWithViewProxy:content];
    host.preferredContentSize = size;
    host.disableAutomaticScrollInsets = ![TiUtils boolValue:[self valueForUndefinedKey:@"autoAdjustScrollViewInsets"] def:NO];
    host.modalPresentationStyle = UIModalPresentationPopover;
    host.willAppear = ^(UIViewController *appearing) {
      if (weakSelf.state == TiAnchoredpresentationStatePresenting) [weakSelf animateDimmingForController:appearing visible:YES];
    };
    host.willDisappear = ^(UIViewController *disappearing) {
      [weakSelf animateDimmingForController:disappearing visible:NO];
    };
    host.didDisappear = ^(UIViewController *disappeared) {
      [weakSelf observeDisappearanceOfController:disappeared];
    };
    controller = host;
  } else {
    NSArray *actions = [self validatedActions];
    NSString *title = [TiUtils stringValue:[self valueForUndefinedKey:@"title"]];
    NSString *message = [TiUtils stringValue:[self valueForUndefinedKey:@"message"]];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleActionSheet];
    __weak UIAlertController *weakAlert = alert;
    for (NSDictionary *entry in actions) {
      NSString *style = entry[@"style"];
      UIAlertActionStyle nativeStyle = [style isEqualToString:@"cancel"] ? UIAlertActionStyleCancel :
          ([style isEqualToString:@"destructive"] ? UIAlertActionStyleDestructive : UIAlertActionStyleDefault);
      UIAlertAction *action = [UIAlertAction actionWithTitle:entry[@"title"] style:nativeStyle handler:^(UIAlertAction *selected) {
        __typeof__(self) strongSelf = weakSelf;
        if (strongSelf == nil || strongSelf.presentation != weakAlert) return;
        strongSelf.selectedAction = entry;
        strongSelf.dismissReason = [style isEqualToString:@"cancel"] ? @"cancel" : @"action";
        // Let UIAlertController initiate its own dismissal, then join it.
        dispatch_async(dispatch_get_main_queue(), ^{
          if (strongSelf.presentation == weakAlert) [strongSelf dismissAnimated:YES];
        });
      }];
      action.enabled = [entry[@"enabled"] boolValue];
      [alert addAction:action];
    }
    controller = alert;
  }
  self.presentation = controller;
  self.source = source;
  self.content = content;
  self.zoomRequested = [transition isEqual:@"zoom"];
  [self configureTransitionForController:controller];
  self.dismissReason = @"outside";
  self.selectedAction = nil;
  self.state = TiAnchoredpresentationStatePresenting;
  self.pendingHide = NO;
  [self rememberSelf];
  self.remembered = YES;
  UIPopoverPresentationController *popover = controller.popoverPresentationController;
  [source configure:popover rect:rect];
  popover.permittedArrowDirections = arrows;
  popover.passthroughViews = passthroughViews;
  popover.backgroundColor = backgroundColor;
  popover.delegate = self;
  controller.modalInPresentation = ![TiUtils boolValue:[self valueForUndefinedKey:@"dismissOnOutsideTap"] def:YES];
  if (content != nil) {
    [content windowWillOpen];
    self.contentOpened = YES;
    (void)controller.view;
    content.sandboxBounds = controller.view.bounds;
    [content reposition];
    [content layoutChildrenIfNeeded];
    [(TiAnchoredpresentationContentController *)controller applyInsetPolicyToView:controller.view];
  }
  BOOL animated = [TiUtils boolValue:[options objectForKey:@"animated"] def:YES];
  @try {
    if (dimmingEnabled && dimmingOpacity > 0) {
      UIWindow *window = source.presenter.view.window;
      self.dimmingOverlay = [[TiAnchoredpresentationDimmingView alloc] initWithWindow:window opacity:dimmingOpacity
          exclusions:excludesPassthrough ? dimmingExclusions : nil];
      self.dimmingOverlay.alpha = animated ? 0 : 1;
      // Insert before UIKit adds its presentation container, leaving all of its
      // chrome, touch handling and zoom rendering above the noninteractive layer.
      [window addSubview:self.dimmingOverlay];
    }
    [source.presenter presentViewController:controller animated:animated completion:^{
      __typeof__(self) strongSelf = weakSelf;
      if (strongSelf == nil || strongSelf.presentation != controller ||
          strongSelf.state != TiAnchoredpresentationStatePresenting) return;
      [strongSelf animateDimmingForController:controller visible:YES];
      strongSelf.state = TiAnchoredpresentationStatePresented;
      if (strongSelf.contentOpened) [strongSelf.content windowDidOpen];
      if ([strongSelf _hasListeners:@"show"]) [strongSelf fireEvent:@"show" withObject:@{@"sourceKind":source.kind}];
      if (strongSelf.pendingHide) [strongSelf dismissAnimated:strongSelf.pendingHideAnimated];
    }];
    if (![self isPopover]) [self animateDimmingForController:controller visible:YES];
  } @catch (NSException *exception) {
    self.dismissReason = @"error";
    [self finishDismissalForController:controller];
    @throw exception;
  }
}
- (void)hide:(id)args
{
  ENSURE_UI_THREAD(hide, args);
  NSDictionary *options = [self options:args];
  if (self.presentation == nil || self.state == TiAnchoredpresentationStateDismissing) return;
  self.dismissReason = @"programmatic";
  BOOL animated = [TiUtils boolValue:[options objectForKey:@"animated"] def:YES];
  if (self.state == TiAnchoredpresentationStatePresenting) {
    self.pendingHide = YES;
    self.pendingHideAnimated = animated;
    return;
  }
  [self dismissAnimated:animated];
}
- (void)dismissAnimated:(BOOL)animated
{
  UIViewController *controller = self.presentation;
  if (controller == nil || self.state == TiAnchoredpresentationStateDismissing) return;
  if (self.state == TiAnchoredpresentationStatePresenting && !controller.isBeingDismissed) {
    self.pendingHide = YES;
    self.pendingHideAnimated = animated;
    return;
  }
  self.state = TiAnchoredpresentationStateDismissing;
  self.pendingHide = NO;
  __weak __typeof__(self) weakSelf = self;
  // Glass popovers can call the presentation completion before clearing their
  // internal transitioning flag. Leave that UIKit callback stack before asking
  // for dismissal; this is a main-loop handoff, not a timed animation delay.
  dispatch_async(dispatch_get_main_queue(), ^{
    [weakSelf beginDismissalOfController:controller animated:animated];
  });
}
- (void)beginDismissalOfController:(UIViewController *)controller animated:(BOOL)animated
{
  if (self.presentation != controller || self.state != TiAnchoredpresentationStateDismissing) return;
  __weak __typeof__(self) weakSelf = self;
  if (controller.isBeingDismissed) {
    [self animateDimmingForController:controller visible:NO];
    // Join UIKit's dismissal (e.g. an action selection) instead of issuing a
    // second dismiss request. Every completion is scoped to this controller.
    id<UIViewControllerTransitionCoordinator> coordinator = controller.transitionCoordinator;
    BOOL joined = [coordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
      __typeof__(self) strongSelf = weakSelf;
      if (strongSelf.presentation != controller) return;
      if (!context.isCancelled) [strongSelf finishDismissalForController:controller];
      else {
        strongSelf.state = TiAnchoredpresentationStatePresented;
        strongSelf.dismissReason = @"outside";
      }
    }];
    if (joined) return;
    // UIKit's presentation delegate or the disappearance observer completes it.
    [self observeDisappearanceOfController:controller];
    return;
  }
  if (controller.presentingViewController == nil) {
    [self observeDisappearanceOfController:controller];
  } else {
    [controller dismissViewControllerAnimated:animated completion:^{
      [weakSelf finishDismissalForController:controller];
    }];
    [self animateDimmingForController:controller visible:NO];
  }
}
- (void)observeDisappearanceOfController:(UIViewController *)controller
{
  if (self.presentation != controller) return;
  __weak __typeof__(self) weakSelf = self;
  id<UIViewControllerTransitionCoordinator> coordinator = controller.transitionCoordinator;
  if (coordinator != nil) {
    BOOL joined = [coordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
      __typeof__(self) strongSelf = weakSelf;
      if (strongSelf.presentation != controller) return;
      if (context.isCancelled) {
        strongSelf.state = TiAnchoredpresentationStatePresented;
        strongSelf.dismissReason = @"outside";
      } else {
        [strongSelf finishDismissalForController:controller];
      }
    }];
    if (joined) return;
  }
  // UIKit can deliver viewDidDisappear before detaching the presentation. Check
  // on the next main-loop turn rather than using a guessed animation duration.
  dispatch_async(dispatch_get_main_queue(), ^{
    [weakSelf finishDismissalForController:controller];
  });
}
- (void)finishDismissalForController:(UIViewController *)controller
{
  // Old controllers can deliver appearance/delegate/completion callbacks after
  // a new show. They must never tear down that new controller's content.
  if (controller == nil || self.presentation != controller) return;
  if (controller.presentingViewController != nil || controller.viewIfLoaded.window != nil ||
      controller.isBeingPresented || controller.isBeingDismissed) return;
  __attribute__((objc_precise_lifetime)) __typeof__(self) keepAlive = self;
  (void)keepAlive;
  NSDictionary *action = self.selectedAction;
  NSString *reason = self.dismissReason ?: @"outside";
  [self.dimmingOverlay removeOverlay];
  self.dimmingOverlay = nil;
  controller.popoverPresentationController.delegate = nil;
  if ([controller isKindOfClass:TiAnchoredpresentationContentController.class]) {
    ((TiAnchoredpresentationContentController *)controller).willAppear = nil;
    ((TiAnchoredpresentationContentController *)controller).willDisappear = nil;
    ((TiAnchoredpresentationContentController *)controller).didDisappear = nil;
    [(TiAnchoredpresentationContentController *)controller restoreInsetPolicy];
  }
  if (self.contentOpened) {
    [self.content windowWillClose];
    [self.content.view removeFromSuperview];
    [self.content windowDidClose];
  }
  self.contentOpened = NO;
  self.content = nil;
  self.presentation = nil;
  self.source = nil;
  self.zoomRequested = NO;
  self.selectedAction = nil;
  self.state = TiAnchoredpresentationStateIdle;
  self.pendingHide = NO;
  BOOL remembered = self.remembered;
  self.remembered = NO;
  // Release this presentation's bridge hold before callbacks can reopen it.
  if (remembered) [self forgetSelf];
  if (action != nil && [self _hasListeners:@"click"]) [self fireEvent:@"click" withObject:action];
  if ([self _hasListeners:@"dismiss"]) [self fireEvent:@"dismiss" withObject:@{@"reason":reason}];
}
- (void)setContentSize:(id)args
{
  ENSURE_UI_THREAD(setContentSize, args);
  if (![self isPopover]) [self fail:@"unsupported_operation" detail:@"setContentSize is for custom-content popovers"];
  NSDictionary *options = [self options:args];
  CGSize size = [self validatedSize:options];
  [self replaceValue:@(size.width) forKey:@"width" notification:NO];
  [self replaceValue:@(size.height) forKey:@"height" notification:NO];
  self.presentation.preferredContentSize = size;
}
- (void)setSourceView:(id)args
{
  ENSURE_UI_THREAD(setSourceView, args);
  ENSURE_SINGLE_ARG(args, TiViewProxy);
  if (self.presentation == nil) {
    [self replaceValue:args forKey:@"sourceView" notification:NO];
    return;
  }
  TiAnchoredpresentationSource *source = [TiAnchoredpresentationSource resolve:args excluding:self.presentation];
  if (source == nil) [self fail:@"source_not_visible" detail:@"The new source must be visible"];
  if (self.presentation != nil && source.presenter != self.source.presenter) [self fail:@"different_presenter" detail:@"A visible popover cannot move to another presentation controller"];
  [self replaceValue:args forKey:@"sourceView" notification:NO];
  if (self.presentation != nil) {
    self.presentation.popoverPresentationController.sourceItem = nil;
    self.presentation.popoverPresentationController.sourceView = nil;
    [source configure:self.presentation.popoverPresentationController rect:nil];
    self.source = source;
    [self configureTransitionForController:self.presentation];
  }
}
- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller
{
  // Keep custom content anchored even on compact-width iPhone layouts.
  return [self isPopover] ? UIModalPresentationNone : UIModalPresentationAutomatic;
}
- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller traitCollection:(UITraitCollection *)traits
{
  return [self adaptivePresentationStyleForPresentationController:controller];
}
- (BOOL)popoverPresentationControllerShouldDismissPopover:(UIPopoverPresentationController *)controller
{
  return [TiUtils boolValue:[self valueForUndefinedKey:@"dismissOnOutsideTap"] def:YES];
}
- (BOOL)presentationControllerShouldDismiss:(UIPresentationController *)controller
{
  return [TiUtils boolValue:[self valueForUndefinedKey:@"dismissOnOutsideTap"] def:YES];
}
- (void)presentationControllerWillDismiss:(UIPresentationController *)controller
{
  [self animateDimmingForController:controller.presentedViewController visible:NO];
}
- (void)presentationControllerDidDismiss:(UIPresentationController *)controller
{
  [self observeDisappearanceOfController:controller.presentedViewController];
}
- (void)popoverPresentationControllerDidDismissPopover:(UIPopoverPresentationController *)controller
{
  [self observeDisappearanceOfController:controller.presentedViewController];
}
@end
@implementation TiAnchoredpresentationActionSheetProxy
- (NSString *)apiName { return @"Ti.AnchoredPresentation.ActionSheet"; }
@end
@implementation TiAnchoredpresentationPopoverProxy
- (NSString *)apiName { return @"Ti.AnchoredPresentation.Popover"; }
@end
