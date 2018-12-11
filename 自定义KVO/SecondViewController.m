//
//  SecondViewController.m
//  003-自定义KVO
//
//  Created by dy on 2018/7/30.
//  Copyright © 2018年dywc. All rights reserved.
//

#import "SecondViewController.h"
#import "Person.h"
#import "NSObject+KVO.h"
#import <objc/runtime.h>
#import "KVOTest.h"

@interface SecondViewController ()
@property (nonatomic, strong) Person* p;
@property (nonatomic, strong) KVOTest *obser;
@end

@implementation SecondViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _p = [Person new];
    _obser = [[KVOTest alloc] init];
    /// 添加观察者
    [_p gv_addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionNew context:nil];
    [_p gv_addObserver:_obser forKeyPath:@"name" options:NSKeyValueObservingOptionNew context:nil];
    

//    [self printClasses:[Person class]];
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

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    NSLog(@"%@  ---  %@", change,_p.name);
}


- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    _p.name = @"Tom";
}

//- (void) dealloc {
//    /// 移除观察者
//    [_p gv_removeObserver:self forKeyPath:@"name"];
//    NSLog(@"hello");
//}

@end
