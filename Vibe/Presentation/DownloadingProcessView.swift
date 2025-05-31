//
//  DownloadingProcessView.swift
//  Vibe
//
//  Created by cmStudent on 2025/05/31.
//

import SwiftUI

struct DownloadingProcessView: View {
    @Binding var downloadingProcesses: [DownloadingProcess]
    var body: some View {
        ForEach(downloadingProcesses) { process in
            VStack(alignment: .leading, spacing: 5) {
                Text(process.fileName)
                    .font(.headline)
                HStack {
                    ProgressView(value: process.progress)
                    Text("\(process.progress * 100, specifier: "%.1f") %")
                }
                //                        let text = "\(process.expectedByte/1024, specifier: "%.1f")mb"
                Text("\(process.finishedByte/102400 , specifier: "%.1f")mb / \(process.expectedByte/102400 , specifier: "%.1f")mb")
                
            }
            .padding(.horizontal)
        }
    }
}

#Preview {
    DownloadingProcessView(downloadingProcesses: .constant(DownloadingProcess.dummyData()))
}
