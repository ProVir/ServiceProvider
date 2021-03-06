//
//  ViewController.swift
//  ServiceProviderExample
//
//  Created by Короткий Виталий on 04.06.2018.
//  Copyright © 2018 ProVir. All rights reserved.
//

import UIKit
import ServiceContainerKit
import ServiceInjects
import ExampleServiceLocators

struct SimpleKeyModel {
    @SLInject(ServiceLocatorKeys.firstService, lazy: true) var firstService
    @EntityInject(SimpleModel.self) var model
    @EntityInject(\SimpleModel.secondService) var secondService
    
    func test() {
        print("START TEST MODEL")
        firstService.test()
        
        print("START TEST Simple MODEL")
        model.test()
        secondService.test()
    }
}

struct SimpleModel {
    @SLSimpleInject(FirstService.self, lazy: true) var firstService
    @ServiceInject(\ServiceContainer.firstServiceProvider) var firstService2
    @ServiceParamsInject(
        \ServiceContainer.second.secondServiceProvider,
        params: .init(number: 9)
    ) var secondService
    
    func test() {
        print("START TEST MODEL")
        firstService.test()
        
        print("START TEST MODEL 2")
        firstService2.test()
        
        print("START TEST MODEL SECOND")
        secondService.test()
    }
}


class ViewController: UIViewController {
    @SLInject(ServiceLocatorKeys.firstService, lazy: false) var firstService
    @SLSimpleInject(FirstService.self, lazy: false) var firstService2
    @ServiceInject(\ServiceContainer.singletonServiceProvider) var singletonService
    
    var token: ServiceInjectReadyToken?
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        token = ServiceInjectResolver.addReadyContainerHandler(ServiceContainer.self) {
            print("ServiceContainer Ready")
        }
        
        $singletonService.setReadyHandler { service in
            print("SingletonService Maked")
            service.test()
        }
    }
    
    var serviceContainer: ServiceContainer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "objc", let vc = segue.destination as? ObjCViewController {
            vc.setup(withContainer: ServiceContainerObjC(container: serviceContainer))
        }
    }
    
    @IBAction func testContainer() {
        print("\n\nSTART TEST SERVICE CONTAINER")
        defer {
            print("\nSTOP TEST SERVICE CONTAINER\n")
        }
        
        print("\nCreate and test FirstService")
        let firstService = serviceContainer.firstServiceProvider.getServiceOrFatal()
        firstService.test()
        
        print("\n\nTest shared FirstService")
        let sharedService = serviceContainer.sharedFirstService
        sharedService.test()
        
        print("\n\nUpdate singleton value")
        let singletonService = serviceContainer.singletonServiceProvider.getServiceOrFatal()
        singletonService.value = "New Value from testContainer"
        
        firstService.test()
        sharedService.test()
        
        
        print("\n\nCreate and test SecondService with custom number (13)")
        let secondService = serviceContainer.secondServiceProvider.getServiceOrFatal(params: .init(number: 13))
        secondService.test()
        
        print("\n\nUpdate lazy value")
        let lazyService = serviceContainer.lazyServiceProvider.getServiceOrFatal()
        lazyService.value = "New Value in Lazy from testContainer"
        secondService.test()
        
        print("\n\nCreate and test SecondService with number = 0")
        let secondNum0Service = serviceContainer.secondServiceNumber0Provider.getServiceOrFatal()
        secondNum0Service.test()

        
        print("\n\nWeak service")
        var weakService = serviceContainer.weakServiceProvider.getServiceAsOptional()
        weakService?.value = "ONE"
        weakService?.test()
        
        serviceContainer.weakServiceProvider.getServiceOrFatal().test()
        
        weakService = nil
        weakService = serviceContainer.weakServiceProvider.getServiceAsOptional()
        weakService?.test()
        
        print("\n\nWeak service with session")
        var weakService1 = serviceContainer.sessionWeakServiceProvider.getServiceAsOptional()
        weakService1?.test()
        
        
        print("\n\nCreate and test SingletonService with UserSession")
        let service1 = serviceContainer.sessionSingletonServiceProvider.getServiceOrFatal()
        service1.test()

        serviceContainer.userMediator.updateSession(.init(userId: 0))
        let service2 = serviceContainer.sessionSingletonServiceProvider.getServiceOrFatal()
        service2.test()

        serviceContainer.userMediator.updateSession(.init(userId: 5))
        let service3 = serviceContainer.sessionSingletonServiceProvider.getServiceOrFatal()
        service3.test()
        
        var weakService2 = serviceContainer.sessionWeakServiceProvider.getServiceAsOptional()
        weakService2?.test()
        serviceContainer.sessionWeakServiceProvider.getServiceAsOptional()?.test()

        serviceContainer.userMediator.updateSession(.init(userId: 0))
        let service4 = serviceContainer.sessionSingletonServiceProvider.getServiceOrFatal()
        service4.test()
        service3.test()
        
        var weakService3 = serviceContainer.sessionWeakServiceProvider.getServiceAsOptional()
        weakService3?.test()

        if service1 === service2 {
            print("\nSUCCESS")
        } else {
            print("\nFAILURE Service1 !== Service2")
        }

        if service2 !== service3 {
            print("\nSUCCESS")
        } else {
            print("\nFAILURE Service2 === Service3")
        }

        if service2 === service4 {
            print("\nSUCCESS")
        } else {
            print("\nFAILURE Service2 !== Service4")
        }
        
        if weakService1 === weakService3 {
            print("\nSUCCESS")
        } else {
            print("\nFAILURE WeakService1 !== WeakService3")
        }
        
        weakService1 = nil
        weakService2 = nil
        weakService3 = nil

        print("\n\nAll experiments completed, removed all services created in current function.")
        
        self.singletonService.test()
    }
    
    @IBAction func testKeyLocator() {
        print("\n\nSTART TEST SERVICE LOCATOR WITH KEYS")
        defer {
            print("\nSTOP TEST SERVICE LOCATOR WITH KEYS\n")
        }
        
        let serviceLocator = ServiceLocator.createDefault()
        print("CREATED SERVICE LOCATOR WITH SERVICES\n")
        
        print("\nCreate and test FirstService")
        let firstService = serviceLocator.getServiceOrFatal(key: ServiceLocatorKeys.firstService)
        firstService.test()
        
        print("\n\nTest shared FirstService")
        let sharedService = serviceLocator.getServiceOrFatal(key: ServiceLocatorKeys.firstServiceShared)
        sharedService.test()
        
        print("\n\nUpdate singleton value - use variant 2 for key")
        let singletonService = serviceLocator.getServiceOrFatal(key: SingletonServiceLocatorKey())
        singletonService.value = "New Value from testLocator"
        
        firstService.test()
        sharedService.test()
        
        
        print("\n\nCreate and test SecondService with custom number (101)")
        let secondService = serviceLocator.getServiceOrFatal(key: ServiceLocatorKeys.secondService,
                                                             params: SecondServiceParams(number: 101))
        secondService.test()
        
        print("\n\nUpdate lazy value - use variant 3 for key")
        let lazyService = serviceLocator.getServiceOrFatal(key: LazyService.locatorKey)
        lazyService.value = "New Value in Lazy from testLocator"
        secondService.test()
        
        print("\n\nCreate and test SecondService with default number (without params)")
        let secondNumDefService = serviceLocator.getServiceOrFatal(key: ServiceLocatorKeys.secondService)
        secondNumDefService.test()
        
        print("\n\nAll experiments completed, removed all services created in current function.")
        
        let model = SimpleKeyModel()
        model.test()
    }
    
    @IBAction func testLocator() {
        print("\n\nSTART TEST SERVICE EASY LOCATOR")
        defer {
            print("\nSTOP TEST SERVICE EASY LOCATOR\n")
        }
        
        guard let serviceLocator = ServiceSimpleLocator.shared else { return }
        
        print("\nCreate and test FirstService")
        let firstService: FirstService = serviceLocator.getServiceOrFatal()
        firstService.test()
        
        print("\n\nTest shared FirstService (for get used protocol)")
        let sharedService = serviceLocator.getServiceOrFatal(FirstServiceShared.self) as! FirstService
        sharedService.test()
        
        print("\n\nUpdate singleton value")
        let singletonService: SingletonService = serviceLocator.getServiceOrFatal()
        singletonService.value = "New Value from testLocator"
        
        firstService.test()
        sharedService.test()
        
        
        print("\n\nCreate and test SecondService with custom number (101)")
        let secondService: SecondService = serviceLocator.getServiceOrFatal(params: SecondServiceParams(number: 101))
        secondService.test()
        
        print("\n\nUpdate lazy value")
        let lazyService: LazyService = serviceLocator.getServiceOrFatal()
        lazyService.value = "New Value in Lazy from testLocator"
        secondService.test()
        
        print("\n\nCreate and test SecondService with default number (without params)")
        let secondNumDefService: SecondService = serviceLocator.getServiceOrFatal()
        secondNumDefService.test()
        
        print("\n\nAll experiments completed, removed all services created in current function.")
        
        
        let model = SimpleModel()
        model.test()
    }
}
