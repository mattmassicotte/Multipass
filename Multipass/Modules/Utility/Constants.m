@import Foundation;

#include <os/base.h>

#ifdef APP_GROUP
NSString* const MTPAppGroupIdentifier = @OS_STRINGIFY(APP_GROUP);
#else
#error Undefined
#endif

#ifdef APP_IDENTIFIER_PREFIX
NSString* const MTPAppIdentifierPrefix = @OS_STRINGIFY(APP_IDENTIFIER_PREFIX);
#else
#error Undefined
#endif
