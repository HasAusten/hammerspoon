#import "lua/lauxlib.h"

@interface PHMenuItemDelegator : NSObject
@property (copy) dispatch_block_t handler;
@end

@implementation PHMenuItemDelegator
- (void) callCustomPhoenixMenuItemDelegator:(id)sender {
    self.handler();
}
@end


@interface PHMenuDelegate : NSObject <NSMenuDelegate>
@property (copy) dispatch_block_t handler;
@end

@implementation PHMenuDelegate

- (void) menuNeedsUpdate:(NSMenu *)menu {
    self.handler();
}

@end


static NSStatusItem *statusItem;
static PHMenuDelegate* menuDelegate;

int menu_show(lua_State* L) {
    int closure_ref = luaL_ref(L, LUA_REGISTRYINDEX);
    
    NSImage* img = [NSImage imageNamed:@"menu"];
    [img setTemplate:YES];
    
    if (!statusItem) {
        statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
        [statusItem setHighlightMode:YES];
        [statusItem setImage:img];
        
        NSMenu* menu = [[NSMenu alloc] init];
        
        menuDelegate = [[PHMenuDelegate alloc] init];
        menuDelegate.handler = ^{
            [menu removeAllItems];
            
            lua_rawgeti(L, LUA_REGISTRYINDEX, closure_ref);
            
            if (lua_pcall(L, 0, 1, 0) == LUA_OK) {
                // table is at top; enumerate each row
                
                NSLog(@"%d", lua_gettop(L));
                NSLog(@"%s", lua_typename(L, lua_type(L, -1)));
                
                lua_pushnil(L);
                while (lua_next(L, -2) != 0) {
                    
                    // table is at top; enumerate each k/v pair
                    
                    lua_pushnil(L);
                    while (lua_next(L, -2) != 0) {
                        NSString* key = [NSString stringWithUTF8String: lua_tostring(L, -2)];
                        
                        if ([key isEqualToString: @"title"]) {
                            NSString* title = [NSString stringWithUTF8String: lua_tostring(L, -1)];
                            
                            NSMenuItem* item = [[NSMenuItem alloc] init];
                            PHMenuItemDelegator* delegator = [[PHMenuItemDelegator alloc] init];
                            
                            item.title = title;
                            item.action = @selector(callCustomPhoenixMenuItemDelegator:);
                            item.target = delegator;
                            item.representedObject = delegator;
                            
                            delegator.handler = ^{
                                NSLog(@"called!");
                            };
                            
                            [menu addItem:item];
                        }
                        
                        lua_pop(L, 1);
                    }
                    
                    lua_pop(L, 1);
                }
            }
        };
        menu.delegate = menuDelegate;
        [statusItem setMenu: menu];
    }
    
    return 0;
}

int menu_hide(lua_State* L) {
    if (statusItem) {
        [[statusItem statusBar] removeStatusItem: statusItem];
        statusItem = nil;
    }
    return 0;
}

//- (IBAction) toggleOpenAtLogin:(NSMenuItem*)sender {
//    [PHOpenAtLogin setOpensAtLogin:[sender state] == NSOffState];
//}
//
//- (void) menuNeedsUpdate:(NSMenu *)menu {
//    [[menu itemWithTitle:@"Open at Login"] setState:([PHOpenAtLogin opensAtLogin] ? NSOnState : NSOffState)];
//}