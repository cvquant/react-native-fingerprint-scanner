#import "ReactNativeFingerprintScanner.h"

#if __has_include(<React/RCTUtils.h>) // React Native >= 0.40
#import <React/RCTUtils.h>
#else // React Native < 0.40
#import "RCTUtils.h"
#endif

#import <LocalAuthentication/LocalAuthentication.h>

@implementation ReactNativeFingerprintScanner

RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(isSensorAvailable: (RCTResponseSenderBlock)callback)
{
    LAContext *context = [[LAContext alloc] init];
    NSError *error;

    if ([context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error]) {
        callback(@[[NSNull null]]);
    } else {
        // Device does not support FingerprintScanner
        [self handleError:error callback:callback];
        return;
    }
}

RCT_EXPORT_METHOD(sensorType: (RCTResponseSenderBlock)callback)
{
    LAContext *context = [[LAContext alloc] init];
    NSError *error;
    NSString *biometryType;
    if ([context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error]) {
        if (@available(iOS 11.0, *)) {
            switch (context.biometryType) {
                case LABiometryTypeFaceID:
                    biometryType = @"FaceID";
                    break;
                case LABiometryTypeTouchID:
                    biometryType = @"TouchID";
                    break;
                default:
                    biometryType = @"None";
                    break;
            }
        } else {
            biometryType = @"TouchID";
        }
        callback(@[[NSNull null], biometryType]);
    } else if (error.code == LAErrorTouchIDNotEnrolled){
        if([[UIDevice currentDevice]userInterfaceIdiom]==UIUserInterfaceIdiomPhone) {
            switch ((int)[[UIScreen mainScreen] nativeBounds].size.height) {
                case 2436:
                    // iphoneX
                    biometryType = @"FaceID";
                    break;
                default:
                    // all other
                    biometryType = @"TouchID";
            }
        } else {
            biometryType = @"TouchID";
        }
        callback(@[[NSNull null], biometryType]);
    } else {
        // Device does not support FingerprintScanner
        [self handleError:error callback:callback];
        return;
    }
}

RCT_EXPORT_METHOD(authenticate: (NSString *)reason
                  fallback: (BOOL)fallbackEnabled
                  callback: (RCTResponseSenderBlock)callback)
{
    LAContext *context = [[LAContext alloc] init];
    NSError *error;

    // Toggle fallback button
    if (!fallbackEnabled) {
        context.localizedFallbackTitle = @"";
    }

    // Device has FingerprintScanner
    if ([context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error]) {
        // Attempt Authentication
        [context evaluatePolicy:LAPolicyDeviceOwnerAuthentication
                localizedReason:reason
                          reply:^(BOOL success, NSError *error)
        {
            // Failed Authentication
            if (error) {
                [self handleError:error callback:callback];
                return;
            }

            if (success) {
                // Authenticated Successfully
                callback(@[[NSNull null], @"Authenticated with Fingerprint Scanner."]);
                return;
            }
            [self handleError:error callback:callback];
        }];

    } else {
        // Device does not support FingerprintScanner
        [self handleError:error callback:callback];
        return;
    }
}

- (void) handleError: (NSError*)error
            callback:(RCTResponseSenderBlock)callback {
    NSString *errorReason = [self switchError:error];
    NSLog(@"Authentication failed: %@", errorReason);
    callback(@[RCTMakeError(errorReason, nil, nil)]);
}

- (NSString*) switchError: (NSError*) error {
    NSString *errorReason;

    switch (error.code) {
        case LAErrorAuthenticationFailed:
            errorReason = @"AuthenticationFailed";
            break;

        case LAErrorUserCancel:
            errorReason = @"UserCancel";
            break;

        case LAErrorUserFallback:
            errorReason = @"UserFallback";
            break;

        case LAErrorSystemCancel:
            errorReason = @"SystemCancel";
            break;

        case LAErrorPasscodeNotSet:
            errorReason = @"PasscodeNotSet";
            break;

        case LAErrorTouchIDNotAvailable:
            errorReason = @"FingerprintScannerNotAvailable";
            break;

        case LAErrorTouchIDNotEnrolled:
            errorReason = @"FingerprintScannerNotEnrolled";
            break;

        default:
            errorReason = @"FingerprintScannerUnknownError";
            break;
    }
    return errorReason;
}

@end
