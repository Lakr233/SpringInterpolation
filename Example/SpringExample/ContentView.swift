//
//  ContentView.swift
//  SpringExample
//
//  Created by QAQ on 2023/12/3.
//

import Combine
import SpringInterpolation
import SwiftUI

let ball: Double = 16

struct ContentView: View {
    @State var target: CGPoint = .zero
    @State var offset: CGPoint = .zero

    @State var springEngine: SpringInterpolation2D = .init()
    @State var lastUpdate: Date = .init()
    let timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()

    @AppStorage("dampingRatio")
    var dampingRatio: Double = SpringInterpolation.Configuration.defaultDampingRatio
    @AppStorage("angularFrequency")
    var angularFrequency: Double = SpringInterpolation.Configuration.defaultAngularFrequency

    @AppStorage("stopWhenHitTarget")
    var stopWhenHitTarget: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            Text("Spring Interpolation Engine 2D")
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .padding()
            Divider()
            panel.padding()
            Divider()
            control.padding()
            Divider()
            runtimeDiag.padding()
        }
        .ignoresSafeArea()
        .onAppear { updateConfig() }
        .onChange(of: dampingRatio) { _, _ in
            updateConfig()
        }
        .onChange(of: angularFrequency) { _, _ in
            updateConfig()
        }
        .onReceive(timer) { _ in
            defer { lastUpdate = .init() }
            springEngine.setTarget(.init(x: target.x, y: target.y))
            let ret = springEngine.update(withDeltaTime: -lastUpdate.timeIntervalSinceNow)
            offset = .init(x: ret.x, y: ret.y)
        }
    }

    var panel: some View {
        GeometryReader { r in
            ZStack(alignment: .topLeading) {
                Rectangle()
                    .opacity(0)
                    .onChange(of: r.size) { _, newValue in
                        let x = newValue.width / 2 - ball / 2
                        let y = newValue.height / 2 - ball / 2
                        springEngine.setCurrent(.init(x: x, y: y))
                        let point = CGPoint(x: x, y: y)
                        target = point
                        offset = point
                    }

                Path { path in
                    path.move(to: offset)
                    path.addLine(to: target)
                }
                .stroke(
                    .green.opacity(0.25),
                    lineWidth: CGFloat(max(1, deformationVisualState.amount * 18)),
                )

                Circle()
                    .frame(width: ball, height: ball)
                    .foregroundStyle(.red.opacity(0.5))
                    .offset(x: target.x, y: target.y)

                Circle()
                    .frame(width: ball, height: ball)
                    .foregroundStyle(.green.opacity(0.6))
                    .scaleEffect(
                        x: deformationVisualState.scaleX,
                        y: deformationVisualState.scaleY,
                        anchor: .center,
                    )
                    .rotationEffect(deformationVisualState.angle)
                    .offset(x: offset.x, y: offset.y)
                    .shadow(
                        color: .green.opacity(0.35),
                        radius: max(2, deformationVisualState.amount * 16),
                        x: 0,
                        y: deformationVisualState.amount * 8,
                    )

                Text("deformation \(deformationVisualState.amount, specifier: "%.3f")")
                    .font(.system(.footnote, design: .rounded, weight: .semibold))
                    .padding(8)
                    .background(.thinMaterial, in: Capsule())
                    .padding()
                    .allowsHitTesting(false)
            }
            .contentShape(Rectangle())
            .highPriorityGesture(DragGesture()
                .onChanged { gesture in
                    target = .init(x: gesture.location.x - ball / 2, y: gesture.location.y - ball / 2)
                })
        }
    }

    var control: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Slider(value: $dampingRatio, in: 0.00001 ... 1, step: 0.1) {
                    Text("Damping Ratio \(dampingRatio, specifier: "%.2f")")
                        .frame(width: 200, alignment: .leading)
                } onEditingChanged: { _ in }
                Slider(value: $angularFrequency, in: 0.00001 ... 10, step: 0.25) {
                    Text("Angular Frequency \(angularFrequency, specifier: "%.2f")")
                        .frame(width: 200, alignment: .leading)
                } onEditingChanged: { _ in }
                Toggle("Stop When Hit Target", isOn: $stopWhenHitTarget)
            }
        }
        .font(.system(.footnote, design: .monospaced, weight: .regular))
    }

    var runtimeDiag: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("x.pos")
                    Spacer()
                    Text("\(springEngine.x.context.currentPos, specifier: "%.2f")")
                }
                HStack {
                    Text("x.vel")
                    Spacer()
                    Text("\(springEngine.x.context.currentVel, specifier: "%.2f")")
                }
                HStack {
                    Text("x.acc")
                    Spacer()
                    Text("\(springEngine.x.context.currentAcceleration, specifier: "%.3f")")
                }
                HStack {
                    Text("x.velDiff")
                    Spacer()
                    Text("\(springEngine.x.context.velocityDelta, specifier: "%.3f")")
                }
                HStack {
                    Text("x.accDiff")
                    Spacer()
                    Text("\(springEngine.x.context.accelerationDelta, specifier: "%.3f")")
                }
                HStack {
                    Text("x.def")
                    Spacer()
                    Text("\(springEngine.x.deformation, specifier: "%.3f")")
                }
                HStack {
                    Text("x.target")
                    Spacer()
                    Text("\(springEngine.x.context.targetPos, specifier: "%.2f")")
                }
                HStack {
                    Text("x.threshold")
                    Spacer()
                    Text("\(springEngine.x.config.threshold, specifier: "%.5f")")
                }
                HStack {
                    Text("x.completed")
                    Spacer()
                    Text("\(springEngine.x.completed ? "YES" : "NO")")
                }
            }
            Spacer().padding(.horizontal)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("y.pos")
                    Spacer()
                    Text("\(springEngine.y.context.currentPos, specifier: "%.2f")")
                }
                HStack {
                    Text("y.vel")
                    Spacer()
                    Text("\(springEngine.y.context.currentVel, specifier: "%.2f")")
                }
                HStack {
                    Text("y.acc")
                    Spacer()
                    Text("\(springEngine.y.context.currentAcceleration, specifier: "%.3f")")
                }
                HStack {
                    Text("y.velDiff")
                    Spacer()
                    Text("\(springEngine.y.context.velocityDelta, specifier: "%.3f")")
                }
                HStack {
                    Text("y.accDiff")
                    Spacer()
                    Text("\(springEngine.y.context.accelerationDelta, specifier: "%.3f")")
                }
                HStack {
                    Text("y.def")
                    Spacer()
                    Text("\(springEngine.y.deformation, specifier: "%.3f")")
                }
                HStack {
                    Text("y.target")
                    Spacer()
                    Text("\(springEngine.y.context.targetPos, specifier: "%.2f")")
                }
                HStack {
                    Text("y.threshold")
                    Spacer()
                    Text("\(springEngine.y.config.threshold, specifier: "%.5f")")
                }
                HStack {
                    Text("y.completed")
                    Spacer()
                    Text("\(springEngine.y.completed ? "YES" : "NO")")
                }
            }
        }
        .font(.system(.footnote, design: .monospaced, weight: .regular))
    }

    func updateConfig() {
        springEngine.setConfig(.init(
            angularFrequency: angularFrequency,
            dampingRatio: dampingRatio,
            threshold: 0.00001,
            stopWhenHitTarget: stopWhenHitTarget,
        ))
    }

    var deformationVisualState: (scaleX: CGFloat, scaleY: CGFloat, angle: Angle, amount: Double) {
        let amount = springEngine.deformationMagnitude
        let velocity = springEngine.velocity
        let stretch = 1 + amount * 0.85
        let squash = max(0.55, 1 - amount * 0.65)
        return (
            scaleX: CGFloat(stretch),
            scaleY: CGFloat(squash),
            angle: velocityAngle(for: velocity),
            amount: amount,
        )
    }

    func velocityAngle(for velocity: SpringInterpolation2D.Vec2D) -> Angle {
        let magnitude = hypot(velocity.x, velocity.y)
        guard magnitude > 0.0001 else { return .zero }
        return .radians(atan2(velocity.y, velocity.x))
    }
}
