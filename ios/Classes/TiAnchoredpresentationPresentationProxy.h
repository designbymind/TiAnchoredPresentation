#import <TitaniumKit/TiProxy.h>
#import <UIKit/UIKit.h>
@interface TiAnchoredpresentationPresentationProxy : TiProxy <UIPopoverPresentationControllerDelegate>
- (void)show:(id)args;
- (void)hide:(id)args;
- (void)setContentSize:(id)args;
- (void)setSourceView:(id)args;
@end
@interface TiAnchoredpresentationActionSheetProxy : TiAnchoredpresentationPresentationProxy
@end
@interface TiAnchoredpresentationPopoverProxy : TiAnchoredpresentationPresentationProxy
@end
