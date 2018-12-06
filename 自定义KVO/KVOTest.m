//
//  KVOTest.m
//  003-自定义KVO
//
//  Created by 杜燚 on 2018/12/5.
//  Copyright © 2018年dywc. All rights reserved.
//

#import "KVOTest.h"


@implementation KVOTest

- (instancetype)init
{
    self = [super init];
    if (self) {
        _p = [Person new];
    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    NSLog(@"%@  ---  %@", change,_p.name);
}
@end

