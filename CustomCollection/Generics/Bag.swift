//
//  Bag.swift
//  CustomCollection
//
//  Created by Dubbasi, Amith on 9/13/19.
//  Copyright © 2019 Dubbasi, Amith. All rights reserved.

import Foundation

/* Bag is a generic data structure that requires the element to be Hashable. Requiring Hashable elements allows We to compare and only store unique values at O(1) time complexity. This means that no matter the size of its contents, Bag will perform at constant speeds. We used a struct to enforce value semantics as found with Swift’s standard collections. */

struct Bag<Element: Hashable> {
    
    fileprivate var contents: [Element: Int] = [:]
    
    var uniqueCount: Int {
        return contents.count
    }
    
    var totalCount: Int {
        return contents.reduce(0, { (result, node) -> Int in
            var result = result
            result += node.value
            return result
        })
        //return contents.values.reduce(0) { $0 + $1 }
    }
    
    init() {
    }
    
    /*let dataArray = ["Banana", "Orange", "Banana"]
    let dataDictionary = ["Banana": 2, "Orange": 1]
    let dataSet: Set = ["Banana", "Orange", "Banana"]
    
    var arrayBag = Bag(dataArray)
    precondition(arrayBag.contents == dataDictionary, "Expected arrayBag contents to match \(dataDictionary)")
    
    var dictionaryBag = Bag(dataDictionary)
    precondition(dictionaryBag.contents == dataDictionary, "Expected dictionaryBag contents to match \(dataDictionary)")
    
    var setBag = Bag(dataSet)
    precondition(setBag.contents == ["Banana": 1, "Orange": 1], "Expected setBag contents to match \(["Banana": 1, "Orange": 1])")*/
    
    // **Rather than explicitly creating an initialization method for each type, we will use generics.**
    
    init<S: Sequence>(_ sequence: S) where S.Iterator.Element == Element {
        for element in sequence {
            add(element)
        }
    }
    
    init<S: Sequence>(_ sequence: S) where S.Iterator.Element == (key: Element, value: Int) {
        for (key, value) in sequence {
            add(key, occurences: value)
        }
    }
    
    mutating func add(_ member: Element, occurences: Int = 1) {
        precondition(occurences > 0, "Can only add positive occurences")
        if let current = contents[member] {
            contents[member] = current + occurences
        } else {
            contents[member] = occurences
        }
    }
    
    mutating func remove(_ member: Element, occurences: Int = 1) {
        guard let currentCount = contents[member], currentCount >= occurences else {
            preconditionFailure("Removal doesn't exist")
        }
        precondition(occurences > 0, "Removal should be positive")
        if currentCount > occurences{
            contents[member] = currentCount - occurences
        } else {
            contents.removeValue(forKey: member)
        }
    }
}

extension Bag: CustomStringConvertible {
    var description: String {
        return String(describing: contents)
    }
}

/*
 
 Swift provides two standard protocols which enable initialization with sequence literals. Literals give a shorthand way to write data without explicitly creating an object.
 
 1. ExpressibleByArrayLiteral
 2. ExpressibleByDictionaryLiteral
 
 var arrayLiteralBag: Bag = ["Banana", "Orange", "Banana"]
 precondition(arrayLiteralBag.contents == dataDictionary, "Expected arrayLiteralBag contents to match \(dataDictionary)")
 
 var dictionaryLiteralBag: Bag = ["Banana": 2, "Orange": 1]
 precondition(dictionaryLiteralBag.contents == dataDictionary, "Expected dictionaryLiteralBag contents to match \(dataDictionary)")
 */

extension Bag: ExpressibleByArrayLiteral {
    init(arrayLiteral elements: Element...) {
        self.init(elements)
    }
}

extension Bag: ExpressibleByDictionaryLiteral {
    init(dictionaryLiteral elements: (Element, Int)...) {
        self.init(elements.map { (key: $0.0, value: $0.1)})
    }
}

//Now we will provide basic stuff like looping through a collection by conforming to Sequence protocol

/*
 extension Bag: Sequence {
 
 We defined a typealias named Iterator that Sequence defines as conforming to IteratorProtocol.
 DictionaryIterator is the type that Dictionary objects use to iterate through their elements. We’re
 using this type because Bag stores its underlying data in a Dictionary.
 
 typealias Iterator = DictionaryIterator<Element, Int>
 
 func makeIterator() -> Iterator {
 return contents.makeIterator()
 }
 
 We can now iterate through each element of a Bag and get the count for each object.
 Conforming to Sequence protocol provides us very useful methods like filter, reduce, map, sorted
 }
 */

extension Bag: Sequence {
    
    typealias Iterator = AnyIterator<(element: Element, count: Int)>
    
    func makeIterator() -> Iterator {
        var iterator = contents.makeIterator()
        return AnyIterator {
            iterator.next()
        }
    }
    
    /*
     Before, We were using the DictionaryIterator tuple names key and value. We’ve hidden
     
     DictionaryIterator from the outside world and renamed the exposed tuple names to element and count.
     To fix the errors, replace key and value with element and count respectively.
     
     Our preconditions should now pass and work just as they did before.
     This is why preconditions are awesome at making sure things don’t change unexpectedly.
     Now no one will know that We’re just using a dictionary to do everything for us.
     */
}

//Few more functionalities for our custom collection

/*extension Bag: Collection {

    typealias Index = DictionaryIndex<Element, Int>

    var startIndex: Index {
        return contents.startIndex
    }

    var endIndex: Index {
        return contents.endIndex
    }

    subscript(position: Index) -> Iterator.Element {
        precondition(indices.contains(position), "Doesn't contain")
        let element = contents[position]
        return (element: element.key, count: element.value)
    }

    func index(after i: Index) -> Index {
        return contents.index(after: i)
    }
}*/


// Note: There’s still some Dictionary smell leaking from Bag. so we created BagIndex, BagIndex is really just a wrapper that hides its true index from the outside world.
struct BagIndex<Element: Hashable> {
    
    fileprivate let index: DictionaryIndex<Element, Int>
    
    fileprivate init(_ dictionaryIndex: DictionaryIndex<Element, Int>) {
        self.index = dictionaryIndex
    }
    
    // after this we replaced Index in conformance to Collection protocol
}

extension BagIndex: Comparable {
    
    /*
     Collection requires Index to be comparable to allow comparing two indexes to perform operations.
     Because of this, BagIndex needs to conform to Comparable.
     */
    static func < (lhs: BagIndex<Element>, rhs: BagIndex<Element>) -> Bool {
       return lhs.index < rhs.index
    }
    
    static func == (lhs: BagIndex<Element>, rhs: BagIndex<Element>) -> Bool {
        return lhs.index == rhs.index
    }
}

extension Bag: Collection {
    
    typealias Index = BagIndex<Element>
    
    var startIndex: Index {
        return BagIndex(contents.startIndex)
    }
    
    var endIndex: Index {
        return BagIndex(contents.endIndex)
    }
    
    func index(after i: Index) -> Index {
        return Index(contents.index(after: i.index))
    }
    
    subscript(position: Index) -> Iterator.Element {
        precondition((startIndex ..< endIndex).contains(position), "Out of bounds")
        let dictionaryElement = contents[position.index]
        return (element: dictionaryElement.key, count: dictionaryElement.value)
    }
        
}

/*
 Learned what makes a data structure a collection in Swift by creating our own.
 We added conformance to Sequence, Collection, CustomStringConvertible, ExpressibleByArrayLiteral,
 ExpressibleByDictionaryLiteral as well as creating our own index type.
 https://swiftdoc.org/v3.0/type/dictionary/hierarchy/
 */

