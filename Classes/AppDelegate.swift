//
//  AppDelegate.swift
//  xkcd
//
//  Created by Paul Rehkugler on 1/24/16.
//
//

import UIKit

/// This class acts as the UIApplicationDelegate of the application.
final class AppDelegate: NSObject, UIApplicationDelegate {

    // MARK: - UIApplicationDelegate

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        MPulse.initializeWithAPIKey("INSERT API KEY HERE")
        let listViewController = ComicListViewController(style: .Plain)

        if let launchURL = launchOptions?[UIApplicationLaunchOptionsURLKey] as? NSURL {
            guard launchURL.scheme == "xkcd" else {
                return false
            }

            if
                let host = launchURL.host,
                let launchedComicNumber = Int(host)
                where launchedComicNumber > 0
            {
                listViewController.requestedLaunchComic = launchedComicNumber
            }
        }

        let navigationController = TLNavigationController(rootViewController: listViewController)

        window = UIWindow(frame: UIScreen.mainScreen().bounds)

        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()

        return true
    }

    func applicationDidBecomeActive(application: UIApplication) {
        Comic.synchronizeDownloadedImages()
    }
}
