//
//  ZXChatBoxView.m
//  ZXDNLLTest
//
//  Created by mxsm on 16/5/19.
//  Copyright © 2016年 mxsm. All rights reserved.
//

#import "ZXChatBoxView.h"
#import <XOBaseLib/XOBaseLib.h>
#import "XOChatModule.h"
#import "CommonTool.h"

#define     CHATBOX_BUTTON_WIDTH        37
#define     HEIGHT_TEXTVIEW             HEIGHT_TABBAR * 0.74
#define     MAX_TEXTVIEW_HEIGHT         104

@interface ZXChatBoxView ()<UITextViewDelegate>

@property (nonatomic, strong) UIView *topLine; // 顶部的线
@property (nonatomic, strong) UIButton *voiceButton; // 声音按钮
@property (nonatomic, strong) UITextView *textView;  // 输入框
@property (nonatomic, strong) UIButton *faceButton;  // 表情按钮
@property (nonatomic, strong) UIButton *moreButton;  // 更多按钮
@property (nonatomic, strong) UIButton *talkButton;  // 聊天键盘按钮


@end

@implementation ZXChatBoxView

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        _safeInset = UIEdgeInsetsZero;
        _curHeight = frame.size.height;// 当前高度初始化为 49
        [self setBackgroundColor:DEFAULT_CHATBOX_COLOR];
        [self addSubview:self.topLine];
        [self addSubview:self.voiceButton];
        [self addSubview:self.textView];
        [self addSubview:self.faceButton];
        [self addSubview:self.moreButton];
        [self addSubview:self.talkButton];
        self.status = TLChatBoxStatusNothing;//初始化状态是空
    }
    return self;
}

-(void)setFrame:(CGRect)frame
{
    // 6 的初始化 0.0.375.49
    [super setFrame:frame];
    _curHeight = frame.size.height;
    self.topLine.width = self.width;
    //  Voice 的高度和宽度初始化的时候都是 37 
    float y = self.height - self.safeInset.bottom - self.voiceButton.height - (HEIGHT_TABBAR - CHATBOX_BUTTON_WIDTH) / 2;
    if (self.voiceButton.y != y) {
        [UIView animateWithDuration:0.1 animations:^{
            // 根据 Voice 的 Y 改变 faceButton  moreButton de Y
            [self.voiceButton setY:y];
            [self.faceButton  setY:self.voiceButton.y];
            [self.moreButton  setY:self.voiceButton.y];
        }];
    }
}

#pragma Public Methods
- (BOOL) resignFirstResponder
{
    [self.textView resignFirstResponder];
    [_moreButton setImage:XOChatGetImage(@"TypeSelectorBtn_Black") forState:UIControlStateNormal];
    [_moreButton setImage:XOChatGetImage(@"TypeSelectorBtnHL_Black") forState:UIControlStateHighlighted];
    [_faceButton setImage:XOChatGetImage(@"ToolViewEmotion") forState:UIControlStateNormal];
    [_faceButton setImage:XOChatGetImage(@"ToolViewEmotionHL") forState:UIControlStateHighlighted];
    return [super resignFirstResponder];
}

- (void) addAtSomeOne:(NSString *)atSomeone
{
    self.textView.text = [self.textView.text stringByAppendingString:atSomeone];
    [self textViewDidChange:self.textView];
    if (![self.textView isFirstResponder]) {
        [self.textView becomeFirstResponder];
    }
}

- (void) addEmojiFace:(ChatFace *)face
{
    NSString *faceText = [NSMutableString stringWithString:face.faceName];
    if (![face.faceName hasPrefix:@"["]) faceText = [@"[" stringByAppendingString:faceText];
    if (![face.faceName hasSuffix:@"]"]) faceText = [faceText stringByAppendingString:@"]"];
    [self.textView setText:[self.textView.text stringByAppendingString:faceText]];
    if (MAX_TEXTVIEW_HEIGHT < self.textView.contentSize.height) {
        float y = self.textView.contentSize.height - self.textView.height;
        y = y < 0 ? 0 : y;
        [self.textView scrollRectToVisible:CGRectMake(0, y, self.textView.width, self.textView.height) animated:YES];
    }
    [self textViewDidChange:self.textView];
}

/**
 *  发送当前消息
 */

- (void) sendCurrentMessage
{
    if (self.textView.text.length > 0) {     // send Text
        if (_delegate && [_delegate respondsToSelector:@selector(chatBox:sendTextMessage:)]) {
            [_delegate chatBox:self sendTextMessage:self.textView.text];
        }
    }
    [self.textView setText:@""];
    [self textViewDidChange:self.textView];
}

- (void) deleteButtonDown
{
    if (self.textView) {
        [self textView:self.textView shouldChangeTextInRange:NSMakeRange(self.textView.text.length - 1, 1) replacementText:@""];
        [self textViewDidChange:self.textView];
    }
}


#pragma mark - UITextViewDelegate
- (void) textViewDidBeginEditing:(UITextView *)textView
{
    /**
     *   textView 已经开始编辑的时候，判断状态
     */
    ZXChatBoxStatus lastStatus = self.status;
    self.status = TLChatBoxStatusShowKeyboard;
    if (lastStatus == TLChatBoxStatusShowFace) {
        
        [_faceButton setImage:XOChatGetImage(@"ToolViewEmotion") forState:UIControlStateNormal];
        [_faceButton setImage:XOChatGetImage(@"ToolViewEmotionHL") forState:UIControlStateHighlighted];
    }
    else if (lastStatus == TLChatBoxStatusShowMore) {
        
        [_moreButton setImage:XOChatGetImage(@"TypeSelectorBtn_Black") forState:UIControlStateNormal];
        [_moreButton setImage:XOChatGetImage(@"TypeSelectorBtnHL_Black") forState:UIControlStateHighlighted];
    }
    
    if (_delegate && [_delegate respondsToSelector:@selector(chatBox:changeStatusForm:to:)]) {
        [_delegate chatBox:self changeStatusForm:lastStatus to:self.status];
    }
}

/**
 *  TextView 的输入内容一改变就调用这个方法，
 */
- (void) textViewDidChange:(UITextView *)textView
{
    /**
     *   textView 的 Frame 值是按照 talkButton  设置的
         sizeThatSize并没有改变原始 textView 的大小
         [label sizeToFit]; 这样搞就直接改变了这个label的宽和高，使它根据上面字符串的大小做合适的改变
     */
    CGFloat height = [textView sizeThatFits:CGSizeMake(self.textView.width, MAXFLOAT)].height;
    height = height > HEIGHT_TEXTVIEW ? height : HEIGHT_TEXTVIEW; // height大于 TextView 的高度 就取height 否则就取 TextView 的高度 --- 下限高度
    height = height < MAX_TEXTVIEW_HEIGHT ? height : textView.height;  // height 小于 textView 的最大高度 104 就取出 height 不然就取出 --- 上限高度
    
    _curHeight = height + self.safeInset.bottom + (HEIGHT_TABBAR - HEIGHT_TEXTVIEW);
    if (_curHeight != self.height) {
        [UIView animateWithDuration:0.05 animations:^{
            self.height = self->_curHeight;
            if (self->_delegate && [self->_delegate respondsToSelector:@selector(chatBox:changeChatBoxHeight:)]) {
                [self->_delegate chatBox:self changeChatBoxHeight:self->_curHeight];
            }
        }];
    }
    
    if (height != textView.height) {
        [UIView animateWithDuration:0.05 animations:^{
            textView.height = height;
        }];
    }
}

////内容将要发生改变编辑
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ([text isEqualToString:@"\n"]) {
        [self sendCurrentMessage];
        return NO;
    }
    // 删除
    else if (textView.text.length > 0 && [text isEqualToString:@""])
    {
        // 删除emoji
        if ([textView.text characterAtIndex:range.location] == ']')
        {
            NSUInteger location = range.location;
            NSUInteger length = range.length;
            while (location != 0) {
                location --;
                length ++ ;
                char c = [textView.text characterAtIndex:location];
                if (c == '[') {
                    
                    textView.text = [textView.text stringByReplacingCharactersInRange:NSMakeRange(location, length) withString:@""];
                    return NO;
                }
                else if (c == ']') {
                    return YES;
                }
            }
        }
        // 删除 @**
        else if ([textView.text characterAtIndex:range.location] == ' ') {
            NSUInteger location = range.location;
            NSUInteger length = range.length;
            while (location != 0) {
                location --;
                length ++ ;
                char c = [textView.text characterAtIndex:location];
                if (c == '@') {

                    textView.text = [textView.text stringByReplacingCharactersInRange:NSMakeRange(location, length) withString:@""];
                    return NO;
                }
                else if (c == ' ') {
                    return YES;
                }
            }
        }
        // 删除文字
        else {
            textView.text = [textView.text stringByReplacingCharactersInRange:NSMakeRange(range.location, range.length) withString:@""];
        }
    }
    // 输入了 @
    else if (textView.text.length > 0 && [text isEqualToString:@"@"])
    {
        if (self.delegate && [self.delegate respondsToSelector:@selector(chatBoxDidInputAtSymbol:)]) {
            [self.delegate chatBoxDidInputAtSymbol:self];
        }
    }
    
    return YES;
}


#pragma mark - Event Response
/**
 *  声音按钮点击
 *
 */
- (void) voiceButtonDown:(UIButton *)sender
{
    ZXChatBoxStatus lastStatus = self.status;
    if (lastStatus == TLChatBoxStatusShowVoice) {      // 正在显示talkButton，改为现实键盘状态
        self.status = TLChatBoxStatusShowKeyboard;
        [self.talkButton setHidden:YES];
        [self.textView setHidden:NO];
        [self.textView becomeFirstResponder];
        [_voiceButton setImage:XOChatGetImage(@"ToolViewInputVoice") forState:UIControlStateNormal];
        [_voiceButton setImage:XOChatGetImage(@"ToolViewInputVoiceHL") forState:UIControlStateHighlighted];
        
        [self textViewDidChange:self.textView];
        if (_delegate && [_delegate respondsToSelector:@selector(chatBox:changeStatusForm:to:)]) {
            [_delegate chatBox:self changeStatusForm:lastStatus to:self.status];
        }
    }
    else {
        // 显示talkButton
        self.curHeight = HEIGHT_TABBAR + self.safeInset.bottom;
        [self setHeight:self.curHeight];
        self.status = TLChatBoxStatusShowVoice;// 如果不是显示讲话的Button，就显示讲话的Button，状态也改变为 shouvoice
        [self.textView resignFirstResponder];
        [self.textView setHidden:YES];
        [self.talkButton setHidden:NO];
        [_voiceButton setImage:XOChatGetImage(@"ToolViewKeyboard") forState:UIControlStateNormal];
        [_voiceButton setImage:XOChatGetImage(@"ToolViewKeyboardHL") forState:UIControlStateHighlighted];
        if (lastStatus == TLChatBoxStatusShowFace) {
            [_faceButton setImage:XOChatGetImage(@"ToolViewEmotion") forState:UIControlStateNormal];
            [_faceButton setImage:XOChatGetImage(@"ToolViewEmotionHL") forState:UIControlStateHighlighted];
        }
        else if (lastStatus == TLChatBoxStatusShowMore) {
            [_moreButton setImage:XOChatGetImage(@"TypeSelectorBtn_Black") forState:UIControlStateNormal];
            [_moreButton setImage:XOChatGetImage(@"TypeSelectorBtnHL_Black") forState:UIControlStateHighlighted];
        }
        
        if (_delegate && [_delegate respondsToSelector:@selector(chatBox:changeStatusForm:to:)]) {
            [_delegate chatBox:self changeStatusForm:lastStatus to:self.status];
        }
    }
}

/**
 *  表情按钮点击时间
 *  1. 无状态时点击   --- 显示表情 -- 按钮为键盘
 *  2. 录音状态时点击 --- 显示表情 -- 按钮为键盘
 *  3. 键盘状态下点击 --- 显示表情 -- 按钮为键盘
 *  4. 更多状态下点击 --- 显示表情 -- 按钮为键盘
 *  5. 表情状态下点击 --- 显示键盘 -- 按钮为表情
 */
- (void) faceButtonDown:(UIButton *)sender
{
    ZXChatBoxStatus lastStatus = self.status;// 记录下上次的状态
    if (lastStatus == TLChatBoxStatusShowFace) {
        // 正在显示表情，按钮显示键盘，改为表情状态（第5种情况）
        self.status = TLChatBoxStatusShowKeyboard;
        
        [_faceButton setImage:XOChatGetImage(@"ToolViewEmotion") forState:UIControlStateNormal];
        [_faceButton setImage:XOChatGetImage(@"ToolViewEmotionHL") forState:UIControlStateHighlighted];
        [self.textView becomeFirstResponder];
        if (_delegate && [_delegate respondsToSelector:@selector(chatBox:changeStatusForm:to:)]) {
            [_delegate chatBox:self changeStatusForm:lastStatus to:self.status];
        }
    }
    else {
        self.status = TLChatBoxStatusShowFace;
        [_faceButton setImage:XOChatGetImage(@"ToolViewKeyboard") forState:UIControlStateNormal];
        [_faceButton setImage:XOChatGetImage(@"ToolViewKeyboardHL") forState:UIControlStateHighlighted];
        if (lastStatus == TLChatBoxStatusShowMore) {
            [_moreButton setImage:XOChatGetImage(@"TypeSelectorBtn_Black") forState:UIControlStateNormal];
            [_moreButton setImage:XOChatGetImage(@"TypeSelectorBtnHL_Black") forState:UIControlStateHighlighted];
        }
        else if (lastStatus == TLChatBoxStatusShowVoice) {
            [_voiceButton setImage:XOChatGetImage(@"ToolViewInputVoice") forState:UIControlStateNormal];
            [_voiceButton setImage:XOChatGetImage(@"ToolViewInputVoiceHL") forState:UIControlStateHighlighted];
            [_talkButton setHidden:YES];
            [_textView setHidden:NO];
            [self textViewDidChange:self.textView];
        }
        else if (lastStatus == TLChatBoxStatusShowKeyboard) {
            [self.textView resignFirstResponder];
        }
        
        if (_delegate && [_delegate respondsToSelector:@selector(chatBox:changeStatusForm:to:)]) {
            [_delegate chatBox:self changeStatusForm:lastStatus to:self.status];
        }
    }
    
}

/**
 *   更多按钮点击
 *  1. 无状态时点击   --- 显示更多 -- 按钮为更多
 *  2. 录音状态时点击 --- 显示更多 -- 按钮为更多
 *  3. 键盘状态下点击 --- 显示更多 -- 按钮为更多
 *  4. 表情状态下点击 --- 显示更多 -- 按钮为更多
 *  5. 更多状态下点击 --- 显示键盘 -- 按钮为键盘
 */
- (void) moreButtonDown:(UIButton *)sender
{
    ZXChatBoxStatus lastStatus = self.status;
    if (lastStatus == TLChatBoxStatusShowMore) {
        
        self.status = TLChatBoxStatusShowKeyboard;
        [_moreButton setImage:XOChatGetImage(@"TypeSelectorBtn_Black") forState:UIControlStateNormal];
        [_moreButton setImage:XOChatGetImage(@"TypeSelectorBtnHL_Black") forState:UIControlStateHighlighted];
        [self.textView becomeFirstResponder];
        if (_delegate && [_delegate respondsToSelector:@selector(chatBox:changeStatusForm:to:)]) {
            [_delegate chatBox:self changeStatusForm:lastStatus to:self.status];
        }
    }
    else {
        
        self.status = TLChatBoxStatusShowMore;
        [_moreButton setImage:XOChatGetImage(@"ToolViewKeyboard") forState:UIControlStateNormal];
        [_moreButton setImage:XOChatGetImage(@"ToolViewKeyboardHL") forState:UIControlStateHighlighted];
        if (lastStatus == TLChatBoxStatusShowFace) {
            [_faceButton setImage:XOChatGetImage(@"ToolViewEmotion") forState:UIControlStateNormal];
            [_faceButton setImage:XOChatGetImage(@"ToolViewEmotionHL") forState:UIControlStateHighlighted];
        }
        else if (lastStatus == TLChatBoxStatusShowVoice) {
            [_voiceButton setImage:XOChatGetImage(@"ToolViewInputVoice") forState:UIControlStateNormal];
            [_voiceButton setImage:XOChatGetImage(@"ToolViewInputVoiceHL") forState:UIControlStateHighlighted];
            [_talkButton setHidden:YES];
            [_textView setHidden:NO];
            [self textViewDidChange:self.textView];
        }
        else if (lastStatus == TLChatBoxStatusShowKeyboard) {
            [self.textView resignFirstResponder];
        }
        if (_delegate && [_delegate respondsToSelector:@selector(chatBox:changeStatusForm:to:)]) {
            [_delegate chatBox:self changeStatusForm:lastStatus to:self.status];
        }
    }
}

- (void) talkButtonDown:(UIButton *)sender
{
    [_talkButton setTitle:XOChatLocalizedString(@"chat.keyboard.sound.send") forState:UIControlStateNormal];
    UIImage *image = [CommonTool imageWithColor:RGBA(255.0 * 0.7, 255.0 * 0.7, 255.0 * 0.7, 0.5) size:CGSizeMake(1.0f, 1.0f)];
    [_talkButton setBackgroundImage:image forState:UIControlStateNormal];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatBoxDidBeginTalking:)]) {
        [self.delegate chatBoxDidBeginTalking:self];
    }
}

- (void) talkButtonUpInside:(UIButton *)sender
{
    [_talkButton setTitle:XOChatLocalizedString(@"chat.keyboard.sound.talk") forState:UIControlStateNormal];
    UIImage *image = [CommonTool imageWithColor:[UIColor clearColor] size:CGSizeMake(1.0f, 1.0f)];
    [_talkButton setBackgroundImage:image forState:UIControlStateNormal];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatBoxDidEndTalking:)]) {
        [self.delegate chatBoxDidEndTalking:self];
    }
}

- (void) talkButtonUpOutside:(UIButton *)sender
{
    [_talkButton setTitle:XOChatLocalizedString(@"chat.keyboard.sound.talk") forState:UIControlStateNormal];
    UIImage *image = [CommonTool imageWithColor:[UIColor clearColor] size:CGSizeMake(1.0f, 1.0f)];
    [_talkButton setBackgroundImage:image forState:UIControlStateNormal];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatBoxDidCancelTalking:)]) {
        [self.delegate chatBoxDidCancelTalking:self];
    }
}

- (void) talkButtonUpCancel:(UIButton *)sender
{
    [_talkButton setTitle:XOChatLocalizedString(@"chat.keyboard.sound.talk") forState:UIControlStateNormal];
    UIImage *image = [CommonTool imageWithColor:[UIColor clearColor] size:CGSizeMake(1.0f, 1.0f)];
    [_talkButton setBackgroundImage:image forState:UIControlStateNormal];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatBoxDidEndTalking:)]) {
        [self.delegate chatBoxDidCancelTalking:self];
    }
}

- (void) talkButtonDragExit:(UIButton *)sender
{
    [_talkButton setTitle:XOChatLocalizedString(@"chat.keyboard.sound.cancel") forState:UIControlStateNormal];
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatBoxWillCancelTalking:)]) {
        [self.delegate chatBoxWillCancelTalking:self];
    }
}

- (void) talkButtonDragEnter:(UIButton *)sender
{
    [_talkButton setTitle:XOChatLocalizedString(@"chat.keyboard.sound.send") forState:UIControlStateNormal];
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatBoxWillGoOnTalking:)]) {
        [self.delegate chatBoxWillGoOnTalking:self];
    }
}

#pragma mark - Getter
- (UIView *) topLine
{
    if (_topLine == nil) {
        _topLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0.35)];
        [_topLine setBackgroundColor:RGBA(178, 178, 178, 1.0)];
    }
    return _topLine;
}

- (UIButton *) voiceButton
{
    if (_voiceButton == nil) {
        _voiceButton = [[UIButton alloc] initWithFrame:CGRectMake(0, (HEIGHT_TABBAR - CHATBOX_BUTTON_WIDTH) / 2, CHATBOX_BUTTON_WIDTH, CHATBOX_BUTTON_WIDTH)];
        [_voiceButton setImage:XOChatGetImage(@"ToolViewInputVoice") forState:UIControlStateNormal];
        [_voiceButton setImage:XOChatGetImage(@"ToolViewInputVoiceHL") forState:UIControlStateHighlighted];
        [_voiceButton addTarget:self action:@selector(voiceButtonDown:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _voiceButton;
}

- (UITextView *) textView
{
    if (_textView == nil) {
        _textView = [[UITextView alloc] initWithFrame:self.talkButton.frame];
        [_textView setFont:[UIFont systemFontOfSize:16.0f]];
        [_textView.layer setMasksToBounds:YES];
        [_textView.layer setCornerRadius:4.0f];
        [_textView.layer setBorderWidth:0.5f];
        [_textView.layer setBorderColor:self.topLine.backgroundColor.CGColor];
        [_textView setScrollsToTop:NO];
        [_textView setReturnKeyType:UIReturnKeySend];// 返回按钮更改为发送
        [_textView setDelegate:self];
    }
    return _textView;
}

- (UIButton *) faceButton
{
    if (_faceButton == nil) {
        _faceButton = [[UIButton alloc] initWithFrame:CGRectMake(self.moreButton.x - CHATBOX_BUTTON_WIDTH, (HEIGHT_TABBAR - CHATBOX_BUTTON_WIDTH) / 2, CHATBOX_BUTTON_WIDTH, CHATBOX_BUTTON_WIDTH)];
        [_faceButton setImage:XOChatGetImage(@"ToolViewEmotion") forState:UIControlStateNormal];
        [_faceButton setImage:XOChatGetImage(@"ToolViewEmotionHL") forState:UIControlStateHighlighted];
        [_faceButton addTarget:self action:@selector(faceButtonDown:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _faceButton;
}

- (UIButton *) moreButton
{
    if (_moreButton == nil) {
        _moreButton = [[UIButton alloc] initWithFrame:CGRectMake(self.width - self.safeInset.right - CHATBOX_BUTTON_WIDTH, (HEIGHT_TABBAR - CHATBOX_BUTTON_WIDTH) / 2, CHATBOX_BUTTON_WIDTH, CHATBOX_BUTTON_WIDTH)];
        [_moreButton setImage:XOChatGetImage(@"TypeSelectorBtn_Black") forState:UIControlStateNormal];
        [_moreButton setImage:XOChatGetImage(@"TypeSelectorBtnHL_Black") forState:UIControlStateHighlighted];
        [_moreButton addTarget:self action:@selector(moreButtonDown:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _moreButton;
}

- (UIButton *) talkButton
{
    if (_talkButton == nil) {
        _talkButton = [[UIButton alloc] initWithFrame:CGRectMake(self.voiceButton.x + self.voiceButton.width + 4, self.height * 0.13, self.faceButton.x - self.voiceButton.x - self.voiceButton.width - 8, HEIGHT_TEXTVIEW)];
        [_talkButton setTitle:XOChatLocalizedString(@"chat.keyboard.sound.talk") forState:UIControlStateNormal];
        [_talkButton setTitle:XOChatLocalizedString(@"chat.keyboard.sound.send") forState:UIControlStateHighlighted];
        [_talkButton setTitleColor:[UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:1.0] forState:UIControlStateNormal];
        [_talkButton setBackgroundImage:[CommonTool imageWithColor:[UIColor colorWithRed:0.7 green:0.7 blue:0.7 alpha:0.5] size:CGSizeMake(1.0, 1.0)] forState:UIControlStateHighlighted];
        [_talkButton.titleLabel setFont:[UIFont boldSystemFontOfSize:16.0f]];
        [_talkButton.layer setMasksToBounds:YES];
        [_talkButton.layer setCornerRadius:4.0f];
        [_talkButton.layer setBorderWidth:0.5f];
        [_talkButton.layer setBorderColor:self.topLine.backgroundColor.CGColor];
        [_talkButton setHidden:YES];
        [_talkButton addTarget:self action:@selector(talkButtonDown:) forControlEvents:UIControlEventTouchDown];
        [_talkButton addTarget:self action:@selector(talkButtonUpInside:) forControlEvents:UIControlEventTouchUpInside];
        [_talkButton addTarget:self action:@selector(talkButtonUpOutside:) forControlEvents:UIControlEventTouchUpOutside];
        [_talkButton addTarget:self action:@selector(talkButtonUpCancel:) forControlEvents:UIControlEventTouchCancel];
        [_talkButton addTarget:self action:@selector(talkButtonDragExit:) forControlEvents:UIControlEventTouchDragExit];
        [_talkButton addTarget:self action:@selector(talkButtonDragEnter:) forControlEvents:UIControlEventTouchDragEnter];
    }
    return _talkButton;
}

//- (void)setSafeInset:(UIEdgeInsets)safeInset
//{
//    _safeInset = safeInset;
//}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.topLine.width = self.width;
    self.moreButton.x = self.width - self.safeInset.right - CHATBOX_BUTTON_WIDTH;
    self.faceButton.x = self.moreButton.x - CHATBOX_BUTTON_WIDTH;
    self.talkButton.width = self.faceButton.x - self.voiceButton.x - self.voiceButton.width - 8;
    self.textView.width = self.talkButton.width;
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
