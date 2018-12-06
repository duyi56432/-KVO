//
//  ViewController.m
//  003-自定义KVO
//
//  Created by dy on 2018/7/30.
//  Copyright © 2018年dywc. All rights reserved.
//

#import "ViewController.h"
#import <objc/runtime.h>
#import "Person.h"


@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    [self printClasses:[Person class]];
}

/// 打印对应的类及子类
- (void) printClasses:(Class) cls {
    
    /// 注册类的总数
    int count = objc_getClassList(NULL, 0);
    
    /// 创建一个数组， 其中包含给定对象
    NSMutableArray* array = [NSMutableArray arrayWithObject:cls];
    
    /// 获取所有已注册的类
    Class* classes = (Class*)malloc(sizeof(Class)*count);
    objc_getClassList(classes, count);
    
    /// 遍历s
    for (int i = 0; i < count; i++) {
        if (cls == class_getSuperclass(classes[i])) {
            [array addObject:classes[i]];
        }
    }
    
    free(classes);
    
    NSLog(@"classes = %@", array);
}
@end
