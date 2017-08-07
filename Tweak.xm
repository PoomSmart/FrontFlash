#import <dlfcn.h>
#import "../PS.h"

%ctor {
    if (isiOS10Up)
        dlopen("/Library/MobileSubstrate/DynamicLibraries/FrontFlash/FrontFlashiOS10.dylib", RTLD_LAZY);
    else if (isiOS9)
        dlopen("/Library/MobileSubstrate/DynamicLibraries/FrontFlash/FrontFlashiOS9.dylib", RTLD_LAZY);
    else if (isiOS8)
        dlopen("/Library/MobileSubstrate/DynamicLibraries/FrontFlash/FrontFlashiOS8.dylib", RTLD_LAZY);
    else if (isiOS7)
        dlopen("/Library/MobileSubstrate/DynamicLibraries/FrontFlash/FrontFlashiOS7.dylib", RTLD_LAZY);
#if !__LP64__
    else
        dlopen("/Library/MobileSubstrate/DynamicLibraries/FrontFlash/FrontFlashiOS56.dylib", RTLD_LAZY);
#endif
}
