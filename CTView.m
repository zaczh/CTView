#import "CTView.h"

//the emoji string is like "[smile] or [微笑]".
//You may change it for your own purpose.
#define EMOJI_RE_PATTERN @"\\[[\u4e00-\u9fa5a-zA-Z]{1,}+\\]"
//The emoji replacement string have to be a fullwidth charecter
//and won't be shrinked when lay out.
//Any CJK charecters is OK.
#define EMOJI_REPLACE_STR @"空"
#define URL_RE_PATTERN @"((http[s]{0,1}|ftp)://[a-zA-Z0-9\\.\\-]+\\.([a-zA-Z]{2,4})(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)|(www.[a-zA-Z0-9\\.\\-]+\\.([a-zA-Z]{2,4})(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)"

#define kRangeLocation @"rangelocation"
#define kImageName @"imagename"
#define kLinkUrl @"linkurl"

@interface CTView()

@property(retain, nonatomic) NSMutableArray *emojiArray;
@property(retain, nonatomic) NSAttributedString *renderedAttributedText;
@property(retain, nonatomic) NSMutableArray *linkArray;

@property (readwrite, nonatomic, assign) CTFramesetterRef framesetter;

@end


static NSDictionary *emojiDict;

/* Callbacks */
static CGFloat ascentCallback( void *ref ){
    return 0.0f;
}
//set descent to center the emoji vertically
static CGFloat descentCallback( void *ref ){
    return -1.5f;
}
static CGFloat imgWidth = 0.0f;
static CGFloat widthCallback( void* ref ){
    return imgWidth;
}

@implementation CTView
- (void)baseInit
{
    self.text = @"";
    self.attributedText = [[[NSAttributedString alloc] initWithString:@""] autorelease];
    self.renderedAttributedText = nil;
    self.font = [UIFont systemFontOfSize:15];
    self.lineBreakMode = NSLineBreakByWordWrapping;
    self.textAlignment = NSTextAlignmentLeft;
    self.backgroundColor = [UIColor clearColor];
    self.textColor = [UIColor blackColor];
    
    self.emojiArray = [[[NSMutableArray alloc] init] autorelease];
    self.linkArray = [[[NSMutableArray alloc] init] autorelease];
    //the emojiname-image dictionary
    emojiDict = [[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"emotion" ofType:@"plist"]];

}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self baseInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(self){
        [self baseInit];
    }
    return self;
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    NSLog(@"drawrect");
    [super drawRect:rect];
    if(_attributedText == nil || _attributedText.length ==0)
        return;
    //set the emoji image width to font's point size
    imgWidth = self.font.pointSize;
    
    CTRunDelegateCallbacks callbacks;
    callbacks.version = kCTRunDelegateCurrentVersion;
    callbacks.getAscent = ascentCallback;
    callbacks.getDescent = descentCallback;
    callbacks.getWidth = widthCallback;
    CTRunDelegateRef delegate = CTRunDelegateCreate(&callbacks, NULL);
    NSDictionary *imageAttributedDictionary = [NSDictionary dictionaryWithObjectsAndKeys:(__bridge id)delegate,(NSString *)kCTRunDelegateAttributeName,(id)[UIColor clearColor].CGColor,kCTForegroundColorAttributeName, nil];
    NSDictionary *linkAttributeDictionary = [NSDictionary dictionaryWithObjectsAndKeys:(id)[UIColor blueColor].CGColor,kCTForegroundColorAttributeName, nil];
    NSAttributedString *faceAttributedString = [[[NSAttributedString alloc] initWithString:EMOTION_REPLACE_STR attributes:imageAttributedDictionary] autorelease];
    
    NSMutableAttributedString *newAttributedStr = [[[NSMutableAttributedString alloc] initWithAttributedString:_attributedText] autorelease];
    
    //set font
    CTFontRef userDefinedFont = CTFontCreateWithName((CFStringRef)self.font.fontName, self.font.pointSize, NULL);
    [newAttributedStr removeAttribute:(NSString *)kCTFontAttributeName range:NSMakeRange(0, newAttributedStr.length)];
    [newAttributedStr addAttribute:(NSString *)kCTFontAttributeName value:(__bridge id)userDefinedFont range:NSMakeRange(0, newAttributedStr.length)];
    CFRelease(userDefinedFont);
    
    //set color
    [newAttributedStr addAttribute:(NSString *)kCTForegroundColorAttributeName value:(__bridge id)self.textColor.CGColor range:NSMakeRange(0, newAttributedStr.length)];
    
    //find emoji
    NSRange range = NSMakeRange(0, newAttributedStr.mutableString.length);
    while(range.length>0)
    {
        range = [newAttributedStr.mutableString rangeOfString:EMOTION_RE_PATTERN options:NSRegularExpressionSearch range:range];
        if(range.location == NSNotFound)
        {
            break;
        }
        else
        {
            NSString *emojiName = [newAttributedStr.mutableString substringWithRange:range];
            if([emojiDict objectForKey:emojiName] != nil)
            {
                [newAttributedStr.mutableString replaceOccurrencesOfString:emojiName withString:EMOTION_REPLACE_STR options:NSLiteralSearch range:range];
                [_emojiArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:range.location],kRangeLocation,[emojiDict objectForKey:emojiName],kImageName,nil]];
                
                range.location += EMOTION_REPLACE_STR.length;
            }
            else
            {
                range.location += emojiName.length;
            }
            range.length = newAttributedStr.mutableString.length - range.location;
        }
    }
    
    //find url link
    range = NSMakeRange(0, newAttributedStr.mutableString.length);
    while(range.length>0)
    {
        range = [newAttributedStr.mutableString rangeOfString:URL_RE_PATTERN options:NSRegularExpressionSearch range:range];
        if(range.location == NSNotFound)
        {
            break;
        }
        else
        {
            NSString *linkUrl = [newAttributedStr.mutableString substringWithRange:range];
            [_linkArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:range.location],kRangeLocation,linkUrl,kLinkUrl,nil]];
            range.location += linkUrl.length;
            range.length = newAttributedStr.mutableString.length - range.location;
        }
    }
    
    for(NSDictionary *dict in _emojiArray)
    {
        [newAttributedStr replaceCharactersInRange:NSMakeRange([[dict objectForKey:kRangeLocation] intValue], EMOTION_REPLACE_STR.length) withAttributedString:faceAttributedString];
    }
    for(NSDictionary *dict in _linkArray)
    {
        [newAttributedStr addAttributes:linkAttributeDictionary range:NSMakeRange([[dict objectForKey:kRangeLocation] intValue], [[dict objectForKey:kLinkUrl] length])];
    }
    

    CGContextRef context = UIGraphicsGetCurrentContext();
    // Flip the coordinate system
    CGContextTranslateCTM(context, 0, self.bounds.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);

    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, self.bounds);

    if(_framesetter == NULL)
    {
        _framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)newAttributedStr);
    }
    CTFrameRef frame = CTFramesetterCreateFrame(_framesetter, CFRangeMake(0, newAttributedStr.length), path, NULL);
    
    CTLineRef line;
    
    int imgIndex = 0;
    int linkIndex = 0;
//    NSLog(@"frame = %@",CTFrameGetLines(frame));
    CTFrameDraw(frame, context);
    self.renderedAttributedText = newAttributedStr;

    for(int i =0;i<CFArrayGetCount(CTFrameGetLines(frame));i++)
    {
        line = CFArrayGetValueAtIndex(CTFrameGetLines(frame), (CFIndex)i);
        CGPoint origins[CFArrayGetCount(CTFrameGetLines(frame))];
        CTFrameGetLineOrigins(frame, CFRangeMake(0, 0), origins);
        for(int j=0; j< CFArrayGetCount(CTLineGetGlyphRuns(line));j++)
        {
            CTRunRef glyphRun = CFArrayGetValueAtIndex(CTLineGetGlyphRuns(line), (CFIndex)j);
            CFRange runRange = CTRunGetStringRange(glyphRun);
            //process emoji
            if([_emojiArray count] != 0 && imgIndex < [_emojiArray count])
            {
                int imgLocation = [[[_emojiArray objectAtIndex:imgIndex] objectForKey:kRangeLocation] intValue];
                NSString *emojiImageName = [[_emojiArray objectAtIndex:imgIndex] objectForKey:kImageName];
                
                while( imgLocation >= runRange.location && imgLocation < runRange.location + runRange.length)
                {
                    CGRect runBounds;
                    CGFloat ascent;
                    CGFloat descent;
                    runBounds.size.width = CTRunGetTypographicBounds(glyphRun, CFRangeMake(0, 0), &ascent, &descent, NULL);
                    runBounds.size.width = imgWidth;
                    runBounds.size.height = imgWidth;
                    CGFloat xOffset = CTLineGetOffsetForStringIndex(line, imgLocation, NULL);
                    runBounds.origin.x = origins[i].x + xOffset;
                    runBounds.origin.y = origins[i].y;
                    runBounds.origin.y += descent;
                    UIImage *img = [UIImage imageNamed:emojiImageName];
                    CGContextDrawImage(context, runBounds, img.CGImage);
                    imgIndex++;
                    if(imgIndex < [_emojiArray count])
                    {
                        imgLocation = [[[_emojiArray objectAtIndex:imgIndex] objectForKey:kRangeLocation] intValue];
                        emojiImageName = [[_emojiArray objectAtIndex:imgIndex] objectForKey:kImageName];
                    }
                    else  //we have drawn all emojis in one line!
                    {
                        imgLocation = -1;
                        break;
                    }
                }
            }
            //process link
            if([_linkArray count] != 0 && linkIndex < [_linkArray count])
            {
                int linkLocation = [[[_linkArray objectAtIndex:linkIndex] objectForKey:kRangeLocation] intValue];
                while(runRange.location <= linkLocation && linkLocation < runRange.location + runRange.length)
                {
                    linkIndex++;
                    if(linkIndex < [_linkArray count])
                    {
                        linkLocation = [[[_linkArray objectAtIndex:linkIndex] objectForKey:kRangeLocation] intValue];
                    }
                    else  //we have drawn all links in one line!
                    {
                        linkLocation = -1;
                        break;
                    }
                }
            }
        }
    }
    
    CFRelease(path);

    CFRelease(frame);
}

- (void)setText:(NSString *)text
{
    if([_text isEqualToString:text])
        return;

    [_text release];
    _text = [text copy];
    
    if(_attributedText != nil)
    {
        [_attributedText release];
    }
    _attributedText = [[NSAttributedString alloc] initWithString:text];
    [self setNeedsDisplay];
}

- (void)setAttributedText:(NSAttributedString *)attributedText
{
    if([_attributedText isEqualToAttributedString:attributedText])
        return;
    
    [_attributedText release];
    _attributedText = [attributedText copy];
    
    if(_text != nil)
    {
        [_text release];
    }
    _text = [_attributedText.string copy];
    [self setNeedsDisplay];
}
//
- (void)setFrame:(CGRect)frame
{
    if(CGRectEqualToRect(frame, self.frame))
        return;
    else
        [super setFrame:frame];
}
- (void)dealloc
{
    [_text release];
    [_attributedText release];
    [_emojiArray release];
    [_linkArray release];
    self.renderedAttributedText = nil;
    if(_framesetter)
    {
        CFRelease(_framesetter);
        _framesetter = NULL;
    }

    [super dealloc];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    CGPoint point = [[touches anyObject] locationInView:self];
    BOOL clickLink = NO;
    //we need to transform the coordination first
    CGPoint transformedPoint = CGPointMake(point.x, self.frame.size.height - point.y);
    if(!self.renderedAttributedText)
    {
        [super touchesEnded:touches withEvent:event];
        return;
    }
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, self.bounds);
    
    CTFrameRef frame = CTFramesetterCreateFrame(_framesetter, CFRangeMake(0, self.renderedAttributedText.length), path, NULL);

    CFArrayRef lines = CTFrameGetLines(frame);
    if(!lines) return;
    
    CGPoint origins[CFArrayGetCount(CTFrameGetLines(frame))];
    CTFrameGetLineOrigins(frame, CFRangeMake(0, 0), origins); //2
    
    for(int i =0;i<CFArrayGetCount(CTFrameGetLines(frame));i++)
    {
        CGPoint linePoint = origins[i];
        if(transformedPoint.y >= linePoint.y && transformedPoint.y <= linePoint.y + self.font.lineHeight)
        {
            CTLineRef line = CFArrayGetValueAtIndex(lines, i);
            
            long pointIndex = CTLineGetStringIndexForPosition(line,transformedPoint);
            
            for(NSDictionary *dict in _linkArray)
            {
                long linkIndex = [[dict objectForKey:kRangeLocation] longValue];
                NSString *linkStr = [dict objectForKey:kLinkUrl];
                
                if(pointIndex > linkIndex && pointIndex <= linkIndex + linkStr.length)
                {
                    //OK, finally we've found the link
                    if([self.delegate respondsToSelector:@selector(CTView:willOpenLinkURL:)])
                    {
                        [self.delegate performSelector:@selector(CTView:willOpenLinkURL:) withObject:self withObject:[NSURL URLWithString:linkStr]];
                        clickLink = YES;
                    }
                    break;
                }
            }
            break;
        }
    }
    //pass the click events through
    if(!clickLink)
    {
        [super touchesEnded:touches withEvent:event];
    }
    CFRelease(frame);
    CFRelease(path);
}

#pragma mark - class methods
+ (CGSize)fitSizeForAttributedString:(NSAttributedString *)attrStr boundingSize:(CGSize)size options:(NSStringDrawingOptions)options context:(NSStringDrawingContext *)context
{
    NSMutableAttributedString *newAttributedStr = [[[NSMutableAttributedString alloc] initWithAttributedString:attrStr] autorelease];
    NSRange range = NSMakeRange(0, newAttributedStr.mutableString.length);
    while(range.length>0)
    {
        range = [newAttributedStr.mutableString rangeOfString:EMOTION_RE_PATTERN options:NSRegularExpressionSearch range:range];
        if(range.location == NSNotFound)
        {
            break;
        }
        else
        {
            NSString *emojiName = [newAttributedStr.mutableString substringWithRange:range];
            if([emojiDict objectForKey:emojiName] != nil)
            {
                [newAttributedStr.mutableString replaceOccurrencesOfString:emojiName withString:EMOTION_REPLACE_STR options:NSLiteralSearch range:range];
                range.location += EMOTION_REPLACE_STR.length;
            }
            else
            {
                range.location += emojiName.length;
            }
            range.length = newAttributedStr.mutableString.length - range.location;
        }
    }
    return [newAttributedStr boundingRectWithSize:size options:options context:context].size;
}

@end
