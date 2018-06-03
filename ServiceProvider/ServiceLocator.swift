//
//  ServiceLocator.swift
//  ServiceProvider 1.0.0
//
//  Created by Короткий Виталий (ViR) on 04.06.2018.
//  Copyright © 2018 ProVir. All rights reserved.
//

import Foundation

///Errors for ServiceLocator
public enum ServiceLocatorError: Error {
    case serviceNotFound
    case sharedRequireSetup
}


/// ServiceLocator as storage ServiceProviders.
open class ServiceLocator {
    public private(set) static var shared: ServiceLocator?
    
    public required init() { }
    
    ///Use for all public methods
    public let lock = NSRecursiveLock()
    public private(set) var readOnly: Bool = false
    
    private var providers = [String : ServiceLocatorProviderBinding]()
    
    
    //MARK: Get
    public static func tryServiceFromShared<T>(settings: ServiceFactorySettings? = nil) throws -> T {
        guard let shared = shared else {
            throw ServiceLocatorError.sharedRequireSetup
        }
        
        return try shared.tryService(settings: settings)
    }
    
    public static func getServiceFromShared<T>(settings: ServiceFactorySettings? = nil) -> T? {
        guard let shared = shared else { return nil }
        return try? shared.tryService(settings: settings)
    }
    
    
    public func tryService<T>(settings: ServiceFactorySettings? = nil) throws -> T {
        lock.lock()
        defer { lock.unlock() }
        
        let typeName = "\(T.self)"
        
        if let provider = providers[typeName] {
            return try provider.tryServiceBinding(settings: settings)
        } else {
            throw ServiceLocatorError.serviceNotFound
        }
    }
    
    public func getService<T>(settings: ServiceFactorySettings? = nil) -> T? {
        return try? tryService(settings: settings)
    }
    
    public func getServiceProvider<T>() -> ServiceProvider<T>? {
        lock.lock()
        defer { lock.unlock() }
        
        let typeName = "\(T.self)"
        return providers[typeName] as? ServiceProvider<T>
    }
    
    
    //MARK: Setup
    public static func setupShared(serviceLocator: ServiceLocator) {
        shared = serviceLocator
    }
    
    public func setReadOnly() {
        lock.lock()
        readOnly = true
        lock.unlock()
    }
    
    public func addService<T>(provider: ServiceProvider<T>) {
        lock.lock()
        defer { lock.unlock() }
        
        if readOnly { fatalError("Don't support addService in readOnly regime") }
        
        let typeName = "\(T.self)"
        providers[typeName] = provider
    }
    
    public func addService<T>(_ service: T) {
        addService(provider: ServiceProvider<T>(service))
    }
    
    public func addService<T, FactoryType: ServiceFactory>(factory: FactoryType) where FactoryType.TypeService == T {
        addService(provider: ServiceProvider<T>(factory: factory))
    }
    
    public func addService<T>(lazy:@escaping () throws ->T) {
        addService(provider: ServiceProvider<T>(lazy: lazy))
    }
    
    public func addService<T>(factory closure:@escaping (ServiceFactorySettings?) throws ->T) {
        addService(provider: ServiceProvider<T>.init(factory: closure))
    }
    
    public func removeService<T>(serviceType: T.Type) {
        lock.lock()
        defer { lock.unlock() }
        
        if readOnly { fatalError("Don't support removeService in readOnly regime") }
        
        providers.removeValue(forKey: "\(T.self)")
    }
    
    public func clone<T: ServiceLocator>(type: T.Type = T.self) -> T {
        let locator = T.init()
        
        lock.lock()
        locator.providers = self.providers
        lock.unlock()
        
        return locator
    }
}


//MARK: - Provider binding to Locator

/// Base protocol for ServiceProvider<T>
fileprivate protocol ServiceLocatorProviderBinding {
    func tryServiceBinding<T>(settings: ServiceFactorySettings?) throws -> T
}

extension ServiceProvider: ServiceLocatorProviderBinding {
    fileprivate func tryServiceBinding<BT>(settings: ServiceFactorySettings?) throws -> BT {
        if let service = try tryService(settings: settings) as? BT {
            return service
        } else {
            throw ServiceLocatorError.serviceNotFound
        }
    }
}

