#import "../PS.h"
#import <dlfcn.h>

%ctor
{
	if (isiOS8Up)
		dlopen("/Library/Application Support/FrontFlash/FrontFlashiOS8.dylib", RTLD_LAZY);
	else if (isiOS7)
		dlopen("/Library/Application Support/FrontFlash/FrontFlashiOS7.dylib", RTLD_LAZY);
	else
		dlopen("/Library/Application Support/FrontFlash/FrontFlashiOS456.dylib", RTLD_LAZY);
}
