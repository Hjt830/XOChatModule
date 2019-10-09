//
//  ZXChatBoxMoreView.m
//  ZXDNLLTest
//
//  Created by mxsm on 16/5/19.
//  Copyright © 2016年 mxsm. All rights reserved.
//

#import "ZXChatBoxMoreView.h"
#import <XOBaseLib/XOBaseLib.h>

@interface ZXChatBoxMoreView() <UIScrollViewDelegate>

@property (nonatomic, strong) UIView *topLine;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIPageControl *pageControl;

@end

@implementation ZXChatBoxMoreView

- (id) initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self setBackgroundColor:DEFAULT_CHATBOX_COLOR];
        [self addSubview:self.topLine];
        [self addSubview:self.scrollView];
        [self addSubview:self.pageControl];
    }
    return self;
}

-(void) setFrame:(CGRect)frame
{
    [super setFrame:frame];
    
    [self.scrollView setFrame:CGRectMake(0, 0.5, frame.size.width, frame.size.height - 18)];
    [self.pageControl setFrame:CGRectMake(0, self.height - 18, frame.size.width, 8)];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.topLine.width = self.width;
    self.scrollView.width = self.width;
    self.pageControl.width = self.width;
    
    float w = self.width * 20 / 21 / 4 * 0.8;
    float space = w / 4;
    float h = (self.height - 20 - space * 2) / 2;
    float x = space, y = space;
    int i = 0, page = 0;
    for (ZXChatBoxItemView * item in self.items) {
        [self.scrollView addSubview:item];
        [item setFrame:CGRectMake(x, y, w, h)];
        [item addTarget:self action:@selector(didSelectedItem:) forControlEvents:UIControlEventTouchUpInside];
        i ++;
        page = i % 8 == 0 ? page + 1 : page;
        x = (i % 4 ? x + w : page * self.width) + space;
        y = (i % 8 < 4 ? space : h + space * 1.5);
    }
}

#pragma mark - Public Methods
-(void)setItems:(NSMutableArray *)items
{
    _items = items;
    NSInteger index = items.count/8 + (items.count%8 == 0 ? 0 : 1);
    self.pageControl.numberOfPages = index;//加多一页
    self.scrollView.contentSize = CGSizeMake(self.width * index, _scrollView.height);
}

#pragma mark - UIScrollViewDelegate
/**
 *  Decelerat 减速，这个方法是在scrollView 结束减速，也就是在停止的时候执行的
 *  - (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
 if (!decelerate)｛}
 }
 是在结束拖拽，也就是在开始减速的时候执行的。
 */
-(void) scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    // contentOffset 监控目前滚动的位置
    int page = scrollView.contentOffset.x / self.width;
    [_pageControl setCurrentPage:page];
}

/**
 *  didSelectedItem page点击小点点来 控制 scrollView 滑动
 */

#pragma  page开始滑动 pageControlClicked
-(void) pageControlClicked:(UIPageControl *)pageControl
{
    // 动画方法
    [self.scrollView scrollRectToVisible:CGRectMake(pageControl.currentPage * self.width, 0, self.width, self.scrollView.height) animated:YES];
}

/**
 *  didSelectedItem 图标点击事件
 */
- (void)didSelectedItem:(ZXChatBoxItemView *)sender
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatBoxMoreView:didSelectItem:)]) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self.delegate chatBoxMoreView:self didSelectItem:((int)sender.tag - 100)];
        }];
    }
}

#pragma mark - Getter
- (UIScrollView *) scrollView
{
    if (_scrollView == nil) {
        _scrollView = [[UIScrollView alloc] init];
        [_scrollView setShowsHorizontalScrollIndicator:NO];
        [_scrollView setShowsVerticalScrollIndicator:NO];
        
        // 控制控件是否整页翻动(默认为NO)
        [_scrollView setPagingEnabled:YES];
        [_scrollView setScrollsToTop:NO];
        [_scrollView setDelegate:self];
    }
    return _scrollView;
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

- (UIView *) topLine
{
    if (_topLine == nil) {
        _topLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.width, 0.5)];
        [_topLine setBackgroundColor:RGBA(230, 230, 230, 0.8)];
    }
    return _topLine;
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
