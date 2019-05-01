//
//  WebserviceRequest.m
//  Yoo
//
//  Created by Heng Sokchamroeun on 10/15/14.
//  Copyright (c) 2014 Fellow Consulting. All rights reserved.
//

#import "WebserviceRequest.h"

@implementation WebserviceRequest

    -(id)init{
        if(self = [super init]){
            self.webData = [[NSMutableData alloc] init];
        }
        return self;
    }

    -(void)doRequest:(WebserviceRequest *) pListener name:(NSString *) pName country:(NSString *)pCountry type:(NSString *)pType action:(NSString *)pAction listNames:(NSArray *)pListNames{

        /*
         
        
        {
            "Name": "Xema",
            "Country": "DE",
            "Typ":"Call or Conf",
            "Action": "Invite",
            "Invite": {
                "Name": "Mustermann", 
                "Name": "Tim",
            }
        }
         */
        NSString *names = @"";
        for(NSString *name in pListNames){
            if([names length] > 0){
                names = [names stringByAppendingString:@", "];
            }
            names = [names stringByAppendingString:[NSString stringWithFormat:@"\"Name\":%@", name]];
        }
        if([names length] > 0){
            names = [NSString stringWithFormat:@"\"Invite\":{%@}", names];
        }
        
        NSString *postData = [NSString stringWithFormat:@"{\"Name\":\"%@\", \"Country\":\"%@\", \"Typ\":\"%@\", \"Action\":\"Invite\", %@}", pName, pCountry, pAction, names];
        
        
        NSUserDefaults *userdefault = [NSUserDefaults standardUserDefaults];
        NSMutableString *baseURL = [[NSMutableString alloc] init];
        [baseURL appendString:@"http://213.136.79.94/api.php"];
//        [baseURL appendString: [NSString stringWithFormat:@"/services/apexrest/%@", webserviceName]];
        
        //        NSString *sql = [self.sqls objectAtIndex:currentIndex];
        //        NSString *encodedSQL = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,(CFStringRef)sql,
        //                                                                                                     NULL,(CFStringRef)@"!*'();:@&=+$,/?%#[]",
        //                                                                                                     kCFStringEncodingUTF8));
        //        [baseURL appendString:encodedSQL];
        
        
        NSLog(@"Call URL: %@", baseURL);
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:baseURL]];
        request.HTTPMethod = @"POST";
        [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [request setHTTPBody:[postData dataUsingEncoding:NSUTF8StringEncoding]];
        self.theConnection = [NSURLConnection connectionWithRequest:request delegate:self];
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    }


    - (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
        self.status = [NSNumber numberWithInt:(int)((NSHTTPURLResponse *)response).statusCode];
        [self.webData setLength: 0];
    }

    - (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
        [self.webData appendData:data];
    }

    - (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)nsError {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        NSDictionary *dic = [[NSDictionary alloc] initWithObjectsAndKeys:@"description",[nsError description], nil];
        [self.listener onFailure:self result:dic];
    }

    - (void)connectionDidFinishLoading:(NSURLConnection *)connection {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        // Success
        NSString *jsonString =[[NSString alloc] initWithData:self.webData encoding:NSUTF8StringEncoding];
        NSLog(@"Response String : %@ status:%@",jsonString,self.status);
        
        //SBJSON *parser = [[SBJSON alloc] init];
        
        // parse the JSON string into an object - assuming json_string is a NSString of JSON data
        //NSMutableDictionary *responseData = [parser objectWithString:jsonString error:nil];

        NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        NSError *e;
        NSDictionary *responseData = [NSJSONSerialization JSONObjectWithData:jsonData options:nil error:&e];
        if(responseData == nil){
            responseData = [NSMutableDictionary dictionary];
        }
        if([responseData isKindOfClass:[NSArray class]]){
            responseData = [(NSArray*)responseData objectAtIndex:0];
        }else if([responseData isKindOfClass:[NSDictionary class]]){
            responseData = responseData;
        }
        //     || [self.status intValue] == 201 || [self.status intValue] == 204
        if ([self.status intValue] == 200) {
            NSLog(@"Successed : %@", responseData);
        }else{
            NSLog(@"Failured : %@", responseData);
        }
        
    }

@end
