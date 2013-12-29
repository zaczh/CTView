#import "CTView.h"

//the emoji string style is like "[smile] or [微笑]".
//You may change it for your own purpose.
//#define EMOJI_RE_PATTERN @"\\[[\u4e00-\u9fa5a-zA-Z]{1,}+\\]"
//The emoji replacement string have to be a fullwidth charecter
//and won't be shrinked when been laid out.
//Any CJK charecters is OK.
//#define EMOJI_REPLACE_STR @"\ufffc"


#define kRangeLocation @"rangelocation"
#define kImageName @"imagename"
#define kLinkUrl @"linkurl"

@interface CTView()
@property (strong, nonatomic) NSMutableArray *emojiArray;
@property (strong, nonatomic) NSAttributedString *renderedAttributedText;
@property (strong, nonatomic) NSMutableArray *linkArray;
@property (strong, nonatomic) NSDictionary *emojiDict;
@property (readwrite, nonatomic, assign) CTFramesetterRef framesetter;
@end

@implementation CTView

- (void)baseInit
{
    _text = @"";
    _attributedText = [[NSAttributedString alloc] initWithString:@""];
    _renderedAttributedText = nil;
    self.font = [UIFont systemFontOfSize:15];
    self.lineBreakMode = NSLineBreakByWordWrapping;
    self.textAlignment = NSTextAlignmentLeft;
    self.backgroundColor = [UIColor clearColor];
    self.textColor = [UIColor blackColor];
    
    self.emojiArray = [[[NSMutableArray alloc] init] autorelease];
    self.linkArray = [[[NSMutableArray alloc] init] autorelease];
    //the emojiname-image dictionary
    self.emojiDict = [[[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"emotion" ofType:@"plist"]] autorelease];
    
    //we want this view redraw itself when its frame changes
//    self.contentMode = UIViewContentModeRedraw;
    
//    self.autoresizesSubviews = NO;
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



/* Callbacks */
//static CGFloat ascentCallback( void *ref ){
////    return 0.0f;
//    return [[(__bridge NSDictionary *)ref objectForKey:@"ascent"] floatValue];
//}
//static CGFloat descentCallback( void *ref ){
////    return -3.5f;
//    return [[(__bridge NSDictionary *)ref objectForKey:@"descent"] floatValue];
//}
//static CGFloat imgWidth = 0.0f;
//static CGFloat widthCallback( void* ref ){
//    return [[(__bridge NSDictionary *)ref objectForKey:@"width"] floatValue];
////    return imgWidth;
//}
//static void deallocCallback( void* ref ){
//    [(id)ref release];
//}

- (NSAttributedString *)preprocessedString
{
    CTFontRef userDefinedFont = CTFontCreateWithName((CFStringRef)self.font.fontName, self.font.pointSize, NULL);
//
//    
//    
//

    
    
//    CTRunDelegateCallbacks callbacks;
//    callbacks.version = kCTRunDelegateCurrentVersion;
//    callbacks.getAscent = ascentCallback;
//    callbacks.getDescent = descentCallback;
//    callbacks.getWidth = widthCallback;
//    callbacks.dealloc = deallocCallback;
//    NSDictionary *imageAttrDict = [[NSDictionary dictionaryWithObjectsAndKeys:
//                                    [NSNumber numberWithFloat:CTFontGetAscent(userDefinedFont)],@"ascent",
//                                    [NSNumber numberWithFloat:CTFontGetDescent(userDefinedFont)],@"descent",
//                                    [NSNumber numberWithFloat:CTFontGetSize(userDefinedFont)],@"width",nil] strong];
//    CTRunDelegateRef delegate = CTRunDelegateCreate(&callbacks, imageAttrDict);
    NSDictionary *imageAttributedDictionary = [NSDictionary dictionaryWithObjectsAndKeys:(NSString *)(__bridge id)userDefinedFont,kCTFontAttributeName,(id)[UIColor clearColor].CGColor,kCTForegroundColorAttributeName, nil];
//    CFRelease(delegate);
    NSDictionary *linkAttributeDictionary = [NSDictionary dictionaryWithObjectsAndKeys:(id)[UIColor blueColor].CGColor,kCTForegroundColorAttributeName, nil];
    NSAttributedString *faceAttributedString = [[[NSAttributedString alloc] initWithString:EMOTION_REPLACE_STR attributes:imageAttributedDictionary] autorelease];
    
    NSMutableAttributedString *newAttributedStr = [[[NSMutableAttributedString alloc] initWithAttributedString:_attributedText] autorelease];
    
    //set font
    [newAttributedStr removeAttribute:NSFontAttributeName range:NSMakeRange(0, newAttributedStr.length)];
    [newAttributedStr addAttribute:(NSString *)kCTFontAttributeName value:(__bridge id)userDefinedFont range:NSMakeRange(0, newAttributedStr.length)];
    CFRelease(userDefinedFont);
    
    //set color
    [newAttributedStr addAttribute:(NSString *)kCTForegroundColorAttributeName value:(__bridge id)self.textColor.CGColor range:NSMakeRange(0, newAttributedStr.length)];
    
    
    
    //find emoji
    [_emojiArray removeAllObjects];
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
            if([self.emojiDict objectForKey:emojiName] != nil)
            {
                [newAttributedStr.mutableString replaceOccurrencesOfString:emojiName withString:EMOTION_REPLACE_STR options:NSLiteralSearch range:range];
                [_emojiArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:range.location],kRangeLocation,[self.emojiDict objectForKey:emojiName],kImageName,nil]];
                
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
    [_linkArray removeAllObjects];
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
    return newAttributedStr;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];

    
//    imgWidth = self.font.pointSize;
    if(_attributedText == nil || _attributedText.length ==0)
        return;
//    if(!CGRectIntersectsRect(rect, self.bounds))
//        return;
    

    

    CGContextRef context = UIGraphicsGetCurrentContext();
    // Flip the coordinate system
    CGContextTranslateCTM(context, 0, self.bounds.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);

    
    CGMutablePathRef path = CGPathCreateMutable();
//    self.bounds = CGRectMake(0, 0, 250,100);
    CGPathAddRect(path, NULL, self.bounds);
//    NSLog(@"bounds:(%f %f %f %f)",self.bounds.origin.x,self.bounds.origin.y, self.bounds.size.width,self.bounds.size.height);
//    NSLog(@"path = %@",path);
    
//    NSAttributedString *str = [[NSAttributedString alloc] initWithString:@"dagagaga"];
//    newAttributedStr = str;
    
    NSAttributedString *newAttributedStr = [self preprocessedString];
    
    if(_framesetter == NULL)
    {
        _framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)newAttributedStr);
    }
    CTFrameRef frame = CTFramesetterCreateFrame(_framesetter, CFRangeMake(0, newAttributedStr.length), path, NULL);
    if(frame)
    {
        CTLineRef line;
        
        int imgIndex = 0;
        int linkIndex = 0;
    //    NSLog(@"frame = %@",CTFrameGetLines(frame));
        CTFrameDraw(frame, context);
        self.renderedAttributedText = newAttributedStr;
        
        CGPoint origins[CFArrayGetCount(CTFrameGetLines(frame))];
        CTFrameGetLineOrigins(frame, CFRangeMake(0, 0), origins);
        for(int i =0;i<CFArrayGetCount(CTFrameGetLines(frame));i++)
        {
            line = CFArrayGetValueAtIndex(CTFrameGetLines(frame), (CFIndex)i);
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
                        CGFloat leading;
                        runBounds.size.width = CTRunGetTypographicBounds(glyphRun, CFRangeMake(0, 1), &ascent, &descent, &leading);
//                        runBounds.size.width = imgWidth;
                        runBounds.size.height = ascent + descent;
                        CGFloat xOffset = CTLineGetOffsetForStringIndex(line, imgLocation, NULL);
                        runBounds.origin.x = origins[i].x + xOffset;
                        runBounds.origin.y = origins[i].y;
                        //NOTE:the runBounds coordination isn't the same to frame's. It's flipped.
                        runBounds.origin.y -= descent;
                        UIImage *img = [UIImage imageNamed:emojiImageName];
                        CGContextDrawImage(context, runBounds, img.CGImage);
    //                    NSLog(@"runBounds:%f%f",runBounds.origin.x,runBounds.origin.y);
                        imgIndex++;
                        if(imgIndex < [_emojiArray count])
                        {
                            imgLocation = [[[_emojiArray objectAtIndex:imgIndex] objectForKey:kRangeLocation] intValue];
                            emojiImageName = [[_emojiArray objectAtIndex:imgIndex] objectForKey:kImageName];
                        }
                        else  //we have drawn all emojies in one line!
                        {
//                            imgLocation = -1;
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
//                            linkLocation = -1;
                            break;
                        }
                    }
                }
    //            CFRelease(glyphRun);
            }
        }
    }
    CFRelease(path);

    if(frame)
    {
        CFRelease(frame);
    }
}

- (void)setText:(NSString *)text
{

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
}

- (void)setAttributedText:(NSAttributedString *)attributedText
{

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
//        self.backgroundColor = [UIColor clearColor];
    }
}
//
- (void)setFrame:(CGRect)frame
{
    if(CGRectEqualToRect(frame, self.frame))
        return;
    else
        [super setFrame:frame];
}

- (CGSize)intrinsicContentSize
{
    if(!self.text)
    {
        return CGSizeZero;
    }
    else
    {
        NSMutableAttributedString *muteAttrStr = [[[NSMutableAttributedString alloc] initWithString:self.text] autorelease];
        [muteAttrStr addAttribute:NSFontAttributeName value:self.font range:NSMakeRange(0, muteAttrStr.length)];
        return [muteAttrStr boundingRectWithSize:CGSizeMake(self.frame.size.width, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading context:nil].size;
    }
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

- (void)reset
{
    self.text = @"";
    self.attributedText = [[[NSAttributedString alloc] initWithString:self.text] autorelease];
    [self setNeedsDisplay];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    CGPoint point = [[touches anyObject] locationInView:self];
    BOOL clickLink = NO;
    //we need to transform the coordination first
    CGPoint transformedPoint = CGPointMake(point.x, self.frame.size.height - point.y);
    NSLog(@"transformedPoint = %f,%f",transformedPoint.x,transformedPoint.y);
    if(!self.renderedAttributedText)
    {
        [super touchesEnded:touches withEvent:event];
        return;
    }
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, self.bounds);
    
    CTFrameRef frame = CTFramesetterCreateFrame(_framesetter, CFRangeMake(0, 0), path, NULL);

    CFArrayRef lines = CTFrameGetLines(frame);
    if(lines)
    {
        CGPoint origins[CFArrayGetCount(CTFrameGetLines(frame))];
        CTFrameGetLineOrigins(frame, CFRangeMake(0, 0), origins); //2
        
        for(int i =0;i<CFArrayGetCount(CTFrameGetLines(frame));i++)
        {
            CGPoint linePoint = origins[i];
            if(transformedPoint.y >= linePoint.y && transformedPoint.y <= linePoint.y + self.font.lineHeight)
            {
                CTLineRef line = CFArrayGetValueAtIndex(lines, i);
                
    //            long pointIndex = CTLineGetStringIndexForPosition(line,transformedPoint);
                for(NSDictionary *dict in _linkArray)
                {
                    long linkIndex = [[dict objectForKey:kRangeLocation] longValue];
                    NSString *linkStr = [dict objectForKey:kLinkUrl];
                    NSLog(@"CTLineGetOffsetForStringIndex: %f,%f", CTLineGetOffsetForStringIndex(line,linkIndex,NULL), CTLineGetOffsetForStringIndex(line,linkIndex + linkStr.length,NULL));

    //                if(pointIndex >= linkIndex && pointIndex <= linkIndex + linkStr.length)
                    if(transformedPoint.x <= CTLineGetOffsetForStringIndex(line,linkIndex + linkStr.length,NULL) &&
                       transformedPoint.x >= CTLineGetOffsetForStringIndex(line,linkIndex,NULL))
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
    NSDictionary *emojiDict = [[[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"emotion" ofType:@"plist"]] autorelease];
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
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)newAttributedStr);
//    CGMutablePathRef path = CGPathCreateMutable();
//    CGPathAddRect(path, NULL, CGRectMake(0, 0, size.width, size.height));
//    CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, NULL);
    CGSize fitSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, [newAttributedStr length]), NULL, CGSizeMake(size.width, CGFLOAT_MAX), NULL);
//    CGSize messuredSize = [self measureFrame:frame forContext:nil];
//    CFRelease(frame);
//    CFRelease(path);
    CFRelease(framesetter);

//    NSLog(@"fitsize:(%f,%f),measured size:(%f,%f)",fitSize.width,fitSize.height,messuredSize.width,messuredSize.height);
    return fitSize;
}

//From http://lists.apple.com/archives/quartz-dev/2008/Mar/msg00079.html
+ (CGSize) measureFrame: (CTFrameRef) frame forContext: (CGContextRef *) cgContext
{
    CGPathRef framePath = CTFrameGetPath(frame);
    CGRect frameRect = CGPathGetBoundingBox(framePath);
    
    CFArrayRef lines = CTFrameGetLines(frame);
    CFIndex numLines = CFArrayGetCount(lines);
    
    CGFloat maxWidth = 0;
    CGFloat textHeight = 0;
    
    // Now run through each line determining the maximum width of all the lines.
    // We special case the last line of text. While we've got it's descent handy,
    // we'll use it to calculate the typographic height of the text as well.
    CFIndex lastLineIndex = numLines - 1;
    for(CFIndex index = 0; index < numLines; index++)
    {
        CGFloat ascent, descent, leading, width;
        CTLineRef line = (CTLineRef) CFArrayGetValueAtIndex(lines, index);
        width = CTLineGetTypographicBounds(line, &ascent,  &descent, &leading);
        
        if(width > maxWidth)
        {
            maxWidth = width;
        }
        
        if(index == lastLineIndex)
        {
            // Get the origin of the last line. We add the descent to this
            // (below) to get the bottom edge of the last line of text.
            CGPoint lastLineOrigin;
            CTFrameGetLineOrigins(frame, CFRangeMake(lastLineIndex, 1), &lastLineOrigin);
            
            // The height needed to draw the text is from the bottom of the last line
            // to the top of the frame.
            textHeight =  CGRectGetMaxY(frameRect) - lastLineOrigin.y + descent;
        }
    }
    
    // For some text the exact typographic bounds is a fraction of a point too
    // small to fit the text when it is put into a context. We go ahead and round
    // the returned drawing area up to the nearest point.  This takes care of the
    // discrepencies.
    return CGSizeMake(ceil(maxWidth), ceil(textHeight));
}

@end
