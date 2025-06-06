//
//  MusicVisualizerView.swift
//  Vibe
//
//  Created by cmStudent on 2025/05/31.
//

import SwiftUI
import Combine

class MusicVisualizerViewModel: ObservableObject {
    @Published var barHeights: [CGFloat]
    private var timer: AnyCancellable?
    private let maxHeight: CGFloat
    private let numberOfBars: Int

    init(numberOfBars: Int = 7, maxHeight: CGFloat = 50) {
        self.numberOfBars = numberOfBars
        self.maxHeight = maxHeight
        self.barHeights = Array(repeating: maxHeight * 0.4, count: numberOfBars)
        startTimer()
    }

    private func startTimer() {
        timer = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.barHeights = (0..<self.numberOfBars).map { _ in
                        CGFloat.random(in: self.maxHeight * 0.1...self.maxHeight)
                    }
                }
            }
    }

    deinit {
        timer?.cancel()
    }
}


struct MusicVisualizerView: View {
    @StateObject private var viewModel: MusicVisualizerViewModel
    let width: CGFloat
    let height: CGFloat

    init(width: CGFloat = 30, height: CGFloat = 20) {
        self.width = width
        self.height = height
        _viewModel = StateObject(wrappedValue: MusicVisualizerViewModel(maxHeight: height))
    }

    var body: some View {
        let spacing: CGFloat = 1
        let barCount = viewModel.barHeights.count
        let barWidth = (width - (CGFloat(barCount - 1) * spacing)) / CGFloat(barCount)

        HStack(spacing: spacing) {
            ForEach(viewModel.barHeights.indices, id: \.self) { index in
                Rectangle()
                    .foregroundStyle(.darkModeWhite)
                    .frame(width: barWidth, height: viewModel.barHeights[index])
                    .cornerRadius(2)
            }
        }
        .frame(width: width, height: height, alignment: .bottom)
    }
}


#Preview {
    ZStack {
        Color.red
        MusicVisualizerView(width: 30, height: 20)
    }
}

