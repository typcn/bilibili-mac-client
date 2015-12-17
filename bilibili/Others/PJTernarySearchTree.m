//
//  PJTernarySearchTree.m
//  PJAutocomplete
//
//  Created by Yichao 'Peak' Ji on 2013-2-22.

#import "PJTernarySearchTree.h"

#pragma mark - PJTernarySearchTreeNode

@interface PJTernarySearchTreeNode : NSObject <NSCoding>{
@public
    PJTernarySearchTreeNode * descendingChild;
    PJTernarySearchTreeNode * equalChild;
    PJTernarySearchTreeNode * ascendingChild;
}

@property (strong) id item;
@property (readwrite) unichar nodeChar;

@end

@implementation PJTernarySearchTreeNode

#define kItemKey                @"item"
#define kNodeCharKey            @"nodeChar"
#define kDescendingChildKey     @"de"
#define kEqualChildKey          @"eq"
#define kAscendingChildKey      @"as"

#pragma mark - NSCoding Delegate

- (void)encodeWithCoder:(NSCoder *)aCoder{
    
    if((self.item!=nil)&&([self.item conformsToProtocol:@protocol(PJSearchableItem)]==YES))
    {
        [aCoder encodeObject:self.item forKey:kItemKey];
    }
    if([NSString stringWithFormat:@"%C",self.nodeChar]!=nil)
    {
        [aCoder encodeObject:[NSString stringWithFormat:@"%C",self.nodeChar] forKey:kNodeCharKey];
    }
    if(descendingChild!=nil)
    {
        [aCoder encodeObject:descendingChild forKey:kDescendingChildKey];
    }
    if(equalChild!=nil)
    {
        [aCoder encodeObject:equalChild forKey:kEqualChildKey];
    }
    if(ascendingChild!=nil)
    {
        [aCoder encodeObject:ascendingChild forKey:kAscendingChildKey];
    }
}


- (id)initWithCoder:(NSCoder *)aDecoder{
    
    if (self = [self init])
    {
        if([aDecoder decodeObjectForKey:kItemKey]!=nil)
        {
            self.item = [aDecoder decodeObjectForKey:kItemKey];
        }
        if([aDecoder decodeObjectForKey:kNodeCharKey]!=nil)
        {
            self.nodeChar = [[aDecoder decodeObjectForKey:kNodeCharKey] characterAtIndex:0];
        }
        if([aDecoder decodeObjectForKey:kAscendingChildKey]!=nil)
        {
            ascendingChild = [aDecoder decodeObjectForKey:kAscendingChildKey];
        }
        else
        {
            ascendingChild = nil;
        }
        if([aDecoder decodeObjectForKey:kDescendingChildKey]!=nil)
        {
            descendingChild = [aDecoder decodeObjectForKey:kDescendingChildKey];
        }
        else
        {
            descendingChild = nil;
        }
        if([aDecoder decodeObjectForKey:kEqualChildKey]!=nil)
        {
            equalChild = [aDecoder decodeObjectForKey:kEqualChildKey];
        }
        else
        {
            equalChild = nil;
        }
        
    }
    return self;
    
}

@end


#pragma mark - PJSearchableString (NSString add-on)

@interface NSString (PJSearchableString) <PJSearchableItem>

- (NSString *)stringValue;

@end

@implementation NSString (PJSearchableString)

- (NSString *)stringValue{
    return (NSString *)self;
}

@end


#pragma mark - PJTernarySearchTree

@interface PJTernarySearchTree ()

@property (strong) PJTernarySearchTreeNode * rootNode;
@property (strong) NSString * lastPrefix;
@property (strong) PJTernarySearchTreeNode * lastResultNode;

@end


@implementation PJTernarySearchTree{
        int autoSaveCount;
}

@synthesize rootNode;

- (id)init{
    self = [super init];
    if (self) {
        self.rootNode = nil;
        self.lastPrefix = nil;
        self.lastResultNode = nil;
    }
    return self;
}


#pragma mark - NSCoding Delegate

#define kRootKey    @"root"

- (void)encodeWithCoder:(NSCoder *)aCoder{
    
    if(self.rootNode!=nil)
    {
        [aCoder encodeObject:self.rootNode forKey:kRootKey];
    }
}


- (id)initWithCoder:(NSCoder *)aDecoder{
    
    if (self = [self init])
    {
        if([aDecoder decodeObjectForKey:kRootKey]!=nil)
        {
            self.rootNode = [aDecoder decodeObjectForKey:kRootKey];
        }
        
    }
    return self;
    
}


#pragma mark - Managing

- (void)insertItem:(id<PJSearchableItem>)item{
    
    if(item==nil||([item isKindOfClass:[NSString class]]&&((NSString *)item).length==0))
    {
        return;
    }
    
    NSString * stringValue = [item stringValue];
    
    NSArray *foundStr = [self retrievePrefix:stringValue countLimit:1];
    
    if(foundStr && [foundStr count] > 0){
        // Never insert same URL
        return;
    }
    
    if(!autoSaveCount){
        autoSaveCount = 1;
    }else if(autoSaveCount > 10){
        dispatch_async(dispatch_get_global_queue(0, 0), ^(void){
            [self saveTreeToFile: @"/Users/Shared/.fc/bm_index.db"];
        });
    }else{
        autoSaveCount++;
    }
    
    
    PJTernarySearchTreeNode * __strong * found = &(self->rootNode),* node = self->rootNode,* parent = nil;
    
    int index = 0;
    
    while (index < [stringValue length]) {
        unichar ch = [stringValue characterAtIndex:index];
        if (!node) {
            * found = [[PJTernarySearchTreeNode alloc] init];
            node = *found;
            node.nodeChar = ch;
        }
        if (ch < node.nodeChar) {
            found = &(node->descendingChild);
            node = node->descendingChild;
        } else if (ch == node.nodeChar) {
            parent = node;
            found = &(node->equalChild);
            node = node->equalChild;
            index++;
        } else {
            found = &(node->ascendingChild);
            node = node->ascendingChild;
        }
    }
    
    if (parent.item == nil) {
        parent.item = item;
    } else {
        if ([parent.item isKindOfClass:[NSMutableArray class]]) {
            [(NSMutableArray *)parent.item addObject:item];
        } else {    
            parent.item = [NSMutableArray arrayWithObjects:parent.item,item, nil];
        }
    }
}

- (void)insertString:(NSString *)str{
    [self insertItem:str];
}

- (BOOL)isEmptyNode:(PJTernarySearchTreeNode *)node{
    if((node==nil)||(node.item==nil && node->descendingChild==nil && node->equalChild==nil && node->ascendingChild==nil))
    {
        return YES;
    }
    else
    {
        return NO;
    }
}

- (void)removeItem:(id<PJSearchableItem>)item{
    
    self.lastResultNode = nil;
    self.lastPrefix = nil;
    
    NSMutableArray * route = [self routePrefixRoot:[item stringValue]];
    
    PJTernarySearchTreeNode * node = [route lastObject];
    
    if(node!=nil)
    {
        node.item = nil;
    }
    
    if([self isEmptyNode:node]==YES)
    {
        for(NSInteger i = [route count]-1;i>=0;i--)
        {
            PJTernarySearchTreeNode * checkNode = [route objectAtIndex:i];
            
            if(checkNode->ascendingChild!=nil && ([self isEmptyNode:checkNode->ascendingChild]==YES))
            {
                checkNode->ascendingChild = nil;
            }
            else
            {
                break;
            }
            if(checkNode->equalChild!=nil && ([self isEmptyNode:checkNode->equalChild]==YES))
            {
                checkNode->equalChild = nil;
            }
            else
            {
                break;
            }
            if(checkNode->descendingChild!=nil && ([self isEmptyNode:checkNode->descendingChild]==YES))
            {
                checkNode->descendingChild = nil;
            }
            else
            {
                break;
            }
        }
    }
}

- (void)removeString:(NSString *)str{
    [self removeItem:str];
}


#pragma mark - Main

- (NSMutableArray *)routePrefixRoot:(NSString*)prefix{
    
    NSInteger index = 0;
    
    NSMutableArray * array = [NSMutableArray array];
    
    PJTernarySearchTreeNode * node = self->rootNode,* found;
    
    while (index < [prefix length]) {
        
        unichar ch = [prefix characterAtIndex:index];
        if (ch < node.nodeChar) {
            if (!node->descendingChild) {
                return nil;
            }
            node = node->descendingChild;
            
            continue;
        } else if (ch == node.nodeChar) {
            found = node;
            [array addObject:found];
            node = node->equalChild;
            index++;
            continue;
        } else {
            if (!node->ascendingChild) {
                return nil;
            }
            node = node->ascendingChild;
            continue;
        }
    }
    return array;
}

- (PJTernarySearchTreeNode *)locatePrefixRoot:(NSString*)prefix withRootNode:(PJTernarySearchTreeNode *)root{
    
    NSInteger index = 0;
    
    PJTernarySearchTreeNode * node = self->rootNode,* found;
    
    if(root!=nil && (self.lastPrefix!=nil))
    {
        node = root;
        index = [prefix length] - ([prefix length] - [self.lastPrefix length]) - 1;
    }
    
    while (index < [prefix length]) {
        
        if(!node){
            return nil;
        }
        
        unichar ch = [prefix characterAtIndex:index];
        if (ch < node.nodeChar) {
            if (!node->descendingChild) {
                return nil;
            }
            node = node->descendingChild;
            
            continue;
        } else if (ch == node.nodeChar) {
            found = node;
            node = node->equalChild;
            index++;
            continue;
        } else {
            if (!node->ascendingChild) {
                return nil;
            }
            node = node->ascendingChild;
            continue;
        }
    }
    return found;
}

+ (void)addItems:(PJTernarySearchTreeNode*)node toArray:(NSMutableArray*)output limit:(NSUInteger)countLimit{
    if ((countLimit!=0)&&([output count]>=countLimit)) {
        return;
    }
    if (!node.item) {
        return;
    }
    if ([node.item isKindOfClass:[NSArray class]]) {
        [output addObjectsFromArray:node.item];
    } else {
        [output addObject:node.item];
    }
}

- (void)retrieveNodeFrom:(PJTernarySearchTreeNode *)prefixedRoot toArray:(NSMutableArray*)output limit:(NSUInteger)countLimit{
    
    if ((countLimit!=0)&&([output count]>=countLimit)) {
        return;
    }
    if (prefixedRoot == nil) {
        return;
    }
    [self retrieveNodeFrom:prefixedRoot->descendingChild toArray:output limit:countLimit];
    [PJTernarySearchTree addItems:prefixedRoot toArray:output limit:countLimit];
    [self retrieveNodeFrom:prefixedRoot->equalChild toArray:output limit:countLimit];
    [self retrieveNodeFrom:prefixedRoot->ascendingChild toArray:output limit:countLimit];
}

#pragma mark - Retrieving

- (NSArray *)retrieveAll{
    return [self retrieveAllWithCountLimit:0];
}

- (NSArray *)retrieveAllWithCountLimit:(NSUInteger)countLimit{
    
    NSMutableArray* output = [NSMutableArray array];
    [PJTernarySearchTree addItems:self.rootNode toArray:output limit:countLimit];
    if(self.rootNode==nil)
    {
        return [NSArray array];
    }
    [self retrieveNodeFrom:self.rootNode->descendingChild toArray:output limit:countLimit];
    [self retrieveNodeFrom:self.rootNode->equalChild toArray:output limit:countLimit];
    [self retrieveNodeFrom:self.rootNode->ascendingChild toArray:output limit:countLimit];
    
    if ((countLimit!=0)&&([output count]>=countLimit)) {
        return [NSArray arrayWithArray:[output objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, countLimit)]]];
    }
    else
    {
        return [NSArray arrayWithArray:output];
    }
}

- (NSArray *)retrievePrefix:(NSString *)prefix countLimit:(NSUInteger)countLimit{
    
    if(prefix==nil)
    {
        prefix = @"";
    }
    
    PJTernarySearchTreeNode * prefixedRoot = nil;
    if(prefix.length==0)
    {
        return [self retrieveAllWithCountLimit:countLimit];
    }
    else
    {
        if(self.lastPrefix!=nil && ([prefix hasPrefix:self.lastPrefix]==YES))
        {
            prefixedRoot = [self locatePrefixRoot:prefix withRootNode:self.lastResultNode];
        }
        else
        {
            prefixedRoot = [self locatePrefixRoot:prefix withRootNode:nil];
        }
    }
    
    if(!prefixedRoot)
    {
        return [NSArray array];
    }
    
    self.lastResultNode = prefixedRoot;
    self.lastPrefix = [NSString stringWithString:prefix];
    
    NSMutableArray* output = [NSMutableArray array];
    [PJTernarySearchTree addItems:prefixedRoot toArray:output limit:countLimit];
    
    [self retrieveNodeFrom:prefixedRoot->equalChild toArray:output limit:countLimit];
    
    if ((countLimit!=0)&&([output count]>=countLimit)) {
        return [NSArray arrayWithArray:[output objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, countLimit)]]];
    }
    else
    {
        return [NSArray arrayWithArray:output];
    }
}

- (NSArray *)retrievePrefix:(NSString *)prefix{
    
    return [self retrievePrefix:prefix countLimit:0];
}

- (void)retrievePrefix:(NSString *)prefix callback:(PJTernarySearchResultBlock)callback{
    [self retrievePrefix:prefix countLimit:0 callback:callback];
}

- (void)retrievePrefix:(NSString *)prefix countLimit:(NSUInteger)countLimit callback:(PJTernarySearchResultBlock)callback{
    
    if(!callback)
    {
        return;
    }
    
    dispatch_queue_t ternary_search_queue;
    
    ternary_search_queue = dispatch_queue_create([[NSString stringWithFormat:@"com.PeakJi.PJAutocomplete.ternary_search.%@",prefix] UTF8String], nil);
    
    dispatch_async(ternary_search_queue, ^{
        
        NSArray * array = [self retrievePrefix:prefix countLimit:countLimit];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            callback(array);
            
        });
    });
}

#pragma mark - Serializing

- (void)saveTreeToFile:(NSString *)path{
    __autoreleasing NSData * data = [NSKeyedArchiver archivedDataWithRootObject:self];
    [data writeToFile:path atomically:YES];
}

+ (PJTernarySearchTree *)treeWithFile:(NSString *)path{
    if (path == nil || [path length] == 0 ||
        [[NSFileManager defaultManager] fileExistsAtPath:path] == NO){
        return nil;
    }
    else
    {
        __autoreleasing PJTernarySearchTree * tree = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
        return tree;
    }
}

- (dispatch_queue_t)sharedIndexQueue {
    static dispatch_queue_t sharedQueue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedQueue = dispatch_queue_create("com.typcn.bilibili.URLIndexThread", DISPATCH_QUEUE_SERIAL);
    });
    return sharedQueue;
}

+ (instancetype)sharedTree {
    static id sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *savePath = @"/Users/Shared/.fc/bm_index.db";
        BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:savePath];
        if(fileExists){
            sharedInstance = [self treeWithFile:savePath];
        }else{
            sharedInstance = [[self alloc] init];
        }
    });
    return sharedInstance;
}

@end