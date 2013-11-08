//
//  ViewController.m
//  IOSExpandEffect
//
//  Created by 이제민 on 13. 10. 28..
//  Copyright (c) 2013년 이제민. All rights reserved.
//

#import "ViewController.h"

@interface ViewController (Private)

// 캡처이미지를 자른다
- (void)captureImageCropping:(CGRect)selectedRect;
// 폴더뷰
- (void)layoutFolderView:(CGRect)selectedRect;
// 폴더뷰 하단(스샷이 들어감)
- (void)layoutElseView;

@end

@implementation ViewController (Private)


// 1 단계: 스샷을 불러와 마스크만큼 자른다
- (void)captureImageCropping:(CGRect)selectedRect
{
    // 저장된 스샷 불러옴
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePath = [NSString stringWithFormat:@"%@/themeScreenShot.png",documentsDirectory];
    NSData *pngData = [NSData dataWithContentsOfFile:filePath];
    
    // 저장된 이미지
    UIImage *img = [UIImage imageWithData:pngData];
    
    // 자를 부분
    CGRect maskRect = CGRectMake(0, 0, 320, self.view.frame.size.height - OM_STARTY);
    // 자를 부분의 y축은 선택한 부분의 y축 + 높이 + 20;
    maskRect.origin.y = selectedRect.origin.y + selectedRect.size.height + 20;
    
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)])
    {
        if ([[UIScreen mainScreen] scale] == 2.0)
        {
            maskRect = CGRectMake(0, 0, 640, 920);
            maskRect.origin.y = 2*(selectedRect.origin.y + selectedRect.size.height + 20 );
        }
        
    }
    
    // 마스크만큼 자르긔
    CGImageRef imageRef = CGImageCreateWithImageInRect([img CGImage], maskRect);
    
    UIImage *modiImg = [UIImage imageWithCGImage:imageRef scale:[self isRetinaDisplay] ? 2.0f : 1.0f orientation:UIImageOrientationUp];
    
    CGImageRelease(imageRef);
    
    NSData *imageData = UIImagePNGRepresentation(modiImg);
    
    NSString *path0 = [NSString stringWithFormat:@"%@/mask.png",documentsDirectory];
    [imageData writeToFile:path0 atomically:YES];
    
    [_elseViewBg setImage:modiImg];
    
}

// 폴더뷰
- (void)layoutFolderView:(CGRect)selectedRect
{
    // 폴더 뷰
	CGRect folderViewFrame = [_folderView frame];
    
    // 폴더뷰의 y축 = 선택한 부분의 y축 + 높이 + 20 + @
    folderViewFrame.origin.y = selectedRect.origin.y + selectedRect.size.height + 20 + OM_STARTY;
    folderViewFrame.size.height = (ceil)(themeDetailCount / 2) * 39;
    [_folderView setFrame:folderViewFrame];
    
	// 폴더 뷰 배경
    CGRect folderViewImg = [_folderBg frame];
    
    
    folderViewImg.size.height = folderViewFrame.size.height;
    
    [_folderBg setFrame:folderViewImg];
    
    NSLog(@"폴더뷰 %@", NSStringFromCGRect(folderViewImg));
    
    // 폴더 뷰 쉐도우
    [_shadowBottomBg setFrame:CGRectMake(0, folderViewFrame.size.height - _shadowBottomBg.frame.size.height, 320, 15)];
}

// 폴더뷰 아래 스샷이미지 부분
- (void)layoutElseView
{
	CGRect maskFrame = _elseView.frame;
    // 하단뷰의 y축 = 폴더뷰의 y + height
	maskFrame.origin.y = _folderView.frame.origin.y + _folderView.frame.size.height;
	_elseView.frame = maskFrame;
    
    // 하단뷰의 이미지
    CGRect maskFrameBg = _elseViewBg.frame;
    
    maskFrameBg.origin.y = 0;
    
    NSLog(@"하단뷰 : %@", NSStringFromCGRect(maskFrame));
    NSLog(@"하단뷰 배경 : %@", NSStringFromCGRect(maskFrameBg));

    [_elseViewBg setFrame:maskFrameBg];
    [_elseViewBg setAlpha:0.5];
    
}
- (BOOL) isRetinaDisplay
{
    UIScreen *ms = [UIScreen mainScreen];
    
    if ( [ms respondsToSelector:@selector(displayLinkWithTarget:selector:)]
        && [ms scale] == 1.0f )
    {
        return NO;
    }
    else
    {
        return YES;
    }
    
}
@end


@interface ViewController ()

@end

@implementation ViewController

double convertHexToDecimal (NSString *hex)
{
    NSScanner *scanner=[NSScanner scannerWithString:hex];
    unsigned int decimal;
    [scanner scanHexInt:&decimal];
    return decimal / 255.0f;
}
UIColor* convertHexToDecimalRGBA (NSString *r, NSString *g, NSString *b, float a)
{
    return [UIColor colorWithRed:convertHexToDecimal(r) green:convertHexToDecimal(g) blue:convertHexToDecimal(b) alpha:a];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    // jsonfile.json 을 가져옴
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"jsonfile" ofType:@"json"];
    
    NSString *jsonString = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    
    
    NSError *error = nil;
    
    // array에 set
    themeInfoList = [NSJSONSerialization JSONObjectWithData:jsonData                                                                                         options:kNilOptions    error:&error];
    
    NSLog(@"themeInfoList : %@", themeInfoList);
    
    themeCount = [themeInfoList count];
    
    [self initer];
    [self drawTheme];
}
- (void) initer
{
    // 폴더뷰 안에 뷰
    _folderinView = [[UIView alloc] init];
    
    // 버튼좌표 딕셔너리
    _btnCrdDictionary = [[NSMutableDictionary alloc] init];
    
    // 블러링뷰 어레이
    _blurArr = [[NSMutableArray alloc] init];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void) drawTheme
{
    
    // 테마 열갯수
    int themeRow = ceil(themeCount / 4);
    // 테마 행갯수
    int themeCols;
    // 카운터
    int forCount = 0;
    
    int viewY = 0;
    int viewHeight = 98;
    
    // 테마갯수가 4보다 작으면 열은 1개 행은 테마갯수
    if(themeCount < 4)
    {
        themeRow = 1;
        themeCols = themeCount;
    }
    // 아니면 무조건 행은 4개
    else
    {
        themeCols = 4;
    }
    
    
    // 세로 그리기
    for (int i = 0; i<themeRow; i++)
    {
        
        int themeX = 6;
        int themeWidth = 77;
        
        UIView *rowView = [[UIView alloc] init];
        [rowView setFrame:CGRectMake(0, viewY, 320, viewHeight)];
        [_scrollView addSubview:rowView];
        
        // 가로 그리기
        for (int j = 0; j<themeCols; j++)
        {
            
            //NSDictionary *themeInfo = [ThemeCommon themeInfoByIndex:forCount];
            
            // 각 뷰
            UIView *itemView = [[UIView alloc] init];
            [itemView setFrame:CGRectMake(themeX, 0, themeWidth, 98)];
            [rowView addSubview:itemView];
            
            // 아이템뷰 기준에서 rect의 좌표를 스크롤뷰에서의 절대좌표로 변환
            CGRect rct = [itemView convertRect:CGRectMake(5, 8, 67, 67) toView:_scrollView];
            
            // 버튼
            UIButton *itemBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            [itemBtn setFrame:rct];
            [itemBtn setTag:forCount];
            [itemBtn setExclusiveTouch:YES];
            [itemBtn addTarget:self action:@selector(themeClick:) forControlEvents:UIControlEventTouchUpInside];
            [_scrollView insertSubview:itemBtn atIndex:100];
            
            // 배열에 버튼의 rect를 저장
            NSValue *rectObj = [NSValue valueWithCGRect:rct];
            NSString *cnt = [NSString stringWithFormat:@"%d", forCount];
            NSArray *arr = [NSArray arrayWithObjects:rectObj, nil];
            
            [_btnCrdDictionary setObject:arr forKey:cnt];
            
            // 버튼배경
            UIImageView *itemBg = [[UIImageView alloc] init];
            
            [itemBg setImage:[UIImage imageNamed:@"tester.png"]];
            
            [itemBg setFrame:CGRectMake(5, 8, 67, 67)];
            [itemView addSubview:itemBg];
            
            // 라벨
            UILabel *itemLbl = [[UILabel alloc] init];
            [itemLbl setBackgroundColor:[UIColor clearColor]];
            [itemLbl setFrame:CGRectMake(0, 8+67+6-1, 77, 11+2)];
            [itemLbl setText:[NSString stringWithFormat:@"%d번째", j + (4 * i)]];
            [itemLbl setFont:[UIFont boldSystemFontOfSize:11]];
            [itemLbl setTextAlignment:NSTextAlignmentCenter];
            [itemLbl setAdjustsFontSizeToFitWidth:YES];
            [itemView addSubview:itemLbl];
            
            themeX += themeWidth;
            
            forCount++;
            
        }
        // 한 행을 다 그리고 몇개가 남았는지 확인.. 4개보다 많으면 다음 열도 4개
        if(themeCount-forCount > 4)
        {
            themeCols = 4;
        }
        else
        {
            themeCols = themeCount - forCount;
        }
        
        
        viewY += viewHeight;
    }
    
    [self blurArrMaker];
    
    themeViewHeight = viewY;
    
    [_scrollView setContentSize:CGSizeMake(320, themeViewHeight)];
    
    [self themeSnapShot];
    
}
- (void) blurArrMaker
{
    // New마크 그리기
    
    int new_x = 0;
    int new_y = 0;
    
    for (int i=0; i<themeCount; i++)
    {
        // 블러링뷰 만들고 어레이에 ADD
        UIControl *blurView = [[UIControl alloc] init];
        [blurView setBackgroundColor:convertHexToDecimalRGBA(@"f2", @"f2", @"f2", 0.75)];
        [blurView setAlpha:0.75];
        [blurView setOpaque:YES];
        [blurView addTarget:self action:@selector(elseViewTab:) forControlEvents:UIControlEventTouchUpInside];
        [blurView setFrame:CGRectMake(6+new_x, 6+new_y, 67+10, 67+30)];
        
        [_blurArr addObject:blurView];
        
        new_x += 77;
        
        if(new_x >= 320-12)
        {
            new_x = 0;
        }
        
        if((i - 3) % 4 == 0)
        {
            new_y += 98;
        }
        
    }
    
}

- (void) themeSnapShot
{
    // 들어오면 일단 캡쳐한다
    CGFloat scale = 1.0;
    if([[UIScreen mainScreen]respondsToSelector:@selector(scale)])
    {
        CGFloat tmp = [[UIScreen mainScreen]scale];
        if (tmp > 1.5) {
            scale = 2.0;
        }
    }
    
    // 레티나인지 걍인지?
    scale > 1.5 ? UIGraphicsBeginImageContextWithOptions(_scrollView.contentSize, NO, scale) : UIGraphicsBeginImageContext(_scrollView.contentSize);
    
	// 메인 백그라운드 뷰 갭춰.
	[_scrollView.layer renderInContext:UIGraphicsGetCurrentContext()];
	UIImage *backgroundImage = UIGraphicsGetImageFromCurrentImageContext();
    
    NSData *imageData = UIImagePNGRepresentation(backgroundImage);
    //UIGraphicsEndImageContext();
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSString *path0 = [NSString stringWithFormat:@"%@/themeScreenShot.png",documentsDirectory];
    [imageData writeToFile:path0 atomically:YES];
    
    //
    [self drawScrollView];
    
}
- (void) drawScrollView
{
    [_scrollView setContentSize:CGSizeMake(320, themeViewHeight)];
    [_scrollView setFrame:CGRectMake(0, OM_STARTY, 320, self.view.frame.size.height - OM_STARTY)];
    [_scrollView setBackgroundColor:convertHexToDecimalRGBA(@"f2", @"f2", @"f2", 1)];
    
}
- (NSDictionary *) themeInfoByIndex :(int)indexer
{
   return [themeInfoList objectAtIndex:indexer];
}
- (void) themeClick:(id)sender
{
    // 태그값으로 무슨 버튼인지 판단
    index = ((UIButton *)sender).tag;
    
    NSDictionary *themeInfo = [self themeInfoByIndex:index];
    // 선택한 테마의 상세테마 수
    
    themeDetailCount = [[themeInfo objectForKey:@"sub"] count];
    
    // 선택한 테마의 좌표값
    CGRect rect = [[[_btnCrdDictionary objectForKey:[NSString stringWithFormat:@"%d", index]] objectAtIndex:0] CGRectValue];
    
    // 상세테마가 없으면 확장없이 바로 ㄲㄱ
    if(themeDetailCount == 0)
    {
        [self subThemeClick:sender];
        
        return;
    }
    // 만약 상세테마뷰가 열려있다면 닫아야지
    if(_folderView.hidden == NO)
    {
        [self elseViewTab:nil];
        return;
    }
    
    // 탭한 폴더의 센터
    CGRect selectedRect = rect;
    
    // 기존 부분을 따로 저장해놓음
    prevRect = selectedRect;
    
    NSLog(@"선택한 버튼 : %@", NSStringFromCGRect(selectedRect));
    
    if (_folderView.hidden) // 만약 폴더가 열려 있지 않으면...
    {
        // 서브테마 그리기
        [self drawSubTheme];
        
        // 저장된 스크린샷을 마스크로 짤라서 하단뷰에 붙임
        [self captureImageCropping:selectedRect];
        // 폴더뷰를 그림
        [self layoutFolderView:selectedRect];
        
        [UIView beginAnimations:@"FolderOpen" context:NULL];
        [UIView setAnimationDuration:0.5];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
        
        _folderView.hidden = NO;
        _elseView.hidden = NO;
        
        // 폴더 열기 애니메이션.
        // 3 단계: 메인 뷰의 나머지 스크린샷 찍힌부분
        [self layoutElseView];
        
        [UIView commitAnimations];
        
        // 블러링뷰를 add한다
        [self blurringViewAddToScrollview:index];
        
        // 나중에 넘어가게되면....
        CGRect folderRect = [_folderView frame];
        
        int viewMax = folderRect.origin.y + folderRect.size.height;
        
        int limitMax = self.view.frame.size.height;
        if(viewMax > limitMax)
        {
            int minus = viewMax - limitMax;
            
            [_scrollView setContentOffset:CGPointMake(0, minus)];
            
            folderRect.origin.y -= minus;
            
            [_folderView setFrame:folderRect];
        }
        
    }
    
}
-(void) drawSubTheme
{
    int themerow = ceil(themeDetailCount / 2);
    
    int counter = 0;
    int detailY = 0;
    int tagCount = 1000;
    
    // 서브테마 세로
    for (int i = 0; i<themerow; i++)
    {
        
        int detailX = 15;
        int detailBtnX = 0;
        int roof = 2;
        
        if(themeDetailCount - counter < 2)
        {
            roof = 1;
        }
        
        // 서브테마 가로
        UIView *detailView = [[UIView alloc] init];
        [detailView setFrame:CGRectMake(0, detailY, 320, 39)];
        [detailView setBackgroundColor:[UIColor clearColor]];
        
        for (int j = 0; j < roof; j++)
        {
            
            // 서브테마 버튼
            UIButton *detailBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            [detailBtn setFrame:CGRectMake(detailBtnX, 0, 160, 39)];
            //if(j % 2 == 0)
            //[detailBtn setBackgroundColor:[UIColor redColor]];
            [detailBtn setImage:[UIImage imageNamed:@"theme_list_01_pressed.png"] forState:UIControlStateHighlighted];
            [detailBtn setTag:tagCount];
            [detailBtn setExclusiveTouch:YES];
            [detailBtn addTarget:self action:@selector(subThemeClick:) forControlEvents:UIControlEventTouchUpInside];
            [detailView addSubview:detailBtn];
            
            // 서브테마 라벨
            
            NSString *str = [NSString stringWithFormat:@"%@", [[[[themeInfoList objectAtIndex:index] objectForKey:@"sub"] objectAtIndex:counter] objectForKey:@"name"]];
            
            UILabel *detailLbl = [[UILabel alloc] init];
            [detailLbl setBackgroundColor:[UIColor clearColor]];
            [detailLbl setFrame:CGRectMake(detailX, 10, 129, 15)];
            [detailLbl setFont:[UIFont systemFontOfSize:15]];
            [detailLbl setTextColor:[UIColor whiteColor]];
            [detailLbl setText:str];
            [detailView addSubview:detailLbl];
            
            
            counter++;
            detailX += 160;
            detailBtnX += 160;
            tagCount++;
            
        }
        
        [_folderinView addSubview:detailView];
        
        
        detailY += 39;
        
        // 밑줄
        UIImageView *underLine = [[UIImageView alloc] init];
        [underLine setFrame:CGRectMake(0, detailY - 1, 320, 1)];
        [underLine setBackgroundColor:[UIColor redColor]];
        [_folderinView addSubview:underLine];
        
        
        [_folderinView setFrame:CGRectMake(0, 0, 320, themerow * 39)];
        [_folderView addSubview:_folderinView];
    }
    
}
-(void) subThemeClick:(id)sender
{
    int tagIndex = ((UIButton *)sender).tag;
    
    tagIndex -= 1000;
    
    NSString *themeCode;
    if(themeDetailCount == 0)
    {
        themeCode = themeInfoList [index] [@"code"];
    }
    else
    {
        themeCode = themeInfoList [index] [@"sub"] [tagIndex] [@"code"];
        
    }
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"클릭" message:[NSString stringWithFormat:@"%@", themeCode] delegate:nil cancelButtonTitle:@"취소" otherButtonTitles:@"확인", nil];
    [alert show];
    
}
- (void) closingExpand:(CGRect)rect
{
    CGRect elseFrame = CGRectMake(0, OM_STARTY + rect.origin.y+rect.size.height + 20, 320,
                                  self.view.frame.size.height - OM_STARTY);
    [_folderView setFrame:elseFrame];
    [_elseView setFrame:elseFrame];
    
}
- (void)blurringViewAddToScrollview:(int)indexing
{
    int cnt = 0;
    
    // 넘겨받은 인덱스값을 제외하고 나머지를 블러처리된 뷰로 add
    for (UIControl __strong *view in _blurArr)
    {
        if(cnt != indexing)
        {
            view = [_blurArr objectAtIndex:cnt];
            
            [_scrollView addSubview:view];
        }
        
        cnt++;
    }
    
    NSLog(@"블러링 배열 : %@", _blurArr);
    
}
- (void) blurringViewRemoveToScrollview:(int)indexing
{
    NSLog(@"블러링 배열 : %@", _blurArr);
    
    int cnt = 0;
    for (UIView __strong *view in _blurArr)
    {
        if(cnt != indexing)
        {
            view = [_blurArr objectAtIndex:cnt];
            
            [view removeFromSuperview];
        }
        cnt++;
    }
}
// 애니메이션
- (void)myAnimation:(NSString*)animation didFinish:(BOOL)finish context:(void *)context
{
    if ([animation isEqualToString:@"FolderClose"])
    {
        _folderView.hidden = YES;
        _elseView.hidden = YES;
        // 알파값 원상 복귀.
        _scrollView.alpha = 1;
        
        // 폴더인뷰의 add 객체 제거
        for (UIControl *addingView in _folderinView.subviews)
        {
            [addingView removeFromSuperview];
        }
        // 블러링뷰 제거
        [self blurringViewRemoveToScrollview:index];
        
        [_scrollView setContentOffset:CGPointMake(0, 0) animated:YES];
        
    }
}

// 확장영역 하단 탭
-(IBAction) elseViewTab:(id)sender
{
    // 폴더 닫기 애니메이션.
    [UIView beginAnimations:@"FolderClose" context:NULL];
    [UIView setAnimationDuration:0.5];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationDidStopSelector:@selector(myAnimation:didFinish:context:)];
    [UIView setAnimationDelegate:self];
    
    // 이전 좌표값으로 되돌림
    [self closingExpand:prevRect];
    [UIView commitAnimations];
    
}

@end
