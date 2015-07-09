#import "TouchIDInfo.h"
#include <sys/sysctl.h>
#import <objc/runtime.h>
#import <dlfcn.h>

BOOL isTouchIDDevice(void) {
	dlopen("/System/Library/PrivateFrameworks/BiometricKit.framework/BiometricKit", RTLD_LAZY);
	Class bk = objc_getClass("BiometricKit");

    int sysctlbyname(const char *, void *, size_t *, void *, size_t);

    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);

    char *answer = (char *)malloc(size);
    sysctlbyname("hw.machine", answer, &size, NULL, 0);

    NSString *results = [NSString stringWithCString:answer encoding: NSUTF8StringEncoding];

    free(answer);

    NSArray *touchIDModels = @[ @"iPhone6,1", @"iPhone6,2", @"iPhone7,1", @"iPhone7,2", @"iPad5,3", @"iPad5,4", @"iPad4,7", @"iPad4,8", @"iPad4,9" ];

    return [touchIDModels containsObject:results] && [[[bk manager] identities:nil] count] > 0;
}