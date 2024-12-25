//
//  MenuBarView.swift
//  WireDrop
//
//  Created by Anton Meier on 2024-12-22.
//

import SwiftUI

// MARK: Initialization

struct MenuBarView: View {
    @Environment(\.openWindow) private var openWindow
    @StateObject var viewModel: MenuBarViewModel
}

// MARK: Body

extension MenuBarView {
    var body: some View {
        VStack(spacing: 8) {
            statusView
            Divider()
            buttons
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 14)
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
    }
}

// MARK: Views

private extension MenuBarView {
    @ViewBuilder
    var statusView: some View {
        ZStack {
            if viewModel.state.isConnected {
                deviceView
            } else {
                emptyDeviceView
            }
        }
        .frame(height: 48)
        .background(.tertiary.opacity(0.25))
        .cornerRadius(9.0)
        .padding(.all, 0)
    }

    var deviceView: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .frame(width: 28, height: 28)
                    .foregroundColor(.white)

                Image(systemName: viewModel.state.deviceImageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .fontWeight(.light)
                    .frame(height: 18)
                    .foregroundColor(Colors.main)
            }

            VStack(alignment: .leading, spacing: -6) {
                Text(viewModel.state.hostNames.remote)
                    .font(.system(size: 12))
                    .fontWeight(.regular)
                    .foregroundColor(.primary)

                ProgressView(value: viewModel.state.transferProgress)
                    .animation(viewModel.state.progressAnimationType, value: viewModel.state.transferProgress)
                    .tint(Colors.main)
                    .padding(.top, 4)
            }
            .padding(.top, 2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 14)
    }

    var emptyDeviceView: some View {
        HStack(spacing: 0) {
            Spacer()

            Text(L10n.General.Label.noDeviceAttached)
                .font(.system(size: 12))
                .fontWeight(.regular)
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding(.horizontal, 14)
    }

    var buttons: some View {
        VStack(spacing: 6) {
            sendFileButton
            quitButton
        }
    }

    var sendFileButton: some View {
        buttonView(
            text: L10n.General.Button.sendFile,
            isFocused: viewModel.state.focusState == .sendFile,
            onTap: {
                viewModel.didTapSendFile {
                    openWindow(id: $0)
                }
            },
            focusType: .sendFile
        )
    }

    var quitButton: some View {
        buttonView(
            text: L10n.General.Button.quit,
            isFocused: viewModel.state.focusState == .quit,
            onTap: viewModel.didTapQuit,
            focusType: .quit
        )
    }

    func buttonView(text: String, isFocused: Bool, onTap: @escaping () -> Void, focusType: MenuBarViewState.FocusState) -> some View {
        ZStack {
            Color.clear
                .overlay {
                    if isFocused {
                        ZStack {
                            Colors.main.opacity(0.5)
                        }
                        .cornerRadius(6.0)
                    }
                }
                .padding(.horizontal, -8)
                .padding(.vertical, -2)

            HStack(spacing: 0) {
                Text(text)
                    .font(.system(size: 13))
                    .fontWeight(.regular)
                    .foregroundColor(.primary)

                Spacer()
            }
        }
        .onTapGesture { onTap() }
        .onHover(perform: { viewModel.didChangeFocusState($0 ? focusType : .none) })
    }
}
