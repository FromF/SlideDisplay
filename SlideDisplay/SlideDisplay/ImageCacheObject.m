//
//  ImageCacheObject.m
//  SlideDisplay
//
//  Created by Fuji on 2015/06/09.
//  Copyright (c) 2015年 FromF. All rights reserved.
//

#import "ImageCacheObject.h"

@interface ImageCacheObject()

@property (nonatomic , strong) NSCache *cache;

@end

@implementation ImageCacheObject

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.cache = [[NSCache alloc] init] ;
        self.cache.countLimit = 10;
    }
    return self;
}


- (UIImage *)getUncachedImage:(NSString *)imgPath{
    
    UIImage *image = [self.cache objectForKey:imgPath];
    
    if (image == nil) {
        image = [[UIImage alloc] initWithContentsOfFile:imgPath];
        [self.cache setObject:image forKey:imgPath];
    }
    
    return image;
}

@end
