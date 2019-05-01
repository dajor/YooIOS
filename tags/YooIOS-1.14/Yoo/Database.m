//
//  Database.m
//  CRMiPad
//
//  Created by Sy Pauv Phou on 3/30/11.
//  Copyright 2011 Fellow Consulting AG. All rights reserved.
//

#import "Database.h"

@implementation Database

static Database *_sharedSingleton = nil;

@synthesize database, exists;

+ (Database *)getInstance
{
	@synchronized([Database class])
	{
		if (!_sharedSingleton) {
			Database *db = [[self alloc] init];
            if (db == nil) {
                NSLog(@"Error obtaining instance");
            }
        }
		return _sharedSingleton;
	}
    
	return nil;
}

+ (id)alloc
{
	@synchronized([Database class])
	{
		NSAssert(_sharedSingleton == nil, @"Attempted to allocate a second instance of a singleton.");
		_sharedSingleton = [super alloc];
		return _sharedSingleton;
	}
    
	return nil;
}

- (void) dealloc
{
    if (database != NULL) {
        sqlite3_close(database);
    }
}

- (id)init {
    self = [super init];
    return self;
}


- (void)initDatabase {
    
	// Get the path to the documents directory and append the databaseName
	NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDir = [documentPaths objectAtIndex:0];
	NSString *databasePath = [documentsDir stringByAppendingPathComponent:DATABASE_NAME];
    
    
    
	// Create a FileManager object, we will use this to check the status
	// of the database and to copy it over if required
	NSFileManager *fileManager = [NSFileManager defaultManager];
    
	// Check if the database has already been created in the users filesystem
	exists = [fileManager fileExistsAtPath:databasePath];
    
	// Open the database from the users filessytem
	if(sqlite3_open([databasePath UTF8String], &database) != SQLITE_OK) {
        NSLog(@"Error opening database");
    }
    
}



- (BOOL)execSql:(NSString *)sql params:(NSArray *)params {
    
    NSLog(@"SQL :%@", [Database setParameters:sql params:params]);
    @synchronized([Database class]) {
        sqlite3_stmt *compiledStatement;
        int result = sqlite3_prepare_v2(database, [sql cStringUsingEncoding:NSUTF8StringEncoding], -1, &compiledStatement, NULL);
        if (result != SQLITE_OK) {
            NSLog(@"SQL Error : %i %s", result, sqlite3_errmsg(database));
            return NO;
        }
        if (params != Nil) {
            for (int i = 0; i < [params count]; i++) {
                if ([[params objectAtIndex:i] isKindOfClass:[NSNumber class]]) {
                    sqlite3_bind_int64(compiledStatement, i+1, [[params objectAtIndex:i] longLongValue]);
                } else if ([[params objectAtIndex:i] isKindOfClass:[NSData class]]) {
                    NSData *data = [params objectAtIndex:i];
                    sqlite3_bind_blob(compiledStatement, i+1, [data bytes], (int)[data length], SQLITE_TRANSIENT);
                } else if ([[params objectAtIndex:i] isKindOfClass:[NSNull class]]) {
                    sqlite3_bind_null(compiledStatement, i+1);
                } else {
                    sqlite3_bind_text(compiledStatement, i+1, [[params objectAtIndex:i] cStringUsingEncoding:NSUTF8StringEncoding], -1, SQLITE_TRANSIENT);
                }
                
            }
        }
        result = sqlite3_step(compiledStatement);
        if (result != SQLITE_DONE) {
            NSLog(@"SQL Error : %i %s", result, sqlite3_errmsg(database));
            return NO;
        }
        sqlite3_finalize(compiledStatement);
    }
    return YES;
}


- (NSArray *)selectSql:(NSString *)sql params:(NSArray *)params fields:(NSArray *)fields {
    NSLog(@"SQL :%@", [Database setParameters:sql params:params]);
    NSMutableArray *list = nil;
    @synchronized([Database class]) {
        sqlite3_stmt *compiledStatement;
        int result = sqlite3_prepare_v2(database, [sql cStringUsingEncoding:NSUTF8StringEncoding], -1, &compiledStatement, NULL);
        if (params != Nil) {
            for (int i = 0; i < [params count]; i++) {
                sqlite3_bind_text(compiledStatement, i+1, [[params objectAtIndex:i] cStringUsingEncoding:NSUTF8StringEncoding], -1, SQLITE_TRANSIENT);
            }
        }
        if (result == SQLITE_OK) {
            list = [[NSMutableArray alloc] initWithCapacity:1];
            // Loop through the results and add them to the feeds array
            while (sqlite3_step(compiledStatement) == SQLITE_ROW) {
                NSMutableDictionary *record = [[NSMutableDictionary alloc] initWithCapacity:1];
                for (int i = 0; i < sqlite3_column_count(compiledStatement); i++) {
                    NSString *field = [fields objectAtIndex:i];
                    if (sqlite3_column_type(compiledStatement, i) == SQLITE_NULL) {
                    } else if (sqlite3_column_type(compiledStatement, i) == SQLITE_BLOB) {
                        NSData *data = [NSData dataWithBytes:sqlite3_column_blob(compiledStatement, i) length:sqlite3_column_bytes(compiledStatement, i)];
                        [record setObject:data forKey:field];
                    } else if (sqlite3_column_type(compiledStatement, i) == SQLITE_TEXT) {
                        NSString *value = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement, i)];
                        [record setObject:value forKey:field];
                    } else {
                        NSString *value = [NSString stringWithFormat:@"%i", sqlite3_column_int(compiledStatement, i)];
                        [record setObject:value forKey:field];
                    }
                }
                [list addObject:record];
            }
        } else {
            NSLog(@"SQL Error : %i %s", result, sqlite3_errmsg(database));
            list = nil;
        }
        // Release the compiled statement from memory
        sqlite3_finalize(compiledStatement);
    }
    return list;
}


- (BOOL)check:(NSString *)table columns:(NSDictionary *)columns {
    return [self check:table columns:columns dontwant:nil];
}


- (BOOL)check:(NSString *)table columns:(NSDictionary *)columns dontwant:(NSArray *)toRemove {
    // check if need to remove some columns
    if (toRemove != nil) {
        BOOL ok = YES;
        for (NSString *colToRemove in toRemove) {
            NSArray *tmp = [NSArray arrayWithObject:colToRemove];
            NSArray *rows2 = [self select:table fields:tmp criteria:nil limit:1 order:nil];
            if (rows2 != nil) {
                ok = NO;
                break;
            }
        }
        if (!ok) {
            [self drop:table];
            [self create:table columns:columns];
            return NO;
        }
    }
    // check if all rows are here
    NSArray *rows = [self select:table fields:[columns allKeys] criteria:nil limit:1 order:nil];
    if (rows == nil) {
        // some rows are missing, find out which ones
        NSMutableArray *missing = [[NSMutableArray alloc] initWithCapacity:1];
        NSArray *columnNames = [columns allKeys];
        for (int i = 0; i < [columnNames count]; i++) {
            NSArray *tmp = [NSArray arrayWithObject:[columnNames objectAtIndex:i]];
            NSArray *rows2 = [self select:table fields:tmp criteria:nil limit:1 order:nil];
            if (rows2 == nil) {
                [missing addObject:[columnNames objectAtIndex:i]];
            }
        }
        if ([missing count] == [columns count]) {
            [self drop:table];
            [self create:table columns:columns];
            return NO;
        } else {
            for (NSString *column in missing) {
                [self alter:table column:column type:[columns objectForKey:column]];
            }
            return NO;
        }
    }
    return YES;
}

- (void)create:(NSString *)table columns:(NSDictionary *)columns {
    NSMutableString *sql = [NSMutableString stringWithString:@"CREATE TABLE IF NOT EXISTS "];
    [sql appendString:table];
    [sql appendString:@"("];
    BOOL first = YES;
    for (NSString *column in columns) {
        if (first) {
            first = NO;
        } else {
            [sql appendString:@", "];
        }
        [sql appendString:column];
        [sql appendString:@" "];
        [sql appendString:[columns objectForKey:column]];
    }
    [sql appendString:@")"];
    [[Database getInstance] execSql:sql params:Nil];
}

- (void)alter:(NSString *)table column:(NSString *)column type:(NSString *)type {
    NSMutableString *sql = [NSMutableString stringWithString:@"ALTER TABLE "];
    [sql appendString:table];
    [sql appendString:@" ADD COLUMN "];
    [sql appendString:column];
    [sql appendString:@" "];
    [sql appendString:type];
    [[Database getInstance] execSql:sql params:Nil];
}


- (void)createIndex:(NSString *)table columns:(NSArray *)columns unique:(BOOL)unique {
    NSMutableString *sql = [NSMutableString stringWithString:@"CREATE "];
    if (unique) {
        [sql appendString:@"UNIQUE "];
    }
    [sql appendString:@"INDEX IF NOT EXISTS "];
    [sql appendString:table];
    for (NSString *column in columns) {
        [sql appendString:@"_"];
        [sql appendString:column];
    }
    [sql appendString:@" ON "];
    [sql appendString:table];
    [sql appendString:@"("];
    BOOL first = YES;
    for (int i = 0; i < [columns count]; i++) {
        if (first) {
            first = NO;
        } else {
            [sql appendString:@", "];
        }
        [sql appendString:[columns objectAtIndex:i]];
    }
    [sql appendString:@")"];
    [[Database getInstance] execSql:sql params:Nil];
}


- (NSArray *)select:(NSString *)table fields:(NSArray *)fields criteria:(NSObject <Criteria> *)criteria limit:(int)limit order:(NSString *)order {
    NSMutableString *sql = [NSMutableString stringWithString:@"SELECT "];
    BOOL first = YES;
    
    for (NSString *field in fields) {
        if (first) {
            first = NO;
        } else {
            [sql appendString:@", "];
        }
        [sql appendString:field];
    }
    
    [sql appendString:@" FROM "];
    [sql appendString:table];
    if (criteria != nil) {
        [sql appendString:@" WHERE "];
        [sql appendString:[criteria toSql]];
    }
    if (order != nil) {
        [sql appendFormat:@" ORDER BY %@", order];
    }
    if (limit != 0) {
        [sql appendFormat:@" LIMIT %d", limit];
    }
    
    return [self selectSql:sql params:[criteria getParams] fields:fields];
}


- (void)drop:(NSString *)table {
    NSString *sql = [NSString stringWithFormat:@"DROP TABLE %@", table];
    [[Database getInstance] execSql:sql params:Nil];
}

- (void)remove:(NSString *)table criteria:(NSObject <Criteria> *)criteria {
    NSMutableString *sql = [NSMutableString stringWithString:@"DELETE FROM "];
    [sql appendString:table];
    if (criteria != nil) {
        [sql appendString:@" WHERE "];
        [sql appendString:[criteria toSql]];
    }
    [self execSql:sql params:[criteria getParams]];
}

- (void)insert:(NSString *)table item:(NSDictionary *)item {
    NSMutableString *sql = [NSMutableString stringWithString:@"INSERT INTO "];
    [sql appendString:table];
    [sql appendString:@"("];
    BOOL first = YES;
    for (NSString *field in [item keyEnumerator]) {
        if (first) {
            first = NO;
        } else {
            [sql appendString:@", "];
        }
        [sql appendString:field];
    }
    [sql appendString:@") VALUES ("];
    first = YES;
    NSMutableArray *params = [[NSMutableArray alloc] initWithCapacity:1];
    for (NSString *field in [item keyEnumerator]) {
        if (first) {
            first = NO;
        } else {
            [sql appendString:@", "];
        }
        [sql appendString:@"?"];
        [params addObject:[item objectForKey:field]];
    }
    [sql appendString:@")"];
    [self execSql:sql params:params];
}

- (void)update:(NSString *)table item:(NSDictionary *)item criteria:(NSObject <Criteria> *)criteria {
    NSMutableString *sql = [NSMutableString stringWithString:@"UPDATE "];
    [sql appendString:table];
    [sql appendString:@" SET "];
    BOOL first = YES;
    NSMutableArray *params = [[NSMutableArray alloc] initWithCapacity:1];
    for (NSString *field in [item keyEnumerator]) {
        if (first) {
            first = NO;
        } else {
            [sql appendString:@", "];
        }
        [sql appendString:field];
        [sql appendString:@" = ?"];
        [params addObject:[item objectForKey:field]];
    }
    if (criteria != nil) {
        [sql appendString:@" WHERE "];
        [sql appendString:[criteria toSql]];
        [params addObjectsFromArray:[criteria getParams]];
    }
    [self execSql:sql params:params];

}

+ (NSString *)setParameters:(NSString *)sql params:(NSArray *)params {
    NSMutableString *ms = [[NSMutableString alloc] initWithString:sql];
    for (NSObject *param in params) {
        NSRange range = [ms rangeOfString:@"?"];
        if (range.location != NSNotFound) {
            if ([param isKindOfClass:[NSData class]]) {
                [ms replaceCharactersInRange:range withString:@"<data>"];
            } else {
                [ms replaceCharactersInRange:range withString:[NSString stringWithFormat:@"'%@'", param]];
            }
        }
    }
    return ms;
}

@end
