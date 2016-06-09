#import <UIKit/UIKit.h>
#import <Cephei/HBLinkTableCell.h>

@implementation UIViewController (Hack)

- (void)setEdgesForExtendedLayout:(UIRectEdge)edge
{
}

@end

@implementation UIView (Hack)

- (void)setTintColor:(UIColor *)color
{
}

@end


@implementation HBLinkTableCell (Hack)

- (UIColor *)tintColor
{
	return nil;
}

@end