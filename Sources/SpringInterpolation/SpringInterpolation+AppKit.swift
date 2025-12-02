//
//  SpringInterpolation+AppKit.swift
//  SpringInterpolation
//
//  Created by QAQ on 2023/12/3.
//

#if canImport(AppKit) && !targetEnvironment(macCatalyst)

    import AppKit

    /// A timing function that uses spring physics for smooth, natural animations.
    ///
    /// `SpringTimingFunction` provides a way to create spring-based timing curves
    /// that can be used with Core Animation. Unlike `CAMediaTimingFunction`,
    /// spring timing functions produce natural, physics-based motion.
    ///
    /// Example usage:
    /// ```swift
    /// let timing = SpringTimingFunction(angularFrequency: 10, dampingRatio: 0.75)
    /// let progress = timing.value(at: 0.5) // Get progress at 50% of duration
    /// ```
    public struct SpringTimingFunction: Equatable, Hashable {
        /// The spring configuration used for timing calculations.
        public let configuration: SpringInterpolation.Configuration

        /// The duration of the animation in seconds.
        public let duration: TimeInterval

        /// The number of samples used for timing curve calculation.
        /// Higher values provide more accurate timing at the cost of performance.
        public let sampleCount: Int

        /// Cached timing values for efficient lookup.
        private let timingValues: [Double]

        /// Creates a spring timing function with the specified parameters.
        ///
        /// - Parameters:
        ///   - dampingRatio: The damping ratio of the spring. Values less than 1 produce oscillation,
        ///                   equal to 1 produces critical damping, greater than 1 produces overdamping.
        ///   - duration: The duration of the animation in seconds. Defaults to 1.0.
        ///   - sampleCount: The number of samples for timing curve calculation. Defaults to 256.
        public init(
            dampingRatio: Double = SpringInterpolation.Configuration.defaultDampingRatio,
            duration: TimeInterval = 1.0,
            sampleCount: Int = 256,
        ) {
            // Angular frequency is redundant when fitting to duration, so we use a constant.
            configuration = .init(
                angularFrequency: 10.0,
                dampingRatio: dampingRatio,
                threshold: 0.0001,
                stopWhenHitTarget: true,
            )
            self.sampleCount = max(2, sampleCount)
            self.duration = duration

            // Calculate settling duration and use it for generating timing values
            // This ensures the animation curve represents the full spring motion,
            // which is then mapped to the user's requested duration.
            let settlingDuration = configuration.settlingDuration

            // If settling duration is invalid or too small, fallback to user duration
            let generationDuration = settlingDuration > 0 && settlingDuration < .infinity ? settlingDuration : duration

            timingValues = Self.generateTimingValues(
                configuration: configuration,
                duration: generationDuration,
                sampleCount: self.sampleCount,
            )
        }

        /// Creates a spring timing function from an existing configuration.
        ///
        /// - Parameters:
        ///   - configuration: The spring configuration to use.
        ///   - duration: The duration of the animation in seconds. Defaults to 1.0.
        ///   - sampleCount: The number of samples for timing curve calculation. Defaults to 256.
        public init(
            configuration: SpringInterpolation.Configuration,
            duration: TimeInterval = 1.0,
            sampleCount: Int = 256,
        ) {
            self.configuration = configuration
            self.sampleCount = max(2, sampleCount)
            self.duration = duration

            // Calculate settling duration and use it for generating timing values
            // This ensures the animation curve represents the full spring motion,
            // which is then mapped to the user's requested duration.
            let settlingDuration = configuration.settlingDuration

            // If settling duration is invalid or too small, fallback to user duration
            let generationDuration = settlingDuration > 0 && settlingDuration < .infinity ? settlingDuration : duration

            timingValues = Self.generateTimingValues(
                configuration: configuration,
                duration: generationDuration,
                sampleCount: self.sampleCount,
            )
        }

        /// Generates the timing values for the spring animation.
        private static func generateTimingValues(
            configuration: SpringInterpolation.Configuration,
            duration: TimeInterval,
            sampleCount: Int,
        ) -> [Double] {
            var spring = SpringInterpolation(config: configuration)
            spring.setCurrent(0)
            spring.setTarget(1)

            var values: [Double] = []
            values.reserveCapacity(sampleCount)

            let deltaTime = duration / Double(sampleCount - 1)

            for _ in 0 ..< sampleCount {
                values.append(spring.value)
                spring.update(withDeltaTime: deltaTime)
            }

            // Ensure the function ends at the target value
            if !values.isEmpty {
                values[values.count - 1] = 1.0
            }

            return values
        }

        /// Returns the timing value at the specified time fraction.
        ///
        /// - Parameter fraction: A value between 0 and 1 representing the fraction of the animation duration.
        /// - Returns: The timing value at the specified fraction, typically between 0 and 1.
        public func value(at fraction: Double) -> Double {
            guard !timingValues.isEmpty else { return fraction }

            let clampedFraction = max(0, min(1, fraction))
            let index = clampedFraction * Double(timingValues.count - 1)
            let lowerIndex = Int(index)
            let upperIndex = min(lowerIndex + 1, timingValues.count - 1)

            if lowerIndex == upperIndex {
                return timingValues[lowerIndex]
            }

            let interpolation = index - Double(lowerIndex)
            return timingValues[lowerIndex] + (timingValues[upperIndex] - timingValues[lowerIndex]) * interpolation
        }

        /// Returns the timing value at the specified time.
        ///
        /// - Parameter time: The time in seconds from the start of the animation.
        /// - Returns: The timing value at the specified time, typically between 0 and 1.
        public func value(atTime time: TimeInterval) -> Double {
            value(at: time / duration)
        }
    }

    // MARK: - Preset Timing Functions

    public extension SpringTimingFunction {
        /// A timing function suitable for interface animations.
        /// Uses higher angular frequency and moderate damping for snappy, responsive feel.
        static let interface = SpringTimingFunction(
            dampingRatio: 0.75,
            duration: 0.5,
        )

        /// A timing function suitable for drag animations.
        /// Uses moderate angular frequency and lower damping for fluid, natural motion.
        static let drag = SpringTimingFunction(
            dampingRatio: 0.7,
            duration: 0.6,
        )

        /// A timing function with gentle spring motion.
        /// Suitable for subtle, non-intrusive animations.
        static let gentle = SpringTimingFunction(
            dampingRatio: 0.9,
            duration: 0.8,
        )

        /// A timing function with bouncy spring motion.
        /// Suitable for playful, attention-grabbing animations.
        static let bouncy = SpringTimingFunction(
            dampingRatio: 0.5,
            duration: 0.7,
        )

        /// A timing function with stiff spring motion.
        /// Suitable for quick, precise animations.
        static let stiff = SpringTimingFunction(
            dampingRatio: 0.85,
            duration: 0.4,
        )
    }

    // MARK: - NSAnimation Integration

    public extension SpringTimingFunction {
        /// Converts the spring timing function to an `NSAnimation.Progress` array.
        ///
        /// - Parameter count: The number of progress values to generate.
        /// - Returns: An array of progress values suitable for use with `NSAnimation`.
        func progressValues(count: Int = 10) -> [NSAnimation.Progress] {
            guard count > 0 else { return [] }

            var values: [NSAnimation.Progress] = []
            values.reserveCapacity(count)

            for i in 0 ..< count {
                let fraction = Double(i) / Double(count - 1)
                values.append(NSAnimation.Progress(value(at: fraction)))
            }

            return values
        }
    }

    // MARK: - CAAnimation Integration

    public extension SpringTimingFunction {
        /// Creates a `CAKeyframeAnimation` with spring timing.
        ///
        /// - Parameters:
        ///   - keyPath: The key path of the property to animate.
        ///   - fromValue: The starting value of the animation.
        ///   - toValue: The ending value of the animation.
        ///   - keyframeCount: The number of keyframes to generate. Defaults to 60.
        /// - Returns: A configured `CAKeyframeAnimation` with spring timing.
        func keyframeAnimation(
            keyPath: String,
            from fromValue: CGFloat,
            to toValue: CGFloat,
            keyframeCount: Int = 60,
        ) -> CAKeyframeAnimation {
            let animation = CAKeyframeAnimation(keyPath: keyPath)
            animation.duration = duration

            var values: [CGFloat] = []
            var keyTimes: [NSNumber] = []

            for i in 0 ..< keyframeCount {
                let fraction = Double(i) / Double(keyframeCount - 1)
                let springValue = value(at: fraction)
                let interpolatedValue = fromValue + (toValue - fromValue) * CGFloat(springValue)

                values.append(interpolatedValue)
                keyTimes.append(NSNumber(value: fraction))
            }

            animation.values = values
            animation.keyTimes = keyTimes
            animation.calculationMode = .linear

            return animation
        }

        /// Creates a `CAKeyframeAnimation` for position with spring timing.
        ///
        /// - Parameters:
        ///   - from: The starting position.
        ///   - to: The ending position.
        ///   - keyframeCount: The number of keyframes to generate. Defaults to 60.
        /// - Returns: A configured `CAKeyframeAnimation` for position with spring timing.
        func positionAnimation(
            from: CGPoint,
            to: CGPoint,
            keyframeCount: Int = 60,
        ) -> CAKeyframeAnimation {
            let animation = CAKeyframeAnimation(keyPath: "position")
            animation.duration = duration

            var values: [NSValue] = []
            var keyTimes: [NSNumber] = []

            for i in 0 ..< keyframeCount {
                let fraction = Double(i) / Double(keyframeCount - 1)
                let springValue = value(at: fraction)

                let x = from.x + (to.x - from.x) * CGFloat(springValue)
                let y = from.y + (to.y - from.y) * CGFloat(springValue)

                values.append(NSValue(point: NSPoint(x: x, y: y)))
                keyTimes.append(NSNumber(value: fraction))
            }

            animation.values = values
            animation.keyTimes = keyTimes
            animation.calculationMode = .linear

            return animation
        }

        /// Creates a `CAKeyframeAnimation` for transform scale with spring timing.
        ///
        /// - Parameters:
        ///   - from: The starting scale.
        ///   - to: The ending scale.
        ///   - keyframeCount: The number of keyframes to generate. Defaults to 60.
        /// - Returns: A configured `CAKeyframeAnimation` for transform.scale with spring timing.
        func scaleAnimation(
            from: CGFloat,
            to: CGFloat,
            keyframeCount: Int = 60,
        ) -> CAKeyframeAnimation {
            keyframeAnimation(
                keyPath: "transform.scale",
                from: from,
                to: to,
                keyframeCount: keyframeCount,
            )
        }

        /// Creates a `CAKeyframeAnimation` for opacity with spring timing.
        ///
        /// - Parameters:
        ///   - from: The starting opacity.
        ///   - to: The ending opacity.
        ///   - keyframeCount: The number of keyframes to generate. Defaults to 60.
        /// - Returns: A configured `CAKeyframeAnimation` for opacity with spring timing.
        func opacityAnimation(
            from: CGFloat,
            to: CGFloat,
            keyframeCount: Int = 60,
        ) -> CAKeyframeAnimation {
            keyframeAnimation(
                keyPath: "opacity",
                from: from,
                to: to,
                keyframeCount: keyframeCount,
            )
        }
    }

    // MARK: - NSView Animation Extension

    public extension NSView {
        /// Animates the view's frame using spring timing.
        ///
        /// - Parameters:
        ///   - frame: The target frame.
        ///   - timing: The spring timing function to use.
        ///   - completion: A closure to execute when the animation completes.
        func animate(
            to frame: NSRect,
            timing: SpringTimingFunction,
            completion: (() -> Void)? = nil,
        ) {
            let fromFrame = self.frame

            CATransaction.begin()
            CATransaction.setCompletionBlock(completion)

            // Animate bounds
            let boundsAnimation = CAKeyframeAnimation(keyPath: "bounds")
            boundsAnimation.duration = timing.duration

            var boundsValues: [NSValue] = []
            var keyTimes: [NSNumber] = []
            let keyframeCount = 60

            for i in 0 ..< keyframeCount {
                let fraction = Double(i) / Double(keyframeCount - 1)
                let springValue = timing.value(at: fraction)

                let width = fromFrame.width + (frame.width - fromFrame.width) * CGFloat(springValue)
                let height = fromFrame.height + (frame.height - fromFrame.height) * CGFloat(springValue)

                boundsValues.append(NSValue(rect: NSRect(x: 0, y: 0, width: width, height: height)))
                keyTimes.append(NSNumber(value: fraction))
            }

            boundsAnimation.values = boundsValues
            boundsAnimation.keyTimes = keyTimes
            boundsAnimation.calculationMode = .linear

            // Animate position
            let positionAnimation = timing.positionAnimation(
                from: CGPoint(x: fromFrame.midX, y: fromFrame.midY),
                to: CGPoint(x: frame.midX, y: frame.midY),
            )

            layer?.add(boundsAnimation, forKey: "springBounds")
            layer?.add(positionAnimation, forKey: "springPosition")

            // Set final values
            self.frame = frame

            CATransaction.commit()
        }

        /// Animates the view's alpha using spring timing.
        ///
        /// - Parameters:
        ///   - alpha: The target alpha value.
        ///   - timing: The spring timing function to use.
        ///   - completion: A closure to execute when the animation completes.
        func animate(
            toAlpha alpha: CGFloat,
            timing: SpringTimingFunction,
            completion: (() -> Void)? = nil,
        ) {
            guard let layer else {
                alphaValue = alpha
                completion?()
                return
            }

            CATransaction.begin()
            CATransaction.setCompletionBlock(completion)

            let animation = timing.opacityAnimation(
                from: CGFloat(layer.opacity),
                to: alpha,
            )

            layer.add(animation, forKey: "springOpacity")
            layer.opacity = Float(alpha)

            CATransaction.commit()
        }
    }

#endif
