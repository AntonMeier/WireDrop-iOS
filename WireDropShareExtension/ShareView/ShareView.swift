//
//  ShareView.swift
//  WireDropShareExtension
//
//  Created by Anton Meier on 2024-03-29.
//

import SwiftUI

// MARK: Initialization

struct ShareView: View {
    @StateObject private var viewModel: ShareViewModel

    init(viewModel: ShareViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
}

// MARK: Body

extension ShareView {
    var body: some View {
        VStack(spacing: 0) {
            toolbarView
            Divider()
            devicesView
            Spacer()
            infoCardView
            Divider()
            footerView
        }
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
    }
}

// MARK: Views

private extension ShareView {
    var toolbarView: some View {
        HStack(spacing: 0) {
            appExtensionToolbarView
            appToolbarView
        }
        .padding([.horizontal, .bottom], 16)
        .padding(.top, 10)
    }

    @ViewBuilder
    var appExtensionToolbarView: some View {
        if viewModel.state.localClientType == .appExtension {
            ZStack {
                Text(L10n.General.Label.sendCopyWith)
                    .font(.headline)
                    .fontWeight(.regular)

                HStack(spacing: 0) {
                    Spacer()
                    Button(L10n.General.Button.done) { viewModel.didTapDone() }
                        .fontWeight(.medium)
                        .tint(Colors.main)
                }
            }
        }
    }

    @ViewBuilder
    var appToolbarView: some View {
        if viewModel.state.localClientType == .app {
            Text(L10n.General.Constants.appName)
                .font(.headline)
                .fontWeight(.regular)
        }
    }

    @ViewBuilder
    var devicesView: some View {
        appExtensionDevicesView
        appDevicesView
    }

    @ViewBuilder
    var appExtensionDevicesView: some View {
        if viewModel.state.localClientType == .appExtension {
            HStack(spacing: 12) {
                Text(L10n.General.Label.devices)
                    .font(.title2)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)

            HStack(spacing: 12) {
                deviceView
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    @ViewBuilder
    var appDevicesView: some View {
        if viewModel.state.localClientType == .app {
            if !viewModel.state.isConnected {
                Spacer()
            }

            serverDeviceView
        }
    }

    var footerView: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .foregroundColor(.white)
                    .frame(width: 38)
                Image(systemName: viewModel.state.avatarImageName)
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.gray)
            }

            VStack(alignment: .leading, spacing: 0) {
                Text(L10n.General.Label.appearAs)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                Text(viewModel.state.hostNames.local)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            Spacer()
        }
        .padding([.horizontal, .top], 16)
        .padding(.bottom, 10)
    }

    @ViewBuilder
    var deviceView: some View {
        if viewModel.state.isConnected {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .frame(width: 60, height: 60)
                        .foregroundColor(Colors.main)

                    Image(systemName: viewModel.state.deviceImageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 36, height: 36)
                        .foregroundColor(.white)

                    CircularProgressView(lineWidth: 2, progress: viewModel.state.transferProgress)
                        .frame(width: 70, height: 70)
                        .opacity(viewModel.state.isProgressBarHidden ? 0.0 : 1.0)
                }
                .onTapGesture { viewModel.didTapDevice() }

                Text(viewModel.state.hostNames.remote)
                    .font(.system(size: 12))
                    .foregroundColor(.primary)

                Text(viewModel.state.transferState.title)
                    .font(.system(size: 12))
                    .foregroundColor(viewModel.state.transferState.tintColor)
                    .opacity(viewModel.state.transferState != .none ? 1.0 : 0.0)
            }
        } else {
            HStack(spacing: 0) {
                Spacer()
                ProgressView()
                Spacer()
            }
            .padding(.vertical, 16)
        }
    }

    @ViewBuilder
    var infoCardView: some View {
        if viewModel.state.localClientType == .appExtension || !viewModel.state.isConnected {
            ZStack {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.General.Label.cantSeeYourDevice)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.secondary)

                        Text(L10n.General.Label.openAppOnMac)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .lineSpacing(4.0)
                    }

                    Image(systemName: viewModel.state.deviceImageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 50, height: 50)
                        .foregroundColor(.secondary).opacity(0.60)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
            }
            .background(.tertiary.opacity(0.25))
            .cornerRadius(9.0)
            .padding(.vertical, 16)
            .padding(.horizontal, 0)
        }
    }

    @ViewBuilder
    var serverDeviceView: some View {
        if viewModel.state.isConnected {
            let progress = viewModel.state.transferProgress
            ZStack {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.white)
                        Image(systemName: viewModel.state.deviceImageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 36, height: 36)
                            .foregroundColor(Colors.main)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.state.hostNames.remote)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.primary)

                        Text(viewModel.state.transferState.receiverTitle)
                            .font(.system(size: 14))
                            .foregroundColor(viewModel.state.transferState.tintColor)
                            .lineSpacing(4.0)

                        ProgressView(value: progress)
                            .animation(progress != 0.0 ? .easeIn : .none, value: progress)
                            .tint(Colors.main)
                            .padding(.top, 4)
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
            }
            .background(.tertiary.opacity(0.25))
            .cornerRadius(9.0)
            .padding([.top, .horizontal], 16)
        } else {
            ZStack {
                VStack(spacing: 16) {
                    ProgressView()
                    Text(L10n.General.Label.waitingForDevice)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 32)
            .padding(.bottom, 16)
        }
    }
}
