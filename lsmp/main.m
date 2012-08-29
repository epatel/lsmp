//
//  main.m
//  lsmp
//
//  Created by Edward Patel on 2012-08-29.
//  Copyright (c) 2012 Edward Patel. All rights reserved.
//

#import <Foundation/Foundation.h>

// Some return codes
enum {
    RETURN_WRONG_BUNDLE_ID = 101,
    RETURN_EXPIRED,
    RETURN_NO_PUSH
};

#define NSLog(FORMAT, ...) printf("%s\n", [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);

void print_usage_and_exit()
{
    printf("Usage: lsmp [ -b <bundle id> | -e | -p ] <filename>\n\n");
    printf("       -b <bundle id>  Check if bundle id is identical\n");
    printf("       -e              Check if profile has expired\n");
    printf("       -p              Check if push has been configured\n");
    exit(-1);
}

int main(int argc, const char * argv[])
{
    int returnValue = 0;

    @autoreleasepool {
        
        int i = 1;
        
        NSData *file = nil;
        
        const char *requiredBundleID = NULL;
        BOOL nonZeroExitOnDate = NO;
        BOOL nonZeroExitOnNoPush = NO;
        
        while (i < argc) {
            if (!strcmp("-b", argv[i])) {
                i++;
                requiredBundleID = argv[i];
            } else if (!strcmp("-e", argv[i])) {
                nonZeroExitOnDate = YES;
            } else if (!strcmp("-p", argv[i])) {
                nonZeroExitOnNoPush = YES;
            } else {
                file = [NSData dataWithContentsOfFile:[NSString stringWithCString:argv[i] encoding:NSUTF8StringEncoding]];
                if (!file ||
                    i+1 != argc)
                    print_usage_and_exit();
            }
            i++;
        }
        
        if (!file)
            print_usage_and_exit();
        
        const char *start = file.bytes;
        const char *end = start + file.length;
        
        while (start < end) {
            if (!memcmp("<?xml ", start, 6))
                break;
            start++;
        }
        
        if (start >= end) {
            printf("Missing profile content!\n");
            exit(-1);
        }
        
        const char *content_start = start;

        while (start < end) {
            if (!memcmp("</plist>", start, 8))
                break;
            start++;
        }

        if (start >= end) {
            printf("Missing profile content!\n");
            exit(-1);
        }

        NSData *content_part = [NSData dataWithBytes:content_start length:(start-content_start + 8)];

        NSPropertyListSerialization *plist = [NSPropertyListSerialization propertyListWithData:content_part
                                                                                       options:NSPropertyListImmutable
                                                                                        format:nil
                                                                                         error:nil];
                
        NSLog(@"Name:               %@", [plist valueForKey:@"Name"]);

        NSString *bundleID = [[[plist valueForKey:@"Entitlements"] valueForKey:@"application-identifier"] stringByReplacingCharactersInRange:NSMakeRange(0, 11) withString:@""];
        NSLog(@"Bundle ID:          %@", bundleID);
        
        if (!returnValue &&
            requiredBundleID &&
            [bundleID isEqualToString:[NSString stringWithUTF8String:requiredBundleID]] == NO)
            returnValue = RETURN_WRONG_BUNDLE_ID;

        NSLog(@"Creation Date:      %@", [plist valueForKey:@"CreationDate"]);
        NSLog(@"Expiration Date:    %@ %@",
              [plist valueForKey:@"ExpirationDate"],
              ([[NSDate date] timeIntervalSinceDate:[plist valueForKey:@"ExpirationDate"]] > 0.0) ? @"~~Has Expired~~" : @"");
        
        if (!returnValue &&
            nonZeroExitOnDate &&
            [[NSDate date] timeIntervalSinceDate:[plist valueForKey:@"ExpirationDate"]] > 0.0)
            returnValue = RETURN_EXPIRED;
        
        if ([[plist valueForKey:@"Entitlements"] valueForKey:@"aps-environment"]) {
            NSLog(@"Push Notifications: %@", [[plist valueForKey:@"Entitlements"] valueForKey:@"aps-environment"]);
        } else {
            NSLog(@"Push Notifications: ~~Not configured~~");
            if (!returnValue && nonZeroExitOnNoPush)
                returnValue = RETURN_NO_PUSH;
        }
                
    }
    
    return returnValue;
}

