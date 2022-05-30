//
//  ViewController.m
//  session_reuse_test
//
//  Created by 李扬 on 2021/12/8.
//

#import "ViewController.h"
#import "AFHTTPSessionManager.h"

@interface ViewController ()
@property (nonatomic, strong) NSMutableDictionary *dictM;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.dictM = [NSMutableDictionary dictionary];
}

// 相同 session 不同host
// 不同host不复用，相同host复用
- (IBAction)testBtnClicked:(UIButton *)sender {
    NSURLSessionConfiguration *sessionConfig = [[NSURLSessionConfiguration defaultSessionConfiguration] copy];
    sessionConfig.HTTPMaximumConnectionsPerHost = 1000;

    AFHTTPSessionManager *sesstionManager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:sessionConfig];
    
    [sesstionManager setTaskDidFinishCollectingMetricsBlock:^(NSURLSession * _Nonnull session, NSURLSessionTask * _Nonnull task, NSURLSessionTaskMetrics * _Nullable metrics) {
        for(NSURLSessionTaskTransactionMetrics *trans in metrics.transactionMetrics) {
            [self.dictM setObject:@(trans.isReusedConnection) forKey:[NSString stringWithFormat:@"%p-%@", task, @(task.taskIdentifier)]];
//            NSLog(@"------ task id %p-%zd reuse %@", task, task.taskIdentifier, self.dictM[[NSString stringWithFormat:@"%p-%@", task, @(task.taskIdentifier)]]);
        }
    }];
    
    [sesstionManager setTaskDidCompleteBlock:^(NSURLSession * _Nonnull session, NSURLSessionTask * _Nonnull task, NSError * _Nullable error) {
        NSLog(@"------ task id %p-%zd reuse %@", task, task.taskIdentifier, self.dictM[[NSString stringWithFormat:@"%p-%@", task, @(task.taskIdentifier)]]);
    }];
    
    for (int i = 0; i < 3; ++i) {
        NSURLSessionDataTask *task = [sesstionManager GET:@"https://maimai.cn/index.html" parameters:nil headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                    NSLog(@"------ task id %p-%zd success", task, task.taskIdentifier);
                } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                    NSLog(@"------ task id %p-%zd failed", task, task.taskIdentifier);
                }];
        
        NSLog(@"------ task id %p-%zd created", task, task.taskIdentifier);
        
        [task addObserver:self forKeyPath:@"countOfBytesReceived" options:NSKeyValueObservingOptionOld context:(__bridge void*)task];
        [task resume];
        usleep(1 * 1000);
    }
    
//    for (int i = 0; i < 3; ++i) {
//        NSURLSessionDataTask *task = [sesstionManager GET:@"https://www.cnblogs.com" parameters:nil headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
//                    NSLog(@"------ task id %p-%zd success", task, task.taskIdentifier);
//                } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
//                    NSLog(@"------ task id %p-%zd failed", task, task.taskIdentifier);
//                }];
//        
//        NSLog(@"------ task 222 id %p-%zd created", task, task.taskIdentifier);
//        
//        [task addObserver:self forKeyPath:@"countOfBytesReceived" options:NSKeyValueObservingOptionOld context:(__bridge void*)task];
//        [task resume];
//        usleep(1 * 1000);
//    }
    
//    [self test1BtnClicked:nil];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self test1BtnClicked:nil];
    });
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if([[change objectForKey:@"old"] integerValue] == 0 && [keyPath isEqualToString:@"countOfBytesReceived"]){
        NSLog(@"------ task id %p-%zd: started", object, ((NSURLSessionDataTask*)object).taskIdentifier);
        @try {
            if ((__bridge void *)object == context) {
                [object removeObserver:self forKeyPath:@"countOfBytesReceived" context:(__bridge void*)object];
            }
        }
        @catch (NSException *exception) {
        }
    }
}

// 不同 session 相同host
// 不同 session 相同host 不复用
- (IBAction)test1BtnClicked:(UIButton *)sender {
    NSURLSessionConfiguration *sessionConfig = [[NSURLSessionConfiguration defaultSessionConfiguration] copy];
//    sessionConfig.HTTPMaximumConnectionsPerHost = 1000;

    AFHTTPSessionManager *sesstionManager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:sessionConfig];
    
    [sesstionManager setTaskDidFinishCollectingMetricsBlock:^(NSURLSession * _Nonnull session, NSURLSessionTask * _Nonnull task, NSURLSessionTaskMetrics * _Nullable metrics) {
        for(NSURLSessionTaskTransactionMetrics *trans in metrics.transactionMetrics) {
            [self.dictM setObject:@(trans.isReusedConnection) forKey:[NSString stringWithFormat:@"%p-%@", task, @(task.taskIdentifier)]];
        }
    }];
    
    [sesstionManager setTaskDidCompleteBlock:^(NSURLSession * _Nonnull session, NSURLSessionTask * _Nonnull task, NSError * _Nullable error) {
        NSLog(@"------ task id %p-%zd reuse %@", task, task.taskIdentifier, self.dictM[[NSString stringWithFormat:@"%p-%@", task, @(task.taskIdentifier)]]);
    }];
    
    for (int i = 0; i < 3; ++i) {
        NSURLSessionDataTask *task = [sesstionManager GET:@"https://www.cnblogs.com" parameters:nil headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                    NSLog(@"------ task id %p-%zd success", task, task.taskIdentifier);
                } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                    NSLog(@"------ task id %p-%zd failed", task, task.taskIdentifier);
                }];
        
        NSLog(@"------ task 1111 id %p-%zd created", task, task.taskIdentifier);
        
        [task addObserver:self forKeyPath:@"countOfBytesReceived" options:NSKeyValueObservingOptionOld context:(__bridge void*)task];
        [task resume];
        usleep(1 * 1000);
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self testBtnClicked:nil];
    });
}

@end
