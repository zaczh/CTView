#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>

@protocol CTViewDelegate;

@interface CTView : UIView

@property (retain, nonatomic) NSString *text;
@property (retain, nonatomic) NSAttributedString *attributedText;
@property (retain, nonatomic) UIFont *font;
@property (retain, nonatomic) UIColor *textColor;
@property (nonatomic) NSLineBreakMode lineBreakMode;
@property (nonatomic) NSTextAlignment textAlignment;
@property (retain, nonatomic) id<CTViewDelegate> delegate;
@property (nonatomic, assign) CGSize bestFitSize;

/*
 use this method to calculate the size of the drawing area,
 please note that you must set a valid font attribute of the
 attributedString before calling this, or you might get a wrong size.
 And the returned size is a float value, you may need to ceil it to an int one.
 */
+ (CGSize)fitSizeForAttributedString:(NSAttributedString *)attrStr boundingSize:(CGSize)size options:(NSStringDrawingOptions)options context:(NSStringDrawingContext *)context;

@end


@protocol CTViewDelegate <NSObject>

@required
- (void)CTView:(CTView *)view willOpenLinkURL:(NSURL *)url;

@end
