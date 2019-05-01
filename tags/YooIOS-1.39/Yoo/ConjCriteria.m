//
//  AndCriteria.m
//
//  Created by Arnaud on 13/05/13.
//

#import "ConjCriteria.h"

@implementation ConjCriteria

@synthesize criterias, conj;

- (id)initWithConjuction:(ConjunctionType)pConj {
    self = [super init];
    self.conj = pConj;
    self.criterias = [[NSMutableArray alloc] initWithCapacity:1];
    return self;
}

- (NSString *)toSql {
    NSMutableString *sql = [NSMutableString stringWithString:@"("];
    for (NSObject <Criteria> *criteria in criterias) {
        if ([sql length] > 1) {
            [sql appendString:self.conj == conjAND ? @" AND " : @" OR "];
        }
        [sql appendString:[criteria toSql]];
    }
    [sql appendString:@")"];
    return sql;
}

- (NSArray *)getParams {
    NSMutableArray *params = [[NSMutableArray alloc] initWithCapacity:1];
    for (NSObject <Criteria> *criteria in criterias) {
        [params addObjectsFromArray:[criteria getParams]];
    }
    return params;
}

@end
