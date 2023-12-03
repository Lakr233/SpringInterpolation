//
//  SpringInterpolation.swift
//  SpringInterpolation
//
//  Created by QAQ on 2023/12/3.
//

import Foundation

public class SpringInterpolation {
    public private(set) var config: Configuration
    public private(set) var context: Context

    public var currentPos: Double { context.currentPos }
    public var currentVel: Double { context.currentVel }
    public var targetPos: Double { context.targetPos }

    public init(_ config: Configuration = .init()) {
        self.config = config
        context = config.generateInitialContext()
    }

    @discardableResult
    public func tik() -> Double {
        let ret = update(
            pos: context.currentPos,
            vel: context.currentVel,
            equilibriumPos: context.targetPos
        )
        context.currentPos = ret.newPos
        context.currentVel = ret.newVel
        return ret.newPos
    }

    public func setCurrent(_ pos: Double) {
        context.currentPos = pos
        context.currentVel = 0
    }

    public func setTarget(_ pos: Double) {
        context.targetPos = pos
    }

    private func update(pos: Double, vel: Double, equilibriumPos: Double) -> (newPos: Double, newVel: Double) {
        let oldPos = pos - equilibriumPos
        let oldVel = vel
        let newPos = oldPos * context.posPosCoef + oldVel * context.posVelCoef + equilibriumPos
        let newVel = oldPos * context.velPosCoef + oldVel * context.velVelCoef
        return (newPos, newVel)
    }
}
