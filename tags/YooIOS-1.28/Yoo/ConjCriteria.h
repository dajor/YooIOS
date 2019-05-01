//
//  AndCriteria.h
//
//  Created by Arnaud on 13/05/13.
//

#import <Foundation/Foundation.h>
#import "Criteria.h"

typedef NS_ENUM(NSInteger, ConjunctionType) {
    conjAND,
    conjOR
};

@interface ConjCriteria: NSObject<Criteria> {
    NSMutableArray *criterias;
    ConjunctionType conj;
}

@property (nonatomic, retain) NSMutableArray *criterias;
@property (assign) ConjunctionType conj;

- (id)initWithConjuction:(ConjunctionType)pConj;

@end
