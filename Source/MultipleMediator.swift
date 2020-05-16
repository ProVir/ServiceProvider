//
//  MultipleMediator.swift
//  ServiceContainerKit
//
//  Created by Короткий Виталий on 08.05.2020.
//  Copyright © 2020 ProVir. All rights reserved.
//

import Foundation

public protocol MultipleMediatorToken: class { }

private protocol MultipleMediatorInternalToken: MultipleMediatorToken {
    func notify(_ entity: Any) -> Bool
}

public final class MultipleMediator {
    private var observers: [ObserverWrapper] = []
    
    public func notify<T>(_ entity: T) {
        observers = observers.filter { $0.handle(entity) }
    }
    
    public func notifySome(_ list: [Any]) {
        observers = observers.filter {
            for entity in list {
                if $0.handle(entity) == false {
                    return false
                }
            }
            return true
        }
    }
    
    public func observe<T>(_ type: T.Type, single: Bool, handler: @escaping (T) -> Void) -> MultipleMediatorToken {
        let token = Token(handler)
        observers.append(.init(token, single: single))
        return token
    }
    
    private final class Token<T>: MultipleMediatorInternalToken {
        private let handler: (T) -> Void
        
        init(_ handler: @escaping (T) -> Void) {
            self.handler = handler
        }
        
        func notify(_ entity: Any) -> Bool {
            if let entity = entity as? T {
                handler(entity)
                return true
            } else {
                return false
            }
        }
    }
    
    private final class ObserverWrapper {
        private let single: Bool
        private weak var token: MultipleMediatorInternalToken?
        
        init(_ token: MultipleMediatorInternalToken, single: Bool) {
            self.token = token
            self.single = single
        }
        
        func handle(_ entity: Any) -> Bool {
            guard let token = token else {
                return false
            }
            let isNotified = token.notify(entity)
            return single || isNotified == false
        }
    }
}