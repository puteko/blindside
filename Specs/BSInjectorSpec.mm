#import <Cedar/SpecHelper.h>
#import "BSModule.h"
#import "BSInjector.h"
#import "Fixtures.h"
#import "BSSingleton.h"

using namespace Cedar::Matchers;

SPEC_BEGIN(BSInjectorSpec)
describe(@"BSInjector", ^{
    __block BSModule *module;
    __block BSInjector *injector;

    beforeEach(^{
        module = [BSModule module];
        injector = [[[BSInjector alloc] initWithModule:module] autorelease];
    }); 

    it(@"can bind an instance to a class", ^{
        NSString *instance = @"foo";
        [module bind:[NSObject class] toInstance:instance];
        id object = [injector getInstance:[NSObject class]];
        expect(object == instance).to(equal(YES));
    });

    it(@"can bind an instance to a string", ^{
        NSString *instance = @"foo";
        [module bind:@"key" toInstance:instance];
        id object = [injector getInstance:@"key"];
        expect(object == instance).to(equal(YES));
    });

    describe(@"building an object whose class has a blindsideInitializer", ^{
        it(@"resolves first-order dependencies", ^{
            Address *address = [[[Address alloc] init] autorelease];
            [module bind:[Address class] toInstance:address];
            House *house = [injector getInstance:[House class]];
            expect(house).to_not(be_nil());
            expect(house.address).to_not(be_nil());
        });

        context(@"when the initializer has more than two arguments", ^{
            it(@"injects all the arguments", ^{
                NSString *street = @"123 Market St.";
                City *city = [[[City alloc] init] autorelease];
                State *state = [[[State alloc] init] autorelease];
                NSString *zip = @"94110";
                
                [module bind:@"street" toInstance:street];
                [module bind:@"city"   toInstance:city];
                [module bind:@"state"  toInstance:state];
                [module bind:@"zip"    toInstance:zip];
                
                Address *address = [injector getInstance:[Address class]];
                
                expect(address.street == street).to(equal(YES));
                expect(address.city   == city).to(equal(YES));
                expect(address.state  == state).to(equal(YES));
                expect(address.zip    == zip).to(equal(YES));
            });
            
            context(@"when some argument keys have no bound values", ^{
                it(@"injects nil", ^{
                    NSString *street = @"123 Market St.";
                    City *city = [[[City alloc] init] autorelease];
                    
                    [module bind:@"street" toInstance:street];
                    [module bind:@"city"   toInstance:city];
                    
                    Address *address = [injector getInstance:[Address class]];
                    
                    expect(address.street == street).to(equal(YES));
                    expect(address.city   == city).to(equal(YES));
                    expect(address.state).to(be_nil);
                    expect(address.zip).to(be_nil);                    
                });
            });
        });

        context(@"when the class also has blindsideProperties", ^{
            __block Garage *garage;
            __block Driveway *driveway;

            beforeEach(^{
                garage = [[[Garage alloc] init] autorelease];
                [module bind:[Garage class] toInstance:garage];

                driveway = [[[Driveway alloc] init] autorelease];
                [module bind:@"theDriveway" toInstance:driveway];
            });

            it(@"injects the properties", ^{
                House *house = [injector getInstance:[House class]];
                expect(house.garage == garage).to(equal(YES));
                expect(house.driveway == driveway).to(equal(YES));
            });

            xit(@"injects superclass properties too", ^{
                TennisCourt *tennisCourt = [[[TennisCourt alloc] init] autorelease];
                [module bind:[TennisCourt class] toInstance:tennisCourt];

                Mansion *mansion = [injector getInstance:[Mansion class]];
                expect(mansion.tennisCourt == tennisCourt).to(equal(YES));
                expect(mansion.garage == garage).to(equal(YES));
                expect(mansion.driveway == driveway).to(equal(YES));
            });
        });
    });
    
    it(@"binds to blocks", ^{
        __block Garage *garage;

        garage = [[[Garage alloc] init] autorelease];
        [module bind:[Garage class] toBlock:^{
            return garage;
        }];

        House *house = [injector getInstance:[House class]];
        expect(house.garage == garage).to(equal(YES));
    });
    
    describe(@"binding to classes", ^{
        context(@"when the class has a blindside initializer", ^{
            it(@"builds the class with the blindside initializer", ^{
                [module bind:@"expensivePurchase" toClass:[House class]];
                id expensivePurchase = [injector getInstance:@"expensivePurchase"];
                expect([expensivePurchase class]).to(equal([House class]));
            });
        });

        context(@"when the class has a default initializer but no blindside initializer", ^{
            xit(@"builds the class with the default initializer", ^{

            });
        });

        context(@"when the class has no blindside initializer nor default initializer", ^{
            xit(@"raises", ^{

            });
        });
    });
    
    describe(@"scoping", ^{
        describe(@"singleton", ^{
            it(@"uses the same instance for all injection points", ^{
                [module bind:[House class] withScope:[BSSingleton scope]];
                House *house1 = [injector getInstance:[House class]];
                House *house2 = [injector getInstance:[House class]];
                expect(house1 == house2).to(equal(YES));
            });
        });

        describe(@"unscoped", ^{
            it(@"uses a different instance for each injection point", ^{
                House *house1 = [injector getInstance:[House class]];
                House *house2 = [injector getInstance:[House class]];
                expect(house1 == house2).to(equal(NO));
            });
        });
    });
});
SPEC_END