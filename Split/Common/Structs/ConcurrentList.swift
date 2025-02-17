//
//  SynchronizedArrayWrapper.swift
//  Split
//
//  Created by Javier on 26/07/2018.
//  Copyright © 2018 Split. All rights reserved.
//

import Foundation

class ConcurrentList<T> {
    private var queue: DispatchQueue
    private var items: [T]
    private var capacity: Int

    var all: [T] {
        var allItems: [T]?
        queue.sync {
            allItems = items
        }
        return allItems!
    }

    var count: Int {
        var count: Int = 0
        queue.sync {
            count = items.count
        }
        return count
    }

    init(capacity: Int) {
        self.queue = DispatchQueue(label: NSUUID().uuidString, attributes: .concurrent)
        self.items = [T]()
        self.capacity = capacity
    }

    convenience init() {
        self.init(capacity: -1)
    }

    func append(_ item: T) {

        queue.async(flags: .barrier) { [weak self] in
            if let self = self {
                if self.capacity > -1,
                   self.items.count >= self.capacity {
                    return
                }
                self.items.append(item)
            }
        }
    }

    func removeAll() {
        queue.async(flags: .barrier) { [weak self] in
            if let self = self {
                self.items.removeAll()
            }
        }
    }

    func append(_ items: [T]) {
        queue.async(flags: .barrier) { [weak self] in
            if let self = self {
                if self.capacity > -1 {
                    if self.items.count >= self.capacity {
                        return
                    }
                    let appendCount = self.capacity - self.items.count
                    if appendCount < 1 {
                        return
                    }
                    self.items.append(contentsOf: items[0..<appendCount])
                } else {
                    self.items.append(contentsOf: items)
                }
            }
        }
    }

    func fill(with newItems: [T]) {
        queue.async(flags: .barrier) { [weak self] in
            if let self = self {
                self.items.removeAll()
                self.items.append(contentsOf: newItems)
            }
        }
    }

    func takeAll() -> [T] {
        var allItems: [T]!
        queue.sync {
            allItems = self.items
            queue.async(flags: .barrier) { [weak self] in
                if let self = self {
                    self.items.removeAll()
                }
            }
        }
        return allItems
    }
}
