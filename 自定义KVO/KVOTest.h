//
//  KVOTest.h
//  003-自定义KVO
//
//  Created by 杜燚 on 2018/12/5.
//  Copyright © 2018年dywc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Person.h"
#import "NSObject+KVO.h"

NS_ASSUME_NONNULL_BEGIN

@interface KVOTest : NSObject
@property (nonatomic, strong) Person* p;
@end

NS_ASSUME_NONNULL_END
