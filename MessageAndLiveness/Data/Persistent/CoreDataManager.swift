//
//  CoreDataManager.swift
//  MessageAndLiveness
//
//  Created by Arifin Firdaus on 13/02/26.
//

import Foundation
import CoreData

/// A lightweight wrapper around `NSPersistentContainer` that configures
/// the Core Data stack with automatic lightweight migration support.
///
/// `CoreDataManager` is responsible for:
/// - Initializing the persistent container
/// - Enabling automatic lightweight migrations
/// - Loading persistent stores
/// - Providing access to main and background contexts
///
/// Usage:
/// ```swift
/// do {
///     let coreDataManager = try CoreDataManager(modelName: "YourModel")
///     let context = coreDataManager.context
/// } catch {
///     // Handle persistent store failure
///     print("Failed to initialize CoreDataManager:", error)
/// }
/// ```
final class CoreDataManager {
	
	/// The underlying persistent container that manages the Core Data stack.
	private let persistentContainer: NSPersistentContainer
	
	/// Creates a new CoreDataManager instance.
	///
	/// - Parameter modelName: The name of the `.xcdatamodeld` file (without extension).
	///   This must match the Core Data model included in the app bundle.
	///
	/// The initializer:
	/// - Configures lightweight migration
	/// - Loads persistent stores
	/// - Enables automatic merging from parent contexts
	///
	/// throw Error if the persistent store fails to load.
	init(modelName: String) throws {
		persistentContainer = NSPersistentContainer(name: modelName)
		setupLightweightMigration()
		
		var loadError: Error?
		
		persistentContainer.loadPersistentStores { _, error in
			loadError = error
		}
		
		if let error = loadError {
			throw error
		}
		
		persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
	}
	
	// MARK: - Contexts
	
	/// The main-thread managed object context.
	///
	/// Use this context for UI-related fetches and updates.
	var context: NSManagedObjectContext {
		persistentContainer.viewContext
	}
	
	/// Creates and returns a new background context.
	///
	/// Use this for heavy operations such as batch inserts,
	/// background imports, or large data processing tasks.
	///
	/// - Returns: A new `NSManagedObjectContext` configured for background use.
	func newBackgroundContext() -> NSManagedObjectContext {
		persistentContainer.newBackgroundContext()
	}
	
	/// Enables automatic lightweight migration for the persistent store.
	///
	/// This allows Core Data to automatically infer simple model changes
	/// such as:
	/// - Adding new attributes
	/// - Adding new entities
	/// - Renaming attributes (with proper renaming identifiers)
	///
	/// Complex schema changes still require a custom migration.
	private func setupLightweightMigration() {
		let description = persistentContainer.persistentStoreDescriptions.first
		description?.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
		description?.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
	}
}

