//
//  SpringInterpolation+Configuration.swift
//  SpringInterpolation
//
//  Created by QAQ on 2023/12/3.
//

import Foundation

public extension SpringInterpolation {
    struct Configuration: Equatable, Hashable {
        public var angularFrequency: Double
        public var dampingRatio: Double
        public var threshold: Double
        public var stopWhenHitTarget: Bool

        public static let defaultAngularFrequency: Double = 4
        public static let defaultDampingRatio: Double = 1

        public init(
            angularFrequency: Double = defaultAngularFrequency,
            dampingRatio: Double = defaultDampingRatio,
            threshold: Double = 0.0001,
            stopWhenHitTarget: Bool = false,
        ) {
            self.angularFrequency = angularFrequency
            self.dampingRatio = dampingRatio
            self.threshold = threshold
            self.stopWhenHitTarget = stopWhenHitTarget

            assert(angularFrequency > 0)
            assert(dampingRatio > 0)
            assert(threshold >= 0)
        }
    }
}

public extension SpringInterpolation.Configuration {
    static let forInterfaceAnimation: Self = .init(
        angularFrequency: 10,
        dampingRatio: 0.75,
        threshold: 1,
        stopWhenHitTarget: true,
    )

    static let forDragAnimation: Self = .init(
        angularFrequency: 8,
        dampingRatio: 0.7,
        threshold: 1,
        stopWhenHitTarget: false,
    )
}

public extension SpringInterpolation.Configuration {
    var settlingDuration: TimeInterval {
        if angularFrequency == 0 { return 0 }

        // We want to find t such that the envelope is approximately equal to threshold.
        // Note: This is an approximation.
        let targetThreshold = max(threshold, .ulpOfOne)

        if dampingRatio < 1.0 {
            // Underdamped: Envelope is exp(-dampingRatio * angularFrequency * t)
            // We use a slightly more conservative estimate by considering the pre-factor is 1.
            // Ideally we should solve for the exact envelope but this is good enough for estimation.
            if dampingRatio == 0 { return .infinity }
            return -log(targetThreshold) / (dampingRatio * angularFrequency)
        } else if dampingRatio > 1.0 {
            // Overdamped: Dominant decay is exp((-zeta + sqrt(zeta^2 - 1)) * omega * t)
            let lambda = -angularFrequency * (dampingRatio - sqrt(dampingRatio * dampingRatio - 1.0))
            return log(targetThreshold) / lambda
        } else {
            // Critically damped: Envelope is (1 + omega * t) * exp(-omega * t)
            // This is harder to invert. We approximate with exp(-omega * t) * (something).
            // Let's just use the exponential decay part with a safety factor.
            return -log(targetThreshold) / angularFrequency
        }
    }
}
