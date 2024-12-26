//
//  FeedbackGenerator.swift
//  WireDrop
//
//  Created by Anton Meier on 2024-12-22.
//

import UIKit

// MARK: Initialization

struct FeedbackGenerator {
    private let generator = UIImpactFeedbackGenerator()
    private let notificationGenerator = UINotificationFeedbackGenerator()
}

// MARK: Public Methods

extension FeedbackGenerator {
    func notification() {
        notificationGenerator.notificationOccurred(.success)
    }

    func impact() {
        generator.impactOccurred(intensity: 0.5)
    }
}
