//
//  PJTernarySearchTree.h
//  PJAutocomplete
//
//  Created by Yichao 'Peak' Ji on 2013-2-22.

// This code is distributed under the terms and conditions of the MIT license.

// Copyright (c) 2013 Yichao 'Peak' Ji
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.


#import <Foundation/Foundation.h>

@protocol PJSearchableItem <NSObject>
- (NSString *)stringValue;
@end

typedef void(^PJTernarySearchResultBlock)(NSArray * retrieved);

@interface PJTernarySearchTree : NSObject <NSCoding>

/* Managing item/string */

- (void)insertItem:(id<PJSearchableItem>)item;
- (void)insertString:(NSString *)str;

- (void)removeItem:(id<PJSearchableItem>)item;
- (void)removeString:(NSString *)str;

/* Retrieving */

- (NSArray *)retrievePrefix:(NSString *)prefix;
- (NSArray *)retrievePrefix:(NSString *)prefix countLimit:(NSUInteger)countLimit;    // 0 = no limit

- (void)retrievePrefix:(NSString *)prefix callback:(PJTernarySearchResultBlock)callback;
- (void)retrievePrefix:(NSString *)prefix countLimit:(NSUInteger)countLimit callback:(PJTernarySearchResultBlock)callback;

- (NSArray *)retrieveAll;
- (NSArray *)retrieveAllWithCountLimit:(NSUInteger)countLimit;

/* Serializing */

- (void)saveTreeToFile:(NSString *)path;
+ (PJTernarySearchTree *)treeWithFile:(NSString *)path;

+ (instancetype)sharedTree;
@end