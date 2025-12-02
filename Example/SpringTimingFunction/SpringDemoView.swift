//
//  SpringDemoView.swift
//  SpringTimingFunction
//
//  Created by qaq on 2/12/2025.
//

import AppKit
import SpringInterpolation

// MARK: - Spring Demo View

class SpringDemoView: NSView {
    // MARK: - UI Components

    private let animatedBox = NSView()
    private let curveView = SpringCurveView()

    private let dampingSlider = NSSlider()
    private let durationSlider = NSSlider()

    private let dampingLabel = NSTextField(labelWithString: "Damping Ratio: 0.75")
    private let durationLabel = NSTextField(labelWithString: "Duration: 0.5s")

    private let animateButton = NSButton(title: "Animate", target: nil, action: nil)
    private let resetButton = NSButton(title: "Reset", target: nil, action: nil)

    private let presetPopup = NSPopUpButton()

    // MARK: - State

    private var currentTiming = SpringTimingFunction.interface
    private var displayLink: CVDisplayLink?
    private var animationStartTime: CFTimeInterval = 0
    private var isAnimating = false
    private var animationFromX: CGFloat = 50
    private var animationToX: CGFloat = 0

    // MARK: - Initialization

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()
        setupDisplayLink()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        stopDisplayLink()
    }

    // MARK: - Setup

    private func setupUI() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

        // Animated box
        animatedBox.wantsLayer = true
        animatedBox.layer?.backgroundColor = NSColor.systemBlue.cgColor
        animatedBox.layer?.cornerRadius = 8
        addSubview(animatedBox)

        // Curve view
        curveView.wantsLayer = true
        curveView.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        curveView.layer?.cornerRadius = 8
        curveView.layer?.borderWidth = 1
        curveView.layer?.borderColor = NSColor.separatorColor.cgColor
        addSubview(curveView)

        // Sliders
        setupSlider(dampingSlider, min: 0.1, max: 2.0, value: 0.75)
        setupSlider(durationSlider, min: 0.1, max: 2.0, value: 0.5)

        dampingSlider.target = self
        dampingSlider.action = #selector(sliderChanged)
        durationSlider.target = self
        durationSlider.action = #selector(sliderChanged)

        addSubview(dampingSlider)
        addSubview(durationSlider)
        addSubview(dampingLabel)
        addSubview(durationLabel)

        // Buttons
        animateButton.bezelStyle = .rounded
        animateButton.target = self
        animateButton.action = #selector(animatePressed)
        addSubview(animateButton)

        resetButton.bezelStyle = .rounded
        resetButton.target = self
        resetButton.action = #selector(resetPressed)
        addSubview(resetButton)

        // Preset popup
        presetPopup.addItems(withTitles: ["Interface", "Drag", "Gentle", "Bouncy", "Stiff"])
        presetPopup.target = self
        presetPopup.action = #selector(presetChanged)
        addSubview(presetPopup)

        updateTimingFunction()
    }

    private func setupSlider(_ slider: NSSlider, min: Double, max: Double, value: Double) {
        slider.minValue = min
        slider.maxValue = max
        slider.doubleValue = value
        slider.isContinuous = true
    }

    private func setupDisplayLink() {
        CVDisplayLinkCreateWithActiveCGDisplays(&displayLink)
        guard let displayLink else { return }

        let callback: CVDisplayLinkOutputCallback = { _, _, _, _, _, userInfo in
            let view = Unmanaged<SpringDemoView>.fromOpaque(userInfo!).takeUnretainedValue()
            DispatchQueue.main.async {
                view.updateAnimation()
            }
            return kCVReturnSuccess
        }

        CVDisplayLinkSetOutputCallback(displayLink, callback, Unmanaged.passUnretained(self).toOpaque())
    }

    private func stopDisplayLink() {
        guard let displayLink else { return }
        CVDisplayLinkStop(displayLink)
    }

    // MARK: - Layout

    override func layout() {
        super.layout()

        let padding: CGFloat = 20
        let sliderHeight: CGFloat = 22
        let labelHeight: CGFloat = 17
        let buttonHeight: CGFloat = 32
        let spacing: CGFloat = 12

        // Curve view (top half)
        let curveHeight = bounds.height * 0.4
        curveView.frame = NSRect(
            x: padding,
            y: bounds.height - padding - curveHeight,
            width: bounds.width - padding * 2,
            height: curveHeight,
        )

        // Animation area
        let animationAreaTop = curveView.frame.minY - padding
        let animationAreaHeight: CGFloat = 80
        let boxSize: CGFloat = 50

        animatedBox.frame = NSRect(
            x: animationFromX,
            y: animationAreaTop - animationAreaHeight / 2 - boxSize / 2,
            width: boxSize,
            height: boxSize,
        )

        animationToX = bounds.width - padding - boxSize

        // Controls area
        var y = animatedBox.frame.minY - padding * 2

        // Preset popup
        y -= buttonHeight
        presetPopup.frame = NSRect(x: padding, y: y, width: 150, height: buttonHeight)

        // Damping
        y -= spacing + labelHeight
        dampingLabel.frame = NSRect(x: padding, y: y, width: 200, height: labelHeight)
        y -= sliderHeight
        dampingSlider.frame = NSRect(x: padding, y: y, width: bounds.width - padding * 2, height: sliderHeight)

        // Duration
        y -= spacing + labelHeight
        durationLabel.frame = NSRect(x: padding, y: y, width: 200, height: labelHeight)
        y -= sliderHeight
        durationSlider.frame = NSRect(x: padding, y: y, width: bounds.width - padding * 2, height: sliderHeight)

        // Buttons
        y -= spacing + buttonHeight
        let buttonWidth: CGFloat = 100
        animateButton.frame = NSRect(x: padding, y: y, width: buttonWidth, height: buttonHeight)
        resetButton.frame = NSRect(x: padding + buttonWidth + spacing, y: y, width: buttonWidth, height: buttonHeight)
    }

    // MARK: - Actions

    @objc private func sliderChanged(_: NSSlider) {
        updateTimingFunction()
        updateLabels()
    }

    @objc private func presetChanged(_: NSPopUpButton) {
        let presets: [SpringTimingFunction] = [.interface, .drag, .gentle, .bouncy, .stiff]
        let preset = presets[presetPopup.indexOfSelectedItem]

        dampingSlider.doubleValue = preset.configuration.dampingRatio
        durationSlider.doubleValue = preset.duration

        updateTimingFunction()
        updateLabels()
    }

    @objc private func animatePressed(_: NSButton) {
        startAnimation()
    }

    @objc private func resetPressed(_: NSButton) {
        stopDisplayLink()
        isAnimating = false
        animatedBox.frame.origin.x = animationFromX
    }

    // MARK: - Animation

    private func updateTimingFunction() {
        currentTiming = SpringTimingFunction(
            dampingRatio: dampingSlider.doubleValue,
            duration: durationSlider.doubleValue,
        )
        curveView.timingFunction = currentTiming
        curveView.needsDisplay = true
    }

    private func updateLabels() {
        dampingLabel.stringValue = String(format: "Damping Ratio: %.2f", dampingSlider.doubleValue)
        durationLabel.stringValue = String(format: "Duration: %.2fs", durationSlider.doubleValue)
    }

    private func startAnimation() {
        guard !isAnimating else { return }

        isAnimating = true
        animationStartTime = CACurrentMediaTime()

        // Toggle direction
        let currentX = animatedBox.frame.origin.x
        if abs(currentX - animationFromX) < 1 {
            // At start, animate to end
        } else {
            // Swap
            swap(&animationFromX, &animationToX)
        }

        if let displayLink {
            CVDisplayLinkStart(displayLink)
        }
    }

    private func updateAnimation() {
        guard isAnimating else { return }

        let elapsed = CACurrentMediaTime() - animationStartTime
        let fraction = min(1.0, elapsed / currentTiming.duration)
        let springValue = currentTiming.value(at: fraction)

        let newX = animationFromX + (animationToX - animationFromX) * CGFloat(springValue)
        animatedBox.frame.origin.x = newX

        curveView.currentProgress = fraction
        curveView.needsDisplay = true

        if fraction >= 1.0 {
            isAnimating = false
            stopDisplayLink()
            swap(&animationFromX, &animationToX)
        }
    }
}

// MARK: - Spring Curve View

class SpringCurveView: NSView {
    var timingFunction: SpringTimingFunction = .interface
    var currentProgress: Double = 0

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard let context = NSGraphicsContext.current?.cgContext else { return }

        let padding: CGFloat = 30
        let graphRect = bounds.insetBy(dx: padding, dy: padding)
        let maxYValue: CGFloat = 2.0

        // Draw grid
        context.setStrokeColor(NSColor.separatorColor.cgColor)
        context.setLineWidth(0.5)

        for i in 0 ... 10 {
            let x = graphRect.minX + graphRect.width * CGFloat(i) / 10
            context.move(to: CGPoint(x: x, y: graphRect.minY))
            context.addLine(to: CGPoint(x: x, y: graphRect.maxY))

            let y = graphRect.minY + graphRect.height * CGFloat(i) / 10
            context.move(to: CGPoint(x: graphRect.minX, y: y))
            context.addLine(to: CGPoint(x: graphRect.maxX, y: y))
        }
        context.strokePath()

        // Draw axes
        context.setStrokeColor(NSColor.labelColor.cgColor)
        context.setLineWidth(1)
        context.move(to: CGPoint(x: graphRect.minX, y: graphRect.minY))
        context.addLine(to: CGPoint(x: graphRect.maxX, y: graphRect.minY))
        context.move(to: CGPoint(x: graphRect.minX, y: graphRect.minY))
        context.addLine(to: CGPoint(x: graphRect.minX, y: graphRect.maxY))
        context.strokePath()

        // Draw spring curve
        context.setStrokeColor(NSColor.systemBlue.cgColor)
        context.setLineWidth(2)

        let steps = 200
        for i in 0 ... steps {
            let fraction = Double(i) / Double(steps)
            let value = timingFunction.value(at: fraction)

            let x = graphRect.minX + graphRect.width * CGFloat(fraction)
            let y = graphRect.minY + graphRect.height * CGFloat(value) / maxYValue

            if i == 0 {
                context.move(to: CGPoint(x: x, y: y))
            } else {
                context.addLine(to: CGPoint(x: x, y: y))
            }
        }
        context.strokePath()

        // Draw linear reference
        context.setStrokeColor(NSColor.systemGray.withAlphaComponent(0.5).cgColor)
        context.setLineWidth(1)
        context.setLineDash(phase: 0, lengths: [4, 4])
        context.move(to: CGPoint(x: graphRect.minX, y: graphRect.minY))
        let refY = graphRect.minY + graphRect.height * (1.0 / maxYValue)
        context.addLine(to: CGPoint(x: graphRect.maxX, y: refY))
        context.strokePath()
        context.setLineDash(phase: 0, lengths: [])

        // Draw 1.0 line
        context.setStrokeColor(NSColor.systemRed.withAlphaComponent(0.3).cgColor)
        context.setLineWidth(1)
        context.move(to: CGPoint(x: graphRect.minX, y: refY))
        context.addLine(to: CGPoint(x: graphRect.maxX, y: refY))
        context.strokePath()

        // Draw current progress indicator
        if currentProgress > 0, currentProgress < 1 {
            let value = timingFunction.value(at: currentProgress)
            let x = graphRect.minX + graphRect.width * CGFloat(currentProgress)
            let y = graphRect.minY + graphRect.height * CGFloat(value) / maxYValue

            context.setFillColor(NSColor.systemRed.cgColor)
            context.fillEllipse(in: CGRect(x: x - 5, y: y - 5, width: 10, height: 10))
        }

        // Draw labels
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 10),
            .foregroundColor: NSColor.secondaryLabelColor,
        ]

        "0".draw(at: CGPoint(x: graphRect.minX - 10, y: graphRect.minY - 15), withAttributes: attributes)
        "1".draw(at: CGPoint(x: graphRect.minX - 10, y: refY - 5), withAttributes: attributes)
        "2".draw(at: CGPoint(x: graphRect.minX - 10, y: graphRect.maxY - 5), withAttributes: attributes)
        "Time".draw(at: CGPoint(x: graphRect.maxX - 20, y: graphRect.minY - 15), withAttributes: attributes)
        "Value".draw(at: CGPoint(x: graphRect.minX + 5, y: graphRect.maxY + 5), withAttributes: attributes)
    }
}
