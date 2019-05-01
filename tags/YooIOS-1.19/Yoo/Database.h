//
//  Database.h
//  CRMiPad
//
//  Created by Sy Pauv Phou on 3/30/11.
//  Copyright 2011 Fellow Consulting AG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import "Criteria.h"


#define DATABASE_NAME @"YOO.DB"

@interface Database : NSObject {
	sqlite3 *database;
    BOOL exists;
    
}

@property (nonatomic, readwrite) sqlite3 *database;
@property (nonatomic, readwrite) BOOL exists;

+ (Database *)getInstance;

- (void)initDatabase;
- (BOOL)execSql:(NSString *)sql params:(NSArray *)params;
- (NSArray *)selectSql:(NSString *)sql params:(NSArray *)params fields:(NSArray *)fields;
- (NSArray *)select:(NSString *)table fields:(NSArray *)fields criteria:(NSObject <Criteria> *)criteria limit:(int)limit order:(NSString *)order;
- (void)drop:(NSString *)table;
- (void)create:(NSString *)table columns:(NSDictionary *)columns;
- (BOOL)check:(NSString *)table columns:(NSDictionary *)columns;
- (BOOL)check:(NSString *)table columns:(NSDictionary *)columns dontwant:(NSArray *)toRemove;
- (void)createIndex:(NSString *)table columns:(NSArray *)columns unique:(BOOL)unique;
- (void)remove:(NSString *)table criteria:(NSObject<Criteria> *)criteria;
- (void)insert:(NSString *)table item:(NSDictionary *)item;
- (void)update:(NSString *)table item:(NSDictionary *)item criteria:(NSObject <Criteria> *)criteria;

@end

