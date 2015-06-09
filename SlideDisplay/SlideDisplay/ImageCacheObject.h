//
//  ImageCacheObject.h
//  SlideDisplay
//
//  Created by Fuji on 2015/06/09.
//  Copyright (c) 2015年 FromF. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface ImageCacheObject : NSObject

- (UIImage *)getUncachedImage:(NSString *)imgPath;

@end
