//
//  CoreDataStack.swift
//  xkcd
//
//  Created by Paul Rehkugler on 1/24/16.
//
//

import CoreData

/// A class that sets up the Core Data stack used in the application.
final class CoreDataStack: NSObject {

    /// The directory where the application stores its documents.
    @objc var applicationsDocumentsDirectory: String

    /// The context where all of the Core Data objects are managed in the application.
    @objc var managedObjectContext: NSManagedObjectContext

    private var managedObjectModel: NSManagedObjectModel
    private var persistentStoreCoordinator: NSPersistentStoreCoordinator

    /// Holds the singleton returned by `sharedCoreDataStack()`.
    private static var sharedCoreDataStackStorage: CoreDataStack?

    /**
     A singleton Core Data stack instance that is used across the application.

     - note: Ideally we would use dependency injection instead of obfuscating the dependency graph like this.
     On the other hand, shipping is better than perfect.

     - returns: A fully initialized `CoreDataStack`.
     */
    @objc class func sharedCoreDataStack() -> CoreDataStack {
        if let coreDataStack = CoreDataStack.sharedCoreDataStackStorage {
            return coreDataStack
        }
        else {
            let coreDataStack = CoreDataStack()
            CoreDataStack.sharedCoreDataStackStorage = coreDataStack
            return coreDataStack
        }
    }

    /**
     Initializes a `CoreDataStack`.

     - returns: A fully initialized `CoreDataStack`.
     */
    override init() {
		let fileManager = FileManager.default
		guard let applicationsDocumentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, [.userDomainMask], true).first else {
            fatalError("Unable to get the applications documents directory.")
        }

		guard let managedObjectModel = NSManagedObjectModel.mergedModel(from: nil) else {
            fatalError("Unable to create a managed object model.")
        }

        // Clean up the old file from pervious versions
		let oldStorePath = (applicationsDocumentsDirectory as NSString).appendingPathComponent("xkcd.sqlite")
		if fileManager.fileExists(atPath: oldStorePath) {
            do {
				try fileManager.removeItem(atPath: oldStorePath)
            }
            catch let error as NSError {
                print("Error removing old SQLite file at \(oldStorePath): \(error.description)")
            }
        }

		let storePath = (applicationsDocumentsDirectory as NSString).appendingPathComponent("comics.sqlite")
		if !fileManager.fileExists(atPath: storePath) {
			if let bundledPath = Bundle.main.path(forResource: "comics", ofType: "sqlite") {
				if fileManager.fileExists(atPath: bundledPath) {
                    do {
						try fileManager.copyItem(atPath: bundledPath, toPath: storePath)
                    }
                    catch let error as NSError {
                        print("The SQLite database does not exist, and the sample one in the bundle is not able to be copied: \(error.description)")
                    }
                }
            }
        }

		let storeURL = NSURL.fileURL(withPath: storePath)
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
        do {
			try persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: nil)
			managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
            managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator
        }
        catch let error as NSError {
            fatalError("Unable to add the SQLite store to the persistent store coordinator: \(error.description)")
        }

        self.persistentStoreCoordinator = persistentStoreCoordinator
        self.applicationsDocumentsDirectory = applicationsDocumentsDirectory
        self.managedObjectModel = managedObjectModel

        super.init()

		NotificationCenter.default.addObserver(self, selector: #selector(UIApplicationDelegate.applicationWillTerminate(_:)), name: NSNotification.Name.UIApplicationWillTerminate, object: nil)
    }

    // MARK: - Saving

    /**
    Saves the managed object context.
    */
    @objc func save() {
		assert(Thread.isMainThread, "This Core Data stack only supports main thread concurrency.")

        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            }
            catch let error as NSError {
                print("Could not save CoreData changes: \(error.description)")
            }
        }
    }

    // MARK: - Notifications

    /**
    Called when the application will terminate. Do not call this directly.

    - parameter notification: The notification that triggered this method call.
    */
    @objc func applicationWillTerminate(notification: NSNotification) {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            }
            catch let error as NSError {
                print("Could not save CoreData changes: \(error.description)")
                exit(EXIT_FAILURE)
            }
        }
    }
}
