//
//  FirstServiceFactory.swift
//  Example
//
//  Created by Короткий Виталий on 28.06.2018.
//  Copyright © 2018 ProVir. All rights reserved.
//

import Foundation
import ServiceContainerKit

extension FirstServiceFactory {
    static var defaultKey: FirstServiceLocatorKey { return .init(isShared: false) }
    static var sharedKey: FirstServiceLocatorKey { return .init(isShared: true) }
}

struct FirstServiceFactory: ServiceFactory {
    let singletonServiceProvider: ServiceProvider<SingletonService>
    
    let factoryType: ServiceFactoryType = .many
    func makeService() throws -> FirstService {
        return FirstService(singletonService: try singletonServiceProvider.tryService())
    }
}

struct FirstServiceLocatorKey: ServiceLocatorKey {
    typealias ServiceType = FirstService
    
    let isShared: Bool
    var storeKey: String {
        return isShared ? "FirstServiceShared" : "FirstService"
    }
}
