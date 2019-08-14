//
//  ZXChatBoxFaceView.m
//  ZXDNLLTest
//
//  Created by mxsm on 16/5/19.
//  Copyright © 2016年 mxsm. All rights reserved.
//

#import "ZXChatBoxFaceView.h"
#import "ZXChatFaceMenuView.h"
#import "ZXChatFaceItemView.h"
#import "ChatFaceHelper.h"
#import <XOBaseLib/XOBaseLib.h>

#define     HEIGHT_BOTTOM_VIEW          36.0f

@interface ZXChatBoxFaceView()<UIScrollViewDelegate,ZXChatBoxFaceMenuViewDelegate, ZXChatFaceItemViewDelegate>

@property (nonatomic, strong) ChatFaceGroup *curGroup;
@property (nonatomic, assign) int curPage;
@property (nonatomic, strong) UIView *topLine;
@property (nonatomic, strong) UIPageControl *pageControl;
@property (nonatomic, strong) ZXChatFaceMenuView *faceMenuView;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) NSMutableArray *facePageViewArray;

@end

@implementation ZXChatBoxFaceView

- (id) initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        
        [self setBackgroundColor:DEFAULT_CHATBOX_COLOR];
        [self addSubview:self.topLine];
        [self addSubview:self.faceMenuView];
        [self addSubview:self.scrollView];
        [self addSubview:self.pageControl];
    }
    return self;
}

/**
 *  添加scrollView 添加 pageController
 */

-(void) setFrame:(CGRect)frame
{
    [super setFrame:frame];
    [self.scrollView  setFrame:CGRectMake(0, 0, frame.size.width, frame.size.height - HEIGHT_BOTTOM_VIEW - 18)];
    [self.pageControl setFrame:CGRectMake(0, self.scrollView.height + 3, frame.size.width, 8)];
    /**
     *  开始就添加三张？
     */
    for (ZXChatFaceItemView *pageView in self.facePageViewArray) {
        
        [self.scrollView addSubview:pageView];
    }
}

#pragma mark - TLChatBoxFaceMenuViewDelegate 三个代理方法
- (void) chatBoxFaceMenuView:(ZXChatFaceMenuView *)chatBoxFaceMenuView didSelectedFaceMenuIndex:(NSInteger)index
{
    /**
     *   这个index 就是菜单栏中的表情组的 index ，其实这里是想通过选中的 表情组的index来更新 ScrollView
     */
    ChatFaceGroup *lastGroup = _curGroup;
    _curGroup = [[[ChatFaceHelper sharedFaceHelper] faceGroupArray] objectAtIndex:index];
    // 如果点击的是正在显示的则不刷新
    if ([lastGroup.groupID isEqualToString:_curGroup.groupID]) return;
    
    if (_curGroup.facesArray == nil) {
        /**
         *   这个groupID 就是该组特有的 ID 例如，系统表情就是 0 自己添加的一组就是 1 等等
         */
        [[ChatFaceHelper sharedFaceHelper] getFaceArrayByGroupID:_curGroup.groupID complection:^(NSArray<ChatFace *> *chatFaceArray) {
            self->_curGroup.facesArray = chatFaceArray;
            [self reloadScrollView];
        }];
    } else {
        [self reloadScrollView];
    }
}


/**
 *  菜单发送按钮
 */
- (void) chatBoxFaceMenuViewSendButtonDown
{
    if (_delegate && [_delegate respondsToSelector:@selector(chatBoxFaceViewDeleteButtonDown)]) {
        [_delegate chatBoxFaceViewSendButtonDown];
    }
}


/**
 *  添加表情按钮。方法没有完善好
 */
- (void) chatBoxFaceMenuViewAddButtonDown
{
    if (_delegate && [_delegate respondsToSelector:@selector(chatBoxFaceViewSendButtonDown)]) {
        
        [_delegate chatBoxFaceViewSendButtonDown];
    }
}

#pragma mark =========================== ZXChatFaceItemViewDelegate ===========================

- (void)chatFaceItemViewDidClickDelete:(ZXChatFaceItemView *)itemView
{
    if (_delegate && [_delegate respondsToSelector:@selector(chatBoxFaceViewDeleteButtonDown)]) {
        [_delegate chatBoxFaceViewDeleteButtonDown];
    }
}

- (void)chatFaceItemView:(ZXChatFaceItemView *)itemView didSelectFace:(ChatFace *)chatFace faceType:(TLFaceType)faceType
{
    if (_delegate && [_delegate respondsToSelector:@selector(chatBoxFaceViewDidSelectedFace:type:)]) {
        [_delegate chatBoxFaceViewDidSelectedFace:chatFace type:faceType];
    }
}


#pragma mark - UIScrollViewDelegate
- (void) scrollViewDidScroll:(UIScrollView *)scrollView
{
    int page = scrollView.contentOffset.x / self.width;
    if (page > _curPage && (page * KWIDTH - scrollView.contentOffset.x) < KWIDTH * 0.2) {
        
        // 向右翻
        [self showFaceFageAtIndex:page];
    }
    else if (page < _curPage && (scrollView.contentOffset.x - page * KWIDTH) < KWIDTH * 0.2) {
        
        [self showFaceFageAtIndex:page];
    }
}


#pragma mark - Event Response

- (void) pageControlClicked:(UIPageControl *)pageControl
{
    [self showFaceFageAtIndex:pageControl.currentPage];
    [self.scrollView scrollRectToVisible:CGRectMake(pageControl.currentPage * KWIDTH, 0, KWIDTH, self.scrollView.height) animated:YES];
}

/**
 *  不同的组对应的pagecontrol 就是不同的，你点击了不同的组，就要重新加载该组的 pageControl和 scrollView
 *
 */
#pragma mark - Private Methods
- (void) reloadScrollView
{
    /**
     *  这里是要计算表情要显示多少页，
     *  如果是emoji一页显示 20 个，
     *  如果是gif一页显示 20 个，
     *  这里的 page 计算，有139个emoji， 139/20 = 6   %20 = 19  7+1=8 就是8页。
     *  这里的 page 计算，有17个gif， 139/20 = 6   %20 = 19  7+1=8 就是8页。
     */
    int a = (self.curGroup.facesArray.count % (self.curGroup.faceType == TLFaceTypeEmoji ? 20 : 8) == 0) ? 0 : 1;
    int page = (int)(self.curGroup.facesArray.count / (self.curGroup.faceType == TLFaceTypeEmoji ? 20 : 8)) + a;
    [self.pageControl setNumberOfPages:page];
    // KWIDTH 屏幕宽
    [self.scrollView setContentSize:CGSizeMake(KWIDTH * page, self.scrollView.height)];
    [self.scrollView scrollRectToVisible:CGRectMake(0, 0, KWIDTH, self.scrollView.height) animated:NO];
    _curPage = -1;
    [self showFaceFageAtIndex:0];
}

- (void) showFaceFageAtIndex:(NSUInteger)index
{
    // 第一次进去 _curPage = -1  第二次 0  返回第一张 1  再回第二张 0
    if (index == _curPage) {
        return;
    }
    
    [self.pageControl setCurrentPage:index];
    int count = _curGroup.faceType == TLFaceTypeEmoji ? 20 : 8;
    // 切换表情组时（采用三个表情页面来轮流显示，降低内存开销）
    if (_curPage == -1) {
        ZXChatFaceItemView *pageView1 = [self.facePageViewArray objectAtIndex:0];
        [pageView1 showFaceGroup:_curGroup formIndex:0 count:0];
        [pageView1 setOrigin:CGPointMake(-KWIDTH, 0)];
        
        ZXChatFaceItemView *pageView2 = [self.facePageViewArray objectAtIndex:1];
        [pageView2 showFaceGroup:_curGroup formIndex:0 count:count];
        [pageView2 setOrigin:CGPointMake(0, 0)];
        
        ZXChatFaceItemView *pageView3 = [self.facePageViewArray objectAtIndex:2];
        [pageView3 showFaceGroup:_curGroup formIndex:count count:count];
        [pageView3 setOrigin:CGPointMake(KWIDTH, 0)];
    }
    else {
        if (_curPage < index) {
            ZXChatFaceItemView *pageView1 = [self.facePageViewArray objectAtIndex:0];
            [pageView1 showFaceGroup:_curGroup formIndex:(int)(index + 1) * count count:count];
            [pageView1 setOrigin:CGPointMake((index + 1) * KWIDTH, 0)];
            [self.facePageViewArray removeObjectAtIndex:0];
            [self.facePageViewArray addObject:pageView1];
        }
        else {
            ZXChatFaceItemView *pageView3 = [self.facePageViewArray objectAtIndex:2];
            [pageView3 showFaceGroup:_curGroup formIndex:(int)(index - 1) * count count:count];
            [pageView3 setOrigin:CGPointMake((index - 1) * KWIDTH, 0)];
            [self.facePageViewArray removeObjectAtIndex:2];
            [self.facePageViewArray insertObject:pageView3 atIndex:0];
        }
    }
    _curPage = (int)index;
}

#pragma mark - Getter
- (UIView *) topLine
{
    if (_topLine == nil) {
        _topLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, KWIDTH, 0.5)];
        [_topLine setBackgroundColor:DEFAULT_LINE_GRAY_COLOR];
    }
    return _topLine;
}

- (ZXChatFaceMenuView *) faceMenuView
{
    if (_faceMenuView == nil) {
        _faceMenuView = [[ZXChatFaceMenuView alloc] initWithFrame:CGRectMake(0, self.height - HEIGHT_BOTTOM_VIEW, KWIDTH, HEIGHT_BOTTOM_VIEW)];
        [_faceMenuView setDelegate:self];
        [_faceMenuView setFaceGroupArray:[[ChatFaceHelper sharedFaceHelper] faceGroupArray]];
    }
    return _faceMenuView;
}

- (UIPageControl *) pageControl
{
    if (_pageControl == nil) {
        _pageControl = [[UIPageControl alloc] init];
        _pageControl.currentPageIndicatorTintColor = [UIColor grayColor];
        _pageControl.pageIndicatorTintColor = DEFAULT_LINE_GRAY_COLOR;
        [_pageControl addTarget:self action:@selector(pageControlClicked:) forControlEvents:UIControlEventValueChanged];
    }
    return _pageControl;
}

- (UIScrollView *) scrollView
{
    if (_scrollView == nil) {
        _scrollView = [[UIScrollView alloc] init];
        [_scrollView setScrollsToTop:NO];
        [_scrollView setShowsHorizontalScrollIndicator:NO];
        [_scrollView setShowsVerticalScrollIndicator:NO];
        [_scrollView setDelegate:self];
        [_scrollView setPagingEnabled:YES];
    }
    return _scrollView;
}

- (NSMutableArray *) facePageViewArray
{
    if (_facePageViewArray == nil) {
        _facePageViewArray = [[NSMutableArray alloc] initWithCapacity:3];
        for (int i = 0; i < 3; i ++) {
            ZXChatFaceItemView *view = [[ZXChatFaceItemView alloc] initWithFrame:self.scrollView.bounds];
            view.delegate = self;
            [_facePageViewArray addObject:view];
        }
    }
    return _facePageViewArray;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
