//
//  main.m
//  NSMachMessages
//
//  Created by Soaurabh Kakkar on 07/07/16.
//  Copyright © 2016 Soaurabh Kakkar. All rights reserved.
//

//  we tested it in one process with two threads
//  but it should work equally well if split into two processes…

#import <Foundation/Foundation.h>
@interface MyObject : NSObject
@end

@implementation MyObject
+ (void)serverThread
{
    
    NSMachPort *serverPort = (id)[NSMachPort port];
    [serverPort setDelegate: (id)self];
    [serverPort scheduleInRunLoop: [NSRunLoop currentRunLoop] forMode: NSDefaultRunLoopMode];
    assert([[NSMachBootstrapServer sharedInstance] registerPort: serverPort name: @"SK's Server"]);
    [[NSRunLoop currentRunLoop] runUntilDate: [NSDate distantFuture]] ;
    
}
+ (void)handlePortMessage: (NSPortMessage *)message
{
    NSLog(@"Received message (msgid: 0x%lX): %@", (long)[message msgid], [[NSString alloc] initWithData:message.components[0] encoding:NSUTF8StringEncoding]);
}
@end

int main(int argc, const char *argv[])
{
    
    [NSThread detachNewThreadSelector: @selector(serverThread) toTarget: [MyObject class] withObject: nil];
    
    NSMachPort *clientPort = (id)[[NSMachBootstrapServer sharedInstance] portForName: @"SK's Server"];
    assert(clientPort);
    for (;;)
    {
        NSPortMessage *message = [[NSPortMessage alloc] initWithSendPort: clientPort receivePort: nil
                                                               components: [NSArray arrayWithObject: [@"hello" dataUsingEncoding: NSUTF8StringEncoding]]];
        [message setMsgid: 0xCAFEBABE];
        
        assert([message sendBeforeDate: [NSDate distantFuture]]);
    }
    
    return 0;
}
