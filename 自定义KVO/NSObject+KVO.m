//
//  NSObject+KVO.m
//  002-KVO的实现原理
//
//  Created by dy on 2018/7/29.
//  Copyright © 2018年dywc. All rights reserved.
//

#import "NSObject+KVO.h"
#import <objc/message.h>

@implementation NSObject (KVO)

#pragma mark - 不创建子类版
- (void)dy_addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(nullable void *)context {
    if(!observer) return;
    // setter
    NSString* setterMethodName = setterForGetter(keyPath);
    SEL setterSEL = NSSelectorFromString(setterMethodName);
    Method setterMethod = class_getInstanceMethod([self class], setterSEL);
    const char* setterTypes = method_getTypeEncoding(setterMethod);
    
    //替换name的setter方法自己实现
    class_replaceMethod([self class], setterSEL, (IMP)dy_setter, setterTypes);
    //将观察者关联为属性，属性便于后面使用
    
    NSMutableArray *observerArr = objc_getAssociatedObject(self, (__bridge void *)@"observerArr")?: [NSMutableArray array];
    
    if (![observerArr containsObject:observer]) [observerArr insertObject:observer atIndex:0];
    objc_setAssociatedObject(self, (__bridge void *)@"observerArr", observerArr, OBJC_ASSOCIATION_RETAIN);
}

static void dy_setter(id self, SEL _cmd, id newValue) {
    NSLog(@"%s", __func__);
    
    NSString* setterName = NSStringFromSelector(_cmd);
    NSString* key = getterForSetter(setterName);
    char *char_content = (char *)[[NSString stringWithFormat:@"_%@",key] cStringUsingEncoding:NSASCIIStringEncoding];
    Ivar ivar = class_getInstanceVariable([self class], char_content);
    object_setIvar(self, ivar, newValue);
    id observerArr = objc_getAssociatedObject(self, (__bridge void *)@"observerArr");
    for (id observer in observerArr) {
        [observer observeValueForKeyPath:key ofObject:self change:@{key:newValue} context:nil];
    }
}

#pragma mark - 通过子类实现版(apple官方是通过创建子类来实现)
/// 添加观察者
- (void)gv_addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(nullable void *)context {
    
    // 动态创建一个子类
    Class newClass = [self createClass:keyPath];
    
    // 修改了isa的指向
    object_setClass(self, newClass);
    
    NSMutableArray *observerArr = objc_getAssociatedObject(self, (__bridge void *)@"observerArr")?: [NSMutableArray array];
    
    if (![observerArr containsObject:observer]) [observerArr insertObject:observer atIndex:0];
    objc_setAssociatedObject(self, (__bridge void *)@"observerArr", observerArr, OBJC_ASSOCIATION_RETAIN);
}

// NSKVONotifying_TZPerson
- (Class) createClass:(NSString*) keyPath {
   
    // 1. 拼接子类名 // Person
    NSString* oldName = NSStringFromClass([self class]);
    NSString* newName = [NSString stringWithFormat:@"TZKVONotifying_%@", oldName];
    
    // 2. 创建并注册类
    Class newClass = NSClassFromString(newName);
    if (!newClass) {
        
        // 创建并注册类
        newClass = objc_allocateClassPair([self class], newName.UTF8String, 0);
        objc_registerClassPair(newClass);
        
        // 添加一些方法
        // class
        Method classMethod = class_getInstanceMethod([self class], @selector(class));
        const char* classTypes = method_getTypeEncoding(classMethod);
        class_addMethod(newClass, @selector(class), (IMP)tz_class, classTypes);
        
        // setter
        NSString* setterMethodName = setterForGetter(keyPath);
        SEL setterSEL = NSSelectorFromString(setterMethodName);
        Method setterMethod = class_getInstanceMethod([self class], setterSEL);
        const char* setterTypes = method_getTypeEncoding(setterMethod);
        
        class_addMethod(newClass, setterSEL, (IMP)tz_setter, setterTypes);
        
        // 添加析构方法
        SEL deallocSEL = NSSelectorFromString(@"dealloc");
        Method deallocMethod = class_getInstanceMethod([self class], deallocSEL);
        const char* deallocTypes = method_getTypeEncoding(deallocMethod);
        class_addMethod(newClass, deallocSEL, (IMP)myDealloc, deallocTypes);
        
        // hook dealloc
       // [self hookDealloc];
    }
    return newClass;
}

void myDealloc(id self, SEL _cmd) {
    // 父类
    Class superClass = [self class];//class_getSuperclass(object_getClass(self));
    
    object_setClass(self, superClass);
    
    NSLog(@"");
}

//- (void) myDealloc {
//
//        // 父类
//    Class superClass = [self class];//class_getSuperclass(object_getClass(self));
//
//    object_setClass(self, superClass);
//
//    [self myDealloc];
//}

- (void) hookDealloc {
    Method m1 = class_getInstanceMethod(object_getClass(self), NSSelectorFromString(@"dealloc"));
    Method m2 = class_getInstanceMethod(object_getClass(self), @selector(myDealloc));
    method_exchangeImplementations(m1, m2);
}

#pragma mark - c 函数


static void tz_setter(id self, SEL _cmd, id newValue) {

    // 通知观察者， 值发生改变了
    // 观察者
    struct objc_super superStruct = {
        self,
        class_getSuperclass(object_getClass(self))
    };
    
    // 改变父类的值
    objc_msgSendSuper(&superStruct, _cmd, newValue);
    
    NSString* setterName = NSStringFromSelector(_cmd);
    NSString* key = getterForSetter(setterName);
    
    id observerArr = objc_getAssociatedObject(self, (__bridge void *)@"observerArr");
    for (id observer in observerArr) {
        [observer observeValueForKeyPath:key ofObject:self change:@{key:newValue} context:nil];
    }
}


Class tz_class(id self, SEL _cmd) {
    return class_getSuperclass(object_getClass(self));
}

/// 移除观察者
- (void)gv_removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath {

    // 父类
    Class superClass = [self class];//class_getSuperclass(object_getClass(self));

    object_setClass(self, superClass);

}


#pragma mark - 从get方法获取set方法的名称 key ===>>> setKey:
static NSString  * setterForGetter(NSString *getter){
    
    if (getter.length <= 0) { return nil; }
    
    NSString *firstString = [[getter substringToIndex:1] uppercaseString];
    NSString *leaveString = [getter substringFromIndex:1];
    
    return [NSString stringWithFormat:@"set%@%@:",firstString,leaveString];
}

#pragma mark - 从set方法获取getter方法的名称 set<Key>:===> Key
static NSString * getterForSetter(NSString *setter){
    
    if (setter.length <= 0 || ![setter hasPrefix:@"set"] || ![setter hasSuffix:@":"]) { return nil;}
    
    NSRange range = NSMakeRange(3, setter.length-4);
    NSString *getter = [setter substringWithRange:range];
    NSString *firstString = [[getter substringToIndex:1] lowercaseString];
    getter = [getter stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:firstString];
    
    return getter;
}

@end
