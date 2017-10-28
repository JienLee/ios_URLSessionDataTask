//
//  ViewController.m
//  MemregTestApplication
//
//  Created by 이지은 on 2017. 10. 19..
//  Copyright © 2017년 이지은. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

NSString *strMemRegUrl;
NSString *strCheckUrl;
NSString *strResult;

NSURLSession *session;
NSURLSessionDataTask *memRegDataTask;
NSURLSessionDataTask *checkDataTask;

SEL selectorChangeLabel;

int startCnt;

- (IBAction)btnStartClick:(UIButton *)sender {
    strResult = [NSString stringWithFormat:@"%@\r%@", strResult, @"start click!"];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *strPushKey = [@"iOSMemTEST_" stringByAppendingFormat:@"%d", arc4random()];
    [defaults setObject:strPushKey forKey:@"push"];
    [defaults synchronize];
    
    if(memRegDataTask.state == NSURLSessionTaskStateRunning) {
        [memRegDataTask cancel];
    } else if (checkDataTask.state == NSURLSessionTaskStateRunning) {
        [checkDataTask cancel];
    }
    
    [self memRegPost];
    [self checkPost];
    [memRegDataTask resume];
    [self changeLabel];
}

- (IBAction)btnStopClick:(UIButton *)sender {
    
    if (memRegDataTask.state == NSURLSessionTaskStateRunning ||
        memRegDataTask.state == NSURLSessionTaskStateSuspended) {
        [memRegDataTask cancel];
    } else if (checkDataTask.state == NSURLSessionTaskStateRunning ||
               checkDataTask.state == NSURLSessionTaskStateSuspended) {
            [checkDataTask cancel];
    }

    strResult = [NSString stringWithFormat:@"%@\r%@", strResult, @"stop click!"];
    // startCnt = 0;
    [self changeLabel];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    startCnt = 0;
    
    selectorChangeLabel = @selector(changeLabel);
    session = [NSURLSession sharedSession];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@"iOSMemTEST_123123123" forKey:@"device"];
    [defaults setObject:@"490717" forKey:@"user"];
    [defaults synchronize];
    
    NSString *path = [NSBundle.mainBundle pathForResource:@"Keys" ofType:@"plist"];
    NSDictionary *plist = [NSDictionary dictionaryWithContentsOfFile:path];
    
    strMemRegUrl = [NSString stringWithFormat:@"%@", [plist objectForKey:@"parseApiUrl"]];
    strCheckUrl = [NSString stringWithFormat:@"%@", [plist objectForKey:@"parseCheckApiUrl"]];
    strResult = @"";
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)memRegPost {
    startCnt++;
    
    NSURL *url = [NSURL URLWithString:strMemRegUrl];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                        cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                    timeoutInterval:60.0];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPMethod:@"POST"];
    
    NSDictionary *bundleInfo = [[NSBundle mainBundle] infoDictionary];
    NSString *currentVersion = [bundleInfo objectForKey:@"CFBundleShortVersionString"];
    
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    NSString *deviceId = [userDefault stringForKey:@"device"];
    NSString *pushId = [userDefault stringForKey:@"push"];
    NSString *userId = [userDefault stringForKey:@"user"];
    
    NSString *params = [NSString stringWithFormat:@"device_id=%@&push_id=%@&m_no=%@&version=%@&platform=I",
                        deviceId, pushId, userId, currentVersion];
    
    [request setHTTPBody:[params dataUsingEncoding:NSUTF8StringEncoding]];

    memRegDataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if(error){
            strResult = [strResult stringByAppendingString:[NSString stringWithFormat:@"\r[%d]", startCnt]];
            strResult = [strResult stringByAppendingString:@"mem reg http error"];
            [self callChangeLabelMethod];
            [self performSelectorOnMainThread:@selector(performStopClick) withObject:nil waitUntilDone:nil];
            
        } else if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
            if([httpResponse statusCode] == 200){
                NSString * str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                NSData *jsonData = [str dataUsingEncoding:NSUTF8StringEncoding];
                NSError *e;
                NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:jsonData options:nil error:&e];
                
                if([dict objectForKey:@"success"] != nil && [dict objectForKey:@"success"]){
                    [checkDataTask resume];
                } else {
                    strResult = [strResult stringByAppendingString:[NSString stringWithFormat:@"\r[%d]", startCnt]];
                    strResult = [strResult stringByAppendingFormat:@"%@\r", @"mem reg api not success"];
                }
            } else {
                strResult = [strResult stringByAppendingString:[NSString stringWithFormat:@"\r[%d]", startCnt]];
                strResult = [strResult stringByAppendingFormat:@"%@:%ld\r",@"mem response error", (long)[httpResponse statusCode]];
            }
        }
    }];
}

- (void)checkPost {
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    NSString *deviceId = [userDefault stringForKey:@"device"];
    
    NSURL *url = [NSURL URLWithString:strCheckUrl];
    
    NSMutableURLRequest *request = [ NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPMethod:@"POST"];
    
    NSString *params = [NSString stringWithFormat:@"deviceId=%@", deviceId];
    
    [request setHTTPBody:[params dataUsingEncoding:NSUTF8StringEncoding]];
    
    checkDataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        if(error){
            strResult = [strResult stringByAppendingString:[NSString stringWithFormat:@"\r[%d]", startCnt]];
            strResult = [strResult stringByAppendingString:@"check data http error"];
            [self callChangeLabelMethod];
            [self performSelectorOnMainThread:@selector(performStopClick) withObject:nil waitUntilDone:nil];
            
        } else if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
            if([httpResponse statusCode] == 200){
                NSString * str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                NSData *jsonData = [str dataUsingEncoding:NSUTF8StringEncoding];
                NSError *e;
                NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:jsonData options:nil error:&e];
                
                if([dict objectForKey:@"message"] != nil &&
                   [@"success" isEqualToString:[dict objectForKey:@"message"]]){
                    NSArray *dataArr = [dict valueForKey:@"result"];
                    if([dataArr count] >= 1) {
                        NSDictionary *resultDict =[dataArr firstObject];
                        NSString *responsePushId = [NSString stringWithFormat:@"%@", [resultDict objectForKey:@"PUSH_ID"]];
//                        NSString *responseUser = [NSString stringWithFormat:@"%@", [resultDict objectForKey:@"M_NO"]];
                        
                        NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
                        NSString *pushId = [userDefault stringForKey:@"push"];
//                        NSString *userId = [userDefault stringForKey:@"user"];
                        
                        if ([responsePushId isEqualToString:pushId] ) { // || [userId isEqualToString:responseUser]
                            
//                            if([userId isEqualToString:responseUser] == NO){
//                                strResult = [strResult stringByAppendingString:[NSString stringWithFormat:@"\r[%d]", startCnt]];
//                                strResult = [strResult stringByAppendingFormat:@"\r%@\r", @"mno not update"];
//                                strResult = [strResult stringByAppendingFormat:@"\rlocal :%@\r", userId];
//                                strResult = [strResult stringByAppendingFormat:@"\rdb :%@\r", responseUser];
//
//                                [self callChangeLabelMethod];
//                            }
                            
                        } else {
                            strResult = [strResult stringByAppendingString:[NSString stringWithFormat:@"\r[%d]", startCnt]];
                            strResult = [strResult stringByAppendingFormat:@"\r%@\r", @"api fail"];
                            [self callChangeLabelMethod];
                        }
                        
                    } else {
                        strResult = [strResult stringByAppendingString:[NSString stringWithFormat:@"\r[%d]", startCnt]];
                        strResult = [strResult stringByAppendingFormat:@"\r%@\r", @"not exist data"];
                        [self callChangeLabelMethod];
                    }
                }
                
                if(memRegDataTask.state == NSURLSessionTaskStateCompleted
                   && checkDataTask.state == NSURLSessionTaskStateCompleted){
                    [self performSelectorOnMainThread:@selector(restartMemTask) withObject:nil waitUntilDone:nil];
                }
            }else {
                strResult = [strResult stringByAppendingFormat:@"%@:%ld\r",@"check response error", (long)[httpResponse statusCode]];
            }
        }
    }];
}

- (void)changeLabel {
    _txtResult.text = strResult;
}

- (void)restartMemTask{
    
    if(memRegDataTask.state == NSURLSessionTaskStateCompleted
       && checkDataTask.state == NSURLSessionTaskStateCompleted){
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *userId = [defaults stringForKey:@"user"];
        if([@"490717" isEqualToString:userId]) {
            userId = @"0";
            [defaults setObject:userId forKey:@"user"];
            
        } else if ([@"0" isEqualToString:userId]) {
            userId = @"2179686";
            [defaults setObject:userId forKey:@"user"];
            
        } else if ([@"2179686" isEqualToString:userId]) {
            userId = @"490717";
            [defaults setObject:userId forKey:@"user"];
        }
        
        [defaults synchronize];
        
        [self memRegPost];
        [self checkPost];
        [self performSelector:@selector(callMemTask) withObject:nil afterDelay:5];
    }
}

- (void)callMemTask {
    [memRegDataTask resume];
}

- (void)performStopClick {
    [_btnStop sendActionsForControlEvents:UIControlEventTouchUpInside];
}

- (void)callChangeLabelMethod{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self performSelector:selectorChangeLabel withObject:nil afterDelay:0];
    });
}

@end

