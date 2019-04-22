//
//  ServiceEasyLocatorTests.swift
//  ServiceContainerKitTests
//
//  Created by Vitalii Korotkii on 22/04/2019.
//  Copyright © 2019 ProVir. All rights reserved.
//

import XCTest
@testable import ServiceContainerKit

class ServiceEasyLocatorTests: XCTestCase {
    var serviceLocator = ServiceEasyLocator()

    override func tearDown() {
        serviceLocator = ServiceEasyLocator()
    }

    func testReadOnly() {
        serviceLocator.addService(ServiceSingleton())
        serviceLocator.setReadOnly(assertionFailure: false)

        serviceLocator.addService(factory: SpyServiceLazyFactory())
        doTestGetSuccessService(serviceLocator, ServiceSingleton.self)
        doTestGetNotFoundService(serviceLocator, ServiceLazy.self)

        serviceLocator.removeService(ServiceSingleton.self)
        doTestGetSuccessService(serviceLocator, ServiceSingleton.self)
    }

    func testClone() {
        serviceLocator.addService(ServiceSingleton())
        serviceLocator.setReadOnly()

        let serviceLocator2 = serviceLocator.clone()
        serviceLocator2.addService(factory: SpyServiceLazyFactory())

        guard let servcie1 = serviceLocator.getService(ServiceSingleton.self) else {
            XCTFail("Service not found")
            return
        }

        guard let servcie2 = serviceLocator2.getService(ServiceSingleton.self) else {
            XCTFail("Service not found")
            return
        }

        XCTAssert(servcie1 === servcie2, "Service singleton after clone also remains singleton")

        if serviceLocator.getService(ServiceLazy.self) != nil {
            XCTFail("Service not be found")
        }

        if serviceLocator2.getService(ServiceLazy.self) == nil {
            XCTFail("Service not found")
        }
    }

    func testAddServiceProvider() {
        let factorySingleton = SpyServiceSingletonFactory()
        let provider1 = factorySingleton.serviceProvider()
        serviceLocator.addService(provider: provider1)

        let factoryLazyError = SpyServiceLazyFactory(error: ServiceCreateError.someError)
        let provider2 = factoryLazyError.serviceProvider()
        serviceLocator.addService(provider: provider2)

        XCTAssertEqual(factorySingleton.callCount, 1, "Real create service need when create provider")
        XCTAssertEqual(factoryLazyError.callCount, 0, "Real create service when first needed")

        doTestGetSuccessService(serviceLocator, ServiceSingleton.self)
        doTestGetFailureService(serviceLocator, ServiceLazy.self)
        doTestGetNotFoundService(serviceLocator, ServiceMany.self)

        XCTAssertEqual(factorySingleton.callCount, 1)
        XCTAssertEqual(factoryLazyError.callCount, 1)

        doTestGetSuccessService(serviceLocator, ServiceSingleton.self)
        doTestGetFailureService(serviceLocator, ServiceLazy.self)

        XCTAssertEqual(factorySingleton.callCount, 1)
        XCTAssertEqual(factoryLazyError.callCount, 2,  "While the error repeats - try to re-create")
    }

    func testAddServiceParamsProvider() {
        let factory = SpyServiceParamsFactory()
        let provider = factory.serviceProvider()
        serviceLocator.addService(provider: provider)

        XCTAssertEqual(factory.callCount, 0, "Create service when needed")

        guard let service = serviceLocator.getService(ServiceParams.self,
                                                      params: ServiceParams.Params(value: "Test1", error: nil)) else {
                                                        XCTFail("Service not found")
                                                        return
        }

        XCTAssertEqual(factory.callCount, 1)
        XCTAssertEqual(service.value, "Test1")

        doTestGetErrorService(serviceLocator, ServiceParams.self, error: ServiceLocatorError.wrongParams)
        doTestGetNotFoundService(serviceLocator, ServiceSingleton.self)
    }

    func testAddServiceFactory() {
        let factorySingleton = SpyServiceSingletonFactory()
        serviceLocator.addService(factory: factorySingleton)

        let factoryLazyError = SpyServiceLazyFactory(error: ServiceCreateError.someError)
        serviceLocator.addService(factory: factoryLazyError)

        XCTAssertEqual(factorySingleton.callCount, 1, "Real create service need when create provider")
        XCTAssertEqual(factoryLazyError.callCount, 0, "Real create service when first needed")

        doTestGetSuccessService(serviceLocator, ServiceSingleton.self)
        doTestGetFailureService(serviceLocator, ServiceLazy.self)
        doTestGetNotFoundService(serviceLocator, ServiceMany.self)

        XCTAssertEqual(factorySingleton.callCount, 1)
        XCTAssertEqual(factoryLazyError.callCount, 1)

        doTestGetSuccessService(serviceLocator, ServiceSingleton.self)
        doTestGetFailureService(serviceLocator, ServiceLazy.self)

        XCTAssertEqual(factorySingleton.callCount, 1)
        XCTAssertEqual(factoryLazyError.callCount, 2,  "While the error repeats - try to re-create")
    }

    func testAddServiceParamsFactory() {
        let factory = SpyServiceParamsFactory()
        serviceLocator.addService(factory: factory)

        XCTAssertEqual(factory.callCount, 0, "Create service when needed")

        guard let service = serviceLocator.getService(ServiceParams.self,
                                                      params: ServiceParams.Params(value: "Test1", error: nil)) else {
                                                        XCTFail("Service not found")
                                                        return
        }

        XCTAssertEqual(factory.callCount, 1)
        XCTAssertEqual(service.value, "Test1")

        doTestGetErrorService(serviceLocator, ServiceParams.self, error: ServiceLocatorError.wrongParams)
        doTestGetNotFoundService(serviceLocator, ServiceSingleton.self)
    }

    func testAddServiceAsProtocol() {
        let factory = SpyServiceValueFactory<ServiceSingleton>.init(factoryType: .atOne)
        let provider = factory.serviceProvider()
        serviceLocator.addService(provider: provider)

        XCTAssertEqual(factory.callCount, 1, "Real create service need when create provider")

        doTestGetSuccessService(serviceLocator, ServiceValue.self)
        doTestGetNotFoundService(serviceLocator, ServiceSingleton.self)

        XCTAssertEqual(factory.callCount, 1)
    }

    func testAddServiceParamsAsProtocol() {
        let factory = SpyServiceParamsValueFactory()
        let provider = factory.serviceProvider()
        serviceLocator.addService(provider: provider)

        XCTAssertEqual(factory.callCount, 0, "Create service when needed")

        guard let service = serviceLocator.getService(ServiceParamsValue.self,
                                                      params: ServiceParams.Params(value: "Test1", error: nil)) else {
                                                        XCTFail("Service not found")
                                                        return
        }

        XCTAssertEqual(factory.callCount, 1)
        XCTAssertEqual(service.value, "Test1")

        doTestGetErrorService(serviceLocator, ServiceParamsValue.self, error: ServiceLocatorError.wrongParams)
        doTestGetNotFoundService(serviceLocator, ServiceParams.self)
    }

    func testAddServiceOptParamsProvider() {
        let factory = SpyServiceOptParamsFactory()
        let provider = factory.serviceProvider()
        serviceLocator.addService(provider: provider)

        XCTAssertEqual(factory.callCount, 0, "Create service when needed")

        guard let service1 = serviceLocator.getService(ServiceParams.self,
                                                       params: ServiceParams.Params(value: "Test1", error: nil)) else {
                                                        XCTFail("Service not found")
                                                        return
        }

        guard let service2 = serviceLocator.getService(ServiceParams.self) else {
            XCTFail("Service not found")
            return
        }

        XCTAssertEqual(factory.callCount, 2)
        XCTAssertEqual(service1.value, "Test1")
        XCTAssertEqual(service2.value, "Default")

        doTestGetSuccessService(serviceLocator, ServiceParams.self)
        doTestGetNotFoundService(serviceLocator, ServiceSingleton.self)

        XCTAssertEqual(factory.callCount, 3)
    }

    func testAddServiceSingletonService() {
        let service = ServiceSingleton()
        serviceLocator.addService(service)

        guard let serviceGet = serviceLocator.getService(ServiceSingleton.self) else {
            XCTFail("Service not found")
            return
        }

        service.value = "Test3"
        XCTAssertEqual(serviceGet.value, "Test3")
        XCTAssert(service === serviceGet)

        doTestGetSuccessService(serviceLocator, ServiceSingleton.self)
        doTestGetNotFoundService(serviceLocator, ServiceMany.self)
    }

    func testAddServiceLazyClosure() {
        var callCount = 0
        var errorClosure: Error? = ServiceCreateError.someError
        serviceLocator.addLazyService { () throws -> ServiceLazy in
            callCount += 1
            if let error = errorClosure {
                throw error
            } else {
                return ServiceLazy()
            }
        }

        XCTAssertEqual(callCount, 0, "Real create service when first needed")

        if serviceLocator.getService(ServiceLazy.self) != nil {
            XCTFail("Service need failure create")
        }

        XCTAssertEqual(callCount, 1, "Real create service when first needed")

        do {
            _ = try serviceLocator.tryService(ServiceLazy.self)
            XCTFail("Service need failure create")
        } catch {
            XCTAssert(error is ServiceCreateError)
        }

        XCTAssertEqual(callCount, 2, "While the error repeats - try to re-create")

        //Next without error
        errorClosure = nil
        guard let service1 = serviceLocator.getService(ServiceLazy.self) else {
            XCTFail("Service not exist")
            return
        }

        XCTAssertEqual(callCount, 3, "While the error repeats - try to re-create")

        service1.value = "Test1"
        guard let service2 = serviceLocator.getService(ServiceLazy.self) else {
            XCTFail("Service not exist")
            return
        }

        XCTAssertEqual(callCount, 3)
        XCTAssertEqual(service2.value,"Test1")

        service2.value = "Test2"
        XCTAssertEqual(service1.value, "Test2")
        XCTAssert(service1 === service2)

        doTestGetSuccessService(serviceLocator, ServiceLazy.self)
        doTestGetNotFoundService(serviceLocator, ServiceSingleton.self)
    }

    func testAddServiceManyClosure() {
        var callCount = 0
        var errorClosure: Error? = ServiceCreateError.someError
        serviceLocator.addService { () throws -> ServiceValue in
            callCount += 1
            if let error = errorClosure {
                throw error
            } else {
                return ServiceMany()
            }
        }

        XCTAssertEqual(callCount, 0, "Real create service when needed")

        if serviceLocator.getService(ServiceValue.self) != nil {
            XCTFail("Service need failure create")
        }

        XCTAssertEqual(callCount, 1, "Create service new with error")

        do {
            _ = try serviceLocator.tryService(ServiceValue.self)
            XCTFail("Service need failure create")
        } catch {
            XCTAssert(error is ServiceCreateError)
        }

        XCTAssertEqual(callCount, 2, "Create service new with error")

        //Next without error
        errorClosure = nil
        guard let service1 = serviceLocator.getService(ServiceValue.self) else {
            XCTFail("Service not exist")
            return
        }

        XCTAssertEqual(callCount, 3, "Create service new")

        service1.value = "Test1"
        guard let service2 = serviceLocator.getService(ServiceValue.self) else {
            XCTFail("Service not exist")
            return
        }

        XCTAssertEqual(callCount, 4)
        XCTAssertNotEqual(service2.value, "Test1")

        service2.value = "Test2"
        XCTAssertNotEqual(service1.value, "Test2")
        XCTAssert(service1 !== service2)

        doTestGetSuccessService(serviceLocator, ServiceValue.self)
        doTestGetNotFoundService(serviceLocator, ServiceMany.self)
    }

    func testRemoveServices() {
        serviceLocator.addService(factory: SpyServiceSingletonFactory())
        serviceLocator.addService(factory: SpyServiceLazyFactory())
        serviceLocator.addService(factory: SpyServiceManyFactory())

        doTestGetSuccessService(serviceLocator, ServiceSingleton.self)
        doTestGetSuccessService(serviceLocator, ServiceLazy.self)
        doTestGetSuccessService(serviceLocator, ServiceMany.self)

        serviceLocator.removeService(ServiceLazy.self)
        doTestGetSuccessService(serviceLocator, ServiceSingleton.self)
        doTestGetNotFoundService(serviceLocator, ServiceLazy.self)
        doTestGetSuccessService(serviceLocator, ServiceMany.self)

        serviceLocator.removeService(ServiceSingleton.self)
        doTestGetNotFoundService(serviceLocator, ServiceSingleton.self)
        doTestGetNotFoundService(serviceLocator, ServiceLazy.self)
        doTestGetSuccessService(serviceLocator, ServiceMany.self)

        serviceLocator.removeService(ServiceMany.self)
        doTestGetNotFoundService(serviceLocator, ServiceSingleton.self)
        doTestGetNotFoundService(serviceLocator, ServiceLazy.self)
        doTestGetNotFoundService(serviceLocator, ServiceMany.self)
    }

    func testAddServicesWithEqualTypes() {
        let service1 = ServiceSingleton()
        service1.value = "Test1"
        serviceLocator.addService(service1)
        if let service = serviceLocator.getService(ServiceSingleton.self) {
            XCTAssertEqual(service.value, "Test1")
            XCTAssert(service1 === service)
        } else {
            XCTFail("Not found service")
        }

        let service2 = ServiceSingleton()
        service2.value = "Test2"
        serviceLocator.addService(service2)
        if let service = serviceLocator.getService(ServiceSingleton.self) {
            XCTAssertEqual(service.value, "Test2")
            XCTAssert(service2 === service)
        } else {
            XCTFail("Not found service")
        }
    }

    func testServiceLocatorObjC() {
        let serviceLocatorObjC = ServiceEasyLocatorObjC(serviceLocator)

        serviceLocator.addService(factory: SpyServiceSingletonObjCFactory())
        serviceLocator.addService(factory: SpyServiceSingletonValueObjCFactory())

        let params = ServiceObjCParams(value: "Test1", error: nil)

        let service1: Any? = serviceLocatorObjC.getService(class: ServiceObjC.self)
        if (service1 as? ServiceObjC) == nil {
            XCTFail("Not found service")
        }

        let service2: Any? = serviceLocatorObjC.getService(protocol: ServiceValueObjC.self)
        if (service2 as? ServiceValueObjC) == nil {
            XCTFail("Not found service")
        }

        serviceLocator.addService(factory: SpyServiceParamsObjCFactory())
        serviceLocator.addService(factory: SpyServiceParamsValueObjCFactory())

        let service3: Any? = serviceLocatorObjC.getService(class: ServiceObjC.self, params: params)
        if (service3 as? ServiceObjC) == nil {
            XCTFail("Not found service")
        }

        let service4: Any? = serviceLocatorObjC.getService(protocol: ServiceValueObjC.self, params: params)
        if (service4 as? ServiceValueObjC) == nil {
            XCTFail("Not found service")
        }
    }
}

extension ServiceEasyLocatorTests {
    private func doTestGetSuccessService<ServiceType>(_ serviceLocator: ServiceEasyLocator, _ serviceType: ServiceType.Type, file: StaticString = #file, line: UInt = #line) {
        if serviceLocator.getService(ServiceType.self) == nil {
            XCTFail("Service not found", file: file, line: line)
        }
    }

    private func doTestGetFailureService<ServiceType>(_ serviceLocator: ServiceEasyLocator, _ serviceType: ServiceType.Type, file: StaticString = #file, line: UInt = #line) {
        doTestGetErrorService(serviceLocator, serviceType, error: ServiceCreateError.someError, file: file, line: line)
    }

    private func doTestGetNotFoundService<ServiceType>(_ serviceLocator: ServiceEasyLocator, _ serviceType: ServiceType.Type, file: StaticString = #file, line: UInt = #line) {
        doTestGetErrorService(serviceLocator, serviceType, error: ServiceLocatorError.serviceNotFound, file: file, line: line)
    }

    private func doTestGetErrorService<ServiceType, E: Error & Equatable>(_ serviceLocator: ServiceEasyLocator,  _ serviceType: ServiceType.Type, error errorService: E, file: StaticString = #file, line: UInt = #line) {
        do {
            _ = try serviceLocator.tryService(ServiceType.self)
            XCTFail("Service not be found", file: file, line: line)
        } catch {
            if let error = error as? E {
                XCTAssertEqual(error, errorService, file: file, line: line)
            } else {
                XCTFail("Unknown error \(error)", file: file, line: line)
            }
        }
    }
}
