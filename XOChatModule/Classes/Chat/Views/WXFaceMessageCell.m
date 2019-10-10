//
//  WXFaceMessageCell.m
//  AFNetworking
//
//  Created by kenter on 2019/10/10.
//

#import "WXFaceMessageCell.h"
#import "ChatFaceHelper.h"
#import "NSBundle+ChatModule.h"
#import <FLAnimatedImage/FLAnimatedImage.h>

@interface WXFaceMessageCell ()

@property (nonatomic, strong) FLAnimatedImageView               *gifImageView;

@end

@implementation WXFaceMessageCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self.messageBackgroundImageView addSubview:self.gifImageView];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGSize faceSize = [self.gifImageView.animatedImage size];
    faceSize = CGSizeMake(faceSize.width/2.0, faceSize.height/2.0);
    float y = self.message.isSelf ? (CGRectGetMaxY(self.avatarImageView.frame) - faceSize.height) : self.avatarImageView.y;
    float x = self.avatarImageView.x + (self.message.isSelf ? - faceSize.width - 5 : self.avatarImageView.width + 5);
    self.gifImageView.frame = CGRectMake(0, 0, faceSize.width, faceSize.height);
    self.messageBackgroundImageView.frame = CGRectMake(x, y, faceSize.width, faceSize.height);
    self.messageSendStatusImageView.center = CGPointMake(x - 20, y + faceSize.height/2.0);
}

- (void)setMessage:(TIMMessage *)message
{
    [super setMessage:message];
    [self.messageBackgroundImageView setImage:nil];
    
    TIMFaceElem *faceElem = (TIMFaceElem *)[message getElem:0];
    if (faceElem.data.length > 0) {
        NSString *groupId = [[NSString alloc] initWithData:faceElem.data encoding:NSUTF8StringEncoding];
        int faceIndex = faceElem.index;
        if (!XOIsEmptyString(groupId)) {
            NSArray <ChatFace *> * chatFaceArray = [[ChatFaceHelper sharedFaceHelper].faceGroupsSet objectForKey:groupId];
            if (chatFaceArray.count > faceIndex) {
                ChatFace *face = [chatFaceArray objectAtIndex:faceIndex];
                NSURL *url = [[NSBundle xo_chatResourceBundle] URLForResource:face.faceID withExtension:@"gif"];
                __block NSData *data = [NSData dataWithContentsOfURL:url];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    FLAnimatedImage *animatedImage = [FLAnimatedImage animatedImageWithGIFData:data];
                    self.gifImageView.animatedImage = animatedImage;
                    [self setNeedsLayout];
                });
            }
        }
    }
}

- (FLAnimatedImageView *)gifImageView
{
    if (!_gifImageView) {
        _gifImageView = [[FLAnimatedImageView alloc] init];
        [_gifImageView setContentMode:UIViewContentModeScaleAspectFit];
        [_gifImageView setUserInteractionEnabled:YES];
    }
    return _gifImageView;
}



@end
