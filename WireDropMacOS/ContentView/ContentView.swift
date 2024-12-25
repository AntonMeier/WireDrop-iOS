//
//  ContentView.swift
//  WireDropMacOS
//
//  Created by Anton Meier on 2024-03-29.
//

import Cocoa
import SwiftUI

// MARK: Initialization

struct ContentView: View {
    @StateObject private var viewModel: ContentViewModel
    @State private var isTargeted = false

    init(viewModel: ContentViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
}

// MARK: Body

extension ContentView {
    var body: some View {
        VStack(spacing: 16) {
            contentView
            infoCardView
        }
        .frame(width: 500)
        .padding(.horizontal, 0)
        .padding(.vertical, 16)
    }
}

// MARK: Views

private extension ContentView {
    @ViewBuilder
    var infoCardView: some View {
        if !viewModel.state.isConnected {
            ZStack {
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.General.Label.cantSeeYourDevice)
                            .font(.system(size: 15))
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)

                        Text(L10n.General.Label.openAppOnIos)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .lineSpacing(4.0)
                            .lineLimit(2)
                            .frame(height: 40)
                    }

                    Spacer()

                    Image(systemName: viewModel.state.deviceImageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .font(Font.system(size: 50, weight: .thin))
                        .frame(width: 50, height: 50)
                        .foregroundColor(.secondary).opacity(0.60)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
            }
            .background(.tertiary.opacity(0.25))
            .cornerRadius(9.0)
            .padding([.top, .bottom], 0)
            .padding(.horizontal, 16)
        }
    }

    @ViewBuilder
    var contentView: some View {
        if viewModel.state.isConnected {
            deviceView
        } else {
            emptyDeviceView
        }
    }

    var deviceView: some View {
        ZStack {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .frame(width: 60, height: 60)
                        .foregroundColor(viewModel.state.remoteClientType == .app ? Colors.main : .white)

                    Image(systemName: viewModel.state.deviceImageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .fontWeight(.light)
                        .frame(height: 38)
                        .foregroundColor(viewModel.state.remoteClientType == .app ? .white : Colors.main)
                        .padding(.leading, 1)

                    if viewModel.state.remoteClientType == .app {
                        CircularProgressView(lineWidth: 3, progress: viewModel.state.transferProgress)
                            .frame(width: 70, height: 70)
                            .opacity(viewModel.state.isProgressBarHidden ? 0.0 : 1.0)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.state.hostNames.remote)
                        .font(.system(size: 15))
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    Text(
                        viewModel.state.remoteClientType == .appExtension
                            ? viewModel.state.transferState.receiverTitle
                            : viewModel.state.transferState.macSenderTitle
                    )
                    .font(.system(size: 14))
                    .foregroundColor(viewModel.state.transferState.tintColor)
                    .lineSpacing(4.0)

                    if viewModel.state.remoteClientType == .appExtension {
                        ProgressView(value: viewModel.state.transferProgress)
                            .animation(viewModel.state.progressAnimationType, value: viewModel.state.transferProgress)
                            .tint(Colors.main)
                            .padding(.top, 4)
                    }
                }

                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .overlay { dragAndDropOverlayView }
            .animation(.default, value: isTargeted)
        }
        .background(.tertiary.opacity(0.25))
        .cornerRadius(9.0)
        .padding(.vertical, 0)
        .padding(.horizontal, 16)
        .onDrop(of: [.content], isTargeted: $isTargeted, perform: viewModel.didDropProviders)
    }

    var emptyDeviceView: some View {
        HStack(spacing: 0) {
            Text(L10n.General.Label.waitingForDevice)
                .font(.system(size: 13))
                .foregroundColor(.secondary)

            Spacer()

            ProgressView()
                .controlSize(.small)
        }
        .padding(.horizontal, 32)
    }

    @ViewBuilder
    var dragAndDropOverlayView: some View {
        if isTargeted, viewModel.state.remoteClientType == .app {
            ZStack {
                Colors.main.opacity(0.20)

                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        Spacer()

                        Image(systemName: viewModel.state.addImageName)
                            .font(.system(size: 18))
                            .fontWeight(.medium)
                            .padding(.all, 12)
                    }

                    Spacer()
                }
                .font(.largeTitle)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.trailing)
            }
        }
    }
}
