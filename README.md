This is a fork of [paulrehkugler/xkcd](https://github.com/paulrehkugler/xkcd), used as a demonstration of SOASTA mPulse for iOS.  To insert your own mPulse API key, edit the `AppDelegate.swift` file, line 19:

```swift
MPulse.initializeWithAPIKey("INSERT API KEY HERE")
```

and insert your own API key.

In addition to measuring all network traffic, this demo also includes a custom timer for measuring the render time of anindividual comics, and a custom metric tracking how often people share links.
