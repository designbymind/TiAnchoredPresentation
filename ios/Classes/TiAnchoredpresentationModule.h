#import <TitaniumKit/TiModule.h>
@interface TiAnchoredpresentationModule : TiModule
- (id)createActionSheet:(id)args;
- (id)createPopover:(id)args;
- (NSNumber *)isMorphingSupported:(id)args;
@end
