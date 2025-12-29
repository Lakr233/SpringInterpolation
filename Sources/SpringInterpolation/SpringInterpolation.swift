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
    public mutating func update(withDeltaTime interval: TimeInterval) -> Double {
        let oldPos = context.currentPos - context.targetPos
        let oldVel = context.currentVel
        let deltaTime = max(interval, 0)
        let parms = config.generateParameters(deltaTime: deltaTime)
        let newPos = oldPos * parms.posPosCoef + oldVel * parms.posVelCoef + context.targetPos
        let newVel = oldPos * parms.velPosCoef + oldVel * parms.velVelCoef
        let previousAcceleration = context.currentAcceleration
        let newAcceleration = deltaTime > 0 ? (newVel - oldVel) / deltaTime : 0

        context.lastDeltaTime = deltaTime
        context.currentPos = newPos
        context.currentVel = newVel
        context.velocityDelta = abs(newVel - oldVel)
        context.accelerationDelta = abs(newAcceleration - previousAcceleration)
        context.currentAcceleration = newAcceleration
        if abs(newPos - context.targetPos) < config.threshold {
            context.currentPos = context.targetPos
            if config.stopWhenHitTarget {
                context.currentVel = 0
                context.currentAcceleration = 0
                context.velocityDelta = 0
                context.accelerationDelta = 0
            }
        }
        return context.currentPos
    }

    public mutating func setCurrent(_ pos: Double, _ vel: Double = 0) {
        context.currentPos = pos
        context.currentVel = vel
        context.currentAcceleration = 0
        context.velocityDelta = 0
        context.accelerationDelta = 0
        context.lastDeltaTime = 0
    }

    public mutating func setTarget(_ pos: Double) {
        context.targetPos = pos
    }

    public mutating func setThreshold(_ threshold: Double) {
        config.threshold = threshold
    }
}
