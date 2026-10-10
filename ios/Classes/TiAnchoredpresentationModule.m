#import "TiAnchoredpresentationModule.h"
#import "TiAnchoredpresentationPresentationProxy.h"
@implementation TiAnchoredpresentationModule
- (id)moduleGUID { return @"85b3fa55-a3e4-4a49-8143-9539f11338b2"; }
- (NSString *)moduleId { return @"ti.anchoredpresentation"; }
- (id)createActionSheet:(id)args
{
  return [[TiAnchoredpresentationActionSheetProxy alloc] _initWithPageContext:self.executionContext args:args];
}
- (id)createPopover:(id)args
{
  return [[TiAnchoredpresentationPopoverProxy alloc] _initWithPageContext:self.executionContext args:args];
}
- (NSNumber *)isMorphingSupported:(id)args
{
  // Every supported deployment runs on iOS 26 or later.
  return @YES;
}
@end
