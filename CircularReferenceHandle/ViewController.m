//
//  ViewController.m
//  CircularReferenceHandle
//
//  Created by 李辉 on 2020/10/24.
//

#import "ViewController.h"
typedef void (^myBlock)(id data);

@interface ViewController ()
@property(nonatomic, strong) NSString *name;
@property(nonatomic, strong) myBlock block;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.name = @"Machiel";
    [self Method4];
}
//Method0 引发循环引用问题
-(void)Method0 {
    self.block = ^(id data) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSLog(@"Hello,%@",self.name);//如果快速的点击返回，2秒之后当前VC已经析构了，拿到的name就是null，Method2的强弱共舞就可以解决这种场景。
        });
    };
    self.block(nil);
}
//Method1 常规弱引用解决办法
-(void)Method1 {
    __weak typeof(self) weakSelf = self;
    self.block = ^(id data) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSLog(@"Hello,%@",weakSelf.name);//如果快速的点击返回，2秒之后当前VC已经析构了，拿到的name就是null，Method2的强弱共舞就可以解决这种场景。
        });
    };
    self.block(nil);
}
//Method2 强弱共舞来解决变量过早释放导致的bug
-(void)Method2 {
    __weak typeof(self) weakSelf = self;
    self.block = ^(id data) {
        __strong typeof(self) strongSelf = weakSelf;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSLog(@"Hello,%@",strongSelf.name);//如果快速的点击返回，2秒之后当前VC已经析构了，拿到的name就是null，Method2的强弱共舞就可以解决这种场景。
        });
    };
    self.block(nil);
}

//Method3 引入中间临时变量，使用完毕之后置为nil
-(void)Method3 {
    __block ViewController *vc = self;
    self.block = ^(id data) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSLog(@"Hello,%@",vc.name);
            vc = nil;//使用完毕之后将vc置空，解除循环引用。
        });
    };
    self.block(nil);
}

//Method4 将self作为参数传递来解除循环引用
-(void)Method4 {
    self.block = ^(ViewController *vc) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSLog(@"Hello,%@",vc.name);
        });
    };
    self.block(self);
}

-(void)dealloc {
    NSLog(@"ViewController析构了!");
}
-(void)didReceiveMemoryWarning {
    
}

@end
