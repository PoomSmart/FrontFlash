#import <dlfcn.h>
#import "../PS.h"

%ctor
{
	if (isiOS9Up)
		dlopen("/Library/Application Support/FrontFlash/FrontFlashiOS9.dylib", RTLD_LAZY);
	else if (isiOS8)
		dlopen("/Library/Application Support/FrontFlash/FrontFlashiOS8.dylib", RTLD_LAZY);
	else if (isiOS7)
		dlopen("/Library/Application Support/FrontFlash/FrontFlashiOS7.dylib", RTLD_LAZY);
	else
		dlopen("/Library/Application Support/FrontFlash/FrontFlashiOS56.dylib", RTLD_LAZY);
}