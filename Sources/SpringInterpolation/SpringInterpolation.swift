//
//  SpringInterpolation.swift
//  SpringInterpolation
//
//  Created by QAQ on 2023/12/3.
//

import Foundation

public struct SpringInterpolation: Equatable, Hashable {
    public var config: Configuration
    public var context: Context

    public var value: Double { context.currentPos }

    public init(config: Configuration = .init(), context: Context = .init()) {
        self.config = config
        self.context = context
    }

    @discardableResult
    public mutating func update(withDeltaTime interval: TimeInterval, stopWhenHitTarget: Bool = false) -> Double {
        let oldPos = context.currentPos - context.targetPos
        let oldVel = context.currentVel
        let parms = config.generateParameters(deltaTime: interval)
        let newPos = oldPos * parms.posPosCoef + oldVel * parms.posVelCoef + context.targetPos
        let newVel = oldPos * parms.velPosCoef + oldVel * parms.velVelCoef
        context.currentPos = newPos
        context.currentVel = newVel
        if abs(newPos - context.targetPos) < config.threshold {
            context.currentPos = context.targetPos
            if stopWhenHitTarget { context.currentVel = 0 }
        }
        return context.currentPos
    }

    public mutating func setCurrent(_ pos: Double, _ vel: Double = 0) {
        context.currentPos = pos
        context.currentVel = vel
    }

    public mutating func setTarget(_ pos: Double) {
        context.targetPos = pos
    }

    public mutating func setThreshold(_ threshold: Double) {
        config.threshold = threshold
    }
}
