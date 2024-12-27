//
//  CircularProgressView.swift
//  WireDrop
//
//  Created by Anton Meier on 2024-04-08.
//

import SwiftUI

// MARK: Initialization

struct CircularProgressView: View {
    let lineWidth: Double
    let progress: Double
    let color: Color = Colors.main
}

// MARK: Body

extension CircularProgressView {
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.25), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(progress != 0.0 ? .easeIn : .none, value: progress)
        }
    }
}
