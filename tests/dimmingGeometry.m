#import <UIKit/UIKit.h>
#import "TiAnchoredpresentationDimmingView.h"

@interface TiAnchoredpresentationDimmingView (Testing)
- (void)updateCutouts;
@end

static NSUInteger failures;
static CGFloat AlphaAt(UIView *view, CGPoint point) {
  NSUInteger width = ceil(view.bounds.size.width), height = ceil(view.bounds.size.height);
  unsigned char *pixels = calloc(width * height, 4);
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  CGContextRef context = CGBitmapContextCreate(pixels, width, height, 8, width * 4, colorSpace, (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
  CGColorSpaceRelease(colorSpace);
  // drawRect is tested directly: layer opacity is separately controlled by UIKit.
  // Bitmap rows run opposite UIKit view coordinates, hence the flipped sample.
  UIGraphicsPushContext(context);
  [view drawRect:view.bounds];
  UIGraphicsPopContext();
  CGFloat alpha = pixels[((height - 1 - (NSUInteger)point.y) * width + (NSUInteger)point.x) * 4 + 3] / 255.0;
  CGContextRelease(context); free(pixels); return alpha;
}
static void Check(BOOL condition, NSString *name) {
  if (!condition) failures++;
  NSLog(@"DIM_GEOMETRY %@ %@", condition ? @"PASS" : @"FAIL", name);
}
@interface GeometryScene : UIResponder <UIWindowSceneDelegate>
@property (nonatomic, strong) UIWindow *window;
@end
@implementation GeometryScene
- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)options {
  self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
  UIViewController *root = [UIViewController new]; root.view.backgroundColor = UIColor.whiteColor;
  self.window.rootViewController = root; [self.window makeKeyAndVisible];
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 500 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
    UIView *first = [[UIView alloc] initWithFrame:CGRectMake(40,100,100,80)];
    first.layer.cornerRadius = 16; [root.view addSubview:first];
    UIView *second = [[UIView alloc] initWithFrame:CGRectMake(100,120,100,80)]; [root.view addSubview:second];
    TiAnchoredpresentationDimmingView *overlay = [[TiAnchoredpresentationDimmingView alloc] initWithWindow:self.window opacity:0.35 excludedViews:@[first,second]];
    [self.window addSubview:overlay]; [overlay layoutIfNeeded];
    Check(!overlay.userInteractionEnabled && overlay.accessibilityElementsHidden, @"noninteractive/accessibility");
    Check(fabs(AlphaAt(overlay,CGPointMake(20,50))-.35)<.01, @"background opacity");
    Check(AlphaAt(overlay,CGPointMake(70,140))==0, @"first cutout");
    Check(AlphaAt(overlay,CGPointMake(120,140))==0, @"overlap remains clear");
    Check(AlphaAt(overlay,CGPointMake(41,101))>.3, @"rounded corner remains dim");
    first.hidden = YES;
    [overlay updateCutouts];
    Check(AlphaAt(overlay,CGPointMake(70,140))>.3, @"hidden view closes cutout");
    second.frame=CGRectMake(240,120,100,80);
    [overlay updateCutouts];
    Check(AlphaAt(overlay,CGPointMake(120,140))>.3 && AlphaAt(overlay,CGPointMake(260,140))==0, @"moved view tracks");
    UIView *clip=[[UIView alloc] initWithFrame:CGRectMake(30,300,60,60)]; clip.clipsToBounds=YES; [root.view addSubview:clip];
    [second removeFromSuperview]; second.frame=CGRectMake(0,0,100,80); [clip addSubview:second];
    [overlay updateCutouts];
    Check(AlphaAt(overlay,CGPointMake(50,320))==0 && AlphaAt(overlay,CGPointMake(110,320))>.3, @"ancestor clipping");
    [second removeFromSuperview]; [overlay updateCutouts];
    Check(AlphaAt(overlay,CGPointMake(50,320))>.3, @"detached view closes cutout");
    [overlay removeOverlay];
    Check(overlay.superview==nil && [overlay valueForKey:@"displayLink"]==nil, @"cleanup stops tracking");
    TiAnchoredpresentationDimmingView *plain=[[TiAnchoredpresentationDimmingView alloc] initWithWindow:self.window opacity:1 excludedViews:nil];
    [self.window addSubview:plain];
    Check(AlphaAt(plain,CGPointMake(70,140))==1 && [plain valueForKey:@"displayLink"]==nil, @"full dimming needs no display link");
    [plain removeOverlay];

    UIView *wrapper = [[UIView alloc] initWithFrame:CGRectMake(40,400,120,60)];
    wrapper.layer.cornerRadius = 20;
    UIButton *inner = [[UIButton alloc] initWithFrame:wrapper.bounds];
    [wrapper addSubview:inner]; [root.view addSubview:wrapper];
    TiAnchoredpresentationDimmingExclusion *exclusion = [TiAnchoredpresentationDimmingExclusion new];
    exclusion.view = inner; exclusion.shapeView = wrapper; exclusion.shape = @"auto";
    TiAnchoredpresentationDimmingView *shaped = [[TiAnchoredpresentationDimmingView alloc] initWithWindow:self.window opacity:.35 exclusions:@[exclusion]];
    [self.window addSubview:shaped];
    Check(AlphaAt(shaped,CGPointMake(41,401))>.3 && AlphaAt(shaped,CGPointMake(100,430))==0, @"Titanium-style rounded wrapper around inner control");

    wrapper.layer.maskedCorners = kCALayerMinXMinYCorner;
    [shaped updateCutouts];
    Check(AlphaAt(shaped,CGPointMake(41,401))>.3 && AlphaAt(shaped,CGPointMake(158,401))==0, @"individual masked corners");
    wrapper.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner | kCALayerMinXMaxYCorner | kCALayerMaxXMaxYCorner;
    wrapper.layer.cornerRadius = 0;
    CAShapeLayer *mask = [CAShapeLayer layer]; mask.frame = wrapper.bounds;
    mask.path = [UIBezierPath bezierPathWithRoundedRect:wrapper.bounds cornerRadius:20].CGPath;
    wrapper.layer.mask = mask;
    [shaped updateCutouts];
    Check(AlphaAt(shaped,CGPointMake(41,401))>.3 && AlphaAt(shaped,CGPointMake(100,430))==0, @"shape-layer mask detection");
    wrapper.layer.mask = nil;

    inner.configuration = UIButtonConfiguration.plainButtonConfiguration;
    UIButtonConfiguration *configuration = inner.configuration;
    configuration.cornerStyle = UIButtonConfigurationCornerStyleCapsule;
    inner.configuration = configuration;
    [shaped updateCutouts];
    Check(AlphaAt(shaped,CGPointMake(41,401))>.3 && AlphaAt(shaped,CGPointMake(50,430))==0, @"UIKit capsule configuration");
    inner.configuration = nil;

    exclusion.shape = @"circle"; [shaped updateCutouts];
    Check(AlphaAt(shaped,CGPointMake(50,430))>.3 && AlphaAt(shaped,CGPointMake(100,430))==0, @"explicit inscribed circle on nonsquare view");
    exclusion.shape = @"capsule"; [shaped updateCutouts];
    Check(AlphaAt(shaped,CGPointMake(41,401))>.3 && AlphaAt(shaped,CGPointMake(50,430))==0, @"explicit capsule");
    exclusion.shape = @"roundedRect"; exclusion.cornerRadius = 20; [shaped updateCutouts];
    Check(AlphaAt(shaped,CGPointMake(41,401))>.3 && AlphaAt(shaped,CGPointMake(50,430))==0, @"explicit rounded rectangle");
    exclusion.cornerRadius = 0; [shaped updateCutouts];
    Check(AlphaAt(shaped,CGPointMake(41,401))==0, @"zero corner radius");
    exclusion.cornerRadius = 1000; [shaped updateCutouts];
    Check(AlphaAt(shaped,CGPointMake(41,401))>.3 && AlphaAt(shaped,CGPointMake(100,430))==0, @"oversized radius clamped");
    [shaped removeOverlay];

    UIView *roundedClip = [[UIView alloc] initWithFrame:CGRectMake(220,400,100,80)];
    roundedClip.clipsToBounds = YES; roundedClip.layer.cornerRadius = 24;
    UIView *child = [[UIView alloc] initWithFrame:roundedClip.bounds];
    [roundedClip addSubview:child]; [root.view addSubview:roundedClip];
    TiAnchoredpresentationDimmingView *clipped = [[TiAnchoredpresentationDimmingView alloc] initWithWindow:self.window opacity:.35 excludedViews:@[child]];
    [self.window addSubview:clipped];
    Check(AlphaAt(clipped,CGPointMake(221,401))>.3 && AlphaAt(clipped,CGPointMake(260,440))==0, @"rounded ancestor clipping");
    [clipped removeOverlay];
    UIView *rotated = [[UIView alloc] initWithFrame:CGRectMake(40,600,120,40)];
    rotated.layer.cornerRadius = 20;
    rotated.transform = CGAffineTransformMakeRotation(M_PI_2);
    [root.view addSubview:rotated];
    TiAnchoredpresentationDimmingView *transformed = [[TiAnchoredpresentationDimmingView alloc] initWithWindow:self.window opacity:.35 excludedViews:@[rotated]];
    [self.window addSubview:transformed];
    Check(AlphaAt(transformed,CGPointMake(100,620))==0 && AlphaAt(transformed,CGPointMake(50,620))>.3, @"2D rotated shape conversion");
    [transformed removeOverlay];
    NSLog(@"DIM_GEOMETRY COMPLETE failures=%lu",(unsigned long)failures);
  });
}
@end
@interface GeometryApp : UIResponder <UIApplicationDelegate>
@end
@implementation GeometryApp
- (UISceneConfiguration *)application:(UIApplication *)app configurationForConnectingSceneSession:(UISceneSession *)session options:(UISceneConnectionOptions *)options {
  UISceneConfiguration *config=[[UISceneConfiguration alloc] initWithName:@"Geometry" sessionRole:session.role];config.delegateClass=GeometryScene.class;return config;
}
@end
int main(int argc, char **argv) { @autoreleasepool { return UIApplicationMain(argc,argv,nil,NSStringFromClass(GeometryApp.class)); } }
