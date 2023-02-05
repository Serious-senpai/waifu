import "package:async_locks/async_locks.dart";

import "cache.dart";
import "client.dart";

/// Images quality percentage when compressing from resmush.it
const reSmushCompressImageQualityPercentage = 40;

/// Images quality percentage when compressing locally
const compressImageQualityPercentage = 40;

/// Max concurrency for [UnfairSemaphore] inside [HTTPClient]
const httpClientMaxConcurrency = 4;

/// The [Duration] to hide system overlay after the user swipe
/// the screen borders
const hideSystemOverlayAfter = Duration(seconds: 4);

/// Initial maximum size of [ImageCache]
const initialImagesCacheSize = 100;
