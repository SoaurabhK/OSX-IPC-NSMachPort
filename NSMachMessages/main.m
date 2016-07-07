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
@interface MyServer : NSObject
@end

@implementation MyServer
+ (void)serverThread
{
    // Register a server's listener port
    NSMachPort *serverPort = (id)[NSMachPort port];
    [serverPort setDelegate: (id)self];
    [serverPort scheduleInRunLoop: [NSRunLoop currentRunLoop] forMode: NSDefaultRunLoopMode];
    assert([[NSMachBootstrapServer sharedInstance] registerPort: serverPort name: @"SK's Server"]);
    
    // Check if server can send messages on client's listener port
    NSMachPort *serverSendPort = nil;
    while(!serverSendPort) {
        serverSendPort = (id)[[NSMachBootstrapServer sharedInstance] portForName: @"SK's Client"];
    }
    
    // Create a message and send it to client's listener port
    NSPortMessage *message = [[NSPortMessage alloc] initWithSendPort: serverSendPort receivePort:nil
                                                              components: [NSArray arrayWithObject: [@"hello from server" dataUsingEncoding: NSUTF8StringEncoding]]];
    [message setMsgid: 0xCBFEBABE];
    assert([message sendBeforeDate: [NSDate distantFuture]]);
    
    // To keep the thread alive
    [[NSRunLoop currentRunLoop] run];
    
}
+ (void)handlePortMessage: (NSPortMessage *)message
{
    NSLog(@"Server Received message (msgid: 0x%lX): %@, %@, %@", (long)[message msgid], [[NSString alloc] initWithData:message.components[0] encoding:NSUTF8StringEncoding], message.receivePort, message.sendPort);
    
}
@end

@interface MyClient : NSObject
@end

@implementation MyClient

+(void) sendIPCMsg {
    
    //Register a client's listener port
    NSMachPort *clientRecievePort = (id)[NSMachPort port];
    [clientRecievePort setDelegate: (id)self];
    [clientRecievePort scheduleInRunLoop: [NSRunLoop currentRunLoop] forMode: NSDefaultRunLoopMode];
    assert([[NSMachBootstrapServer sharedInstance] registerPort: clientRecievePort name: @"SK's Client"]);
    
    
    [NSThread detachNewThreadSelector: @selector(serverThread) toTarget: [MyServer class] withObject: nil];
    
    // Check if client can send messages on server's listener port
    NSMachPort *clientSendPort = nil;
    while (!clientSendPort) {
        clientSendPort = (id)[[NSMachBootstrapServer sharedInstance] portForName: @"SK's Server"];
        
    }
    // Create a message and send it to server's listener port
    NSPortMessage *message = [[NSPortMessage alloc] initWithSendPort: clientSendPort receivePort:clientRecievePort
                                                              components: [NSArray arrayWithObject: [@"hello from client" dataUsingEncoding: NSUTF8StringEncoding]]];
    [message setMsgid: 0xCAFEBABE];
    assert([message sendBeforeDate: [NSDate distantFuture]]);
    
    // To keep the thread alive
    [[NSRunLoop currentRunLoop] run];
}

+ (void)handlePortMessage: (NSPortMessage *)message
{
    NSLog(@"Client Received message (msgid: 0x%lX): %@, %@, %@", (long)[message msgid], [[NSString alloc] initWithData:message.components[0] encoding:NSUTF8StringEncoding], message.receivePort, message.sendPort);
}

@end

int main(int argc, const char *argv[])
{
   
    [NSThread detachNewThreadSelector: @selector(sendIPCMsg) toTarget: [MyClient class] withObject: nil];
    [[NSRunLoop currentRunLoop] run];
    return 0;
}
