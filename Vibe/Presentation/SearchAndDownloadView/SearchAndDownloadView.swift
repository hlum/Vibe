//
//  SearchAndDownloadView.swift
//  Vibe
//
//  Created by cmStudent on 2025/05/28.
//

import SwiftUI

struct SearchAndDownloadView: View {
    @State private var showFileNameInputAlert: Bool = false
    @State private var fileName: String = ""
    @Binding var youtubeURL: String
    @Binding var downloadingProcesses: [DownloadingProcess]
    let download: (_ fileName: String) -> Void
    var body: some View {
        VStack {
            TextField("Input youtube url", text: $youtubeURL)
                .padding()
                .frame(maxWidth: .infinity)
                .frame(height: 55)
                .background(.gray.opacity(0.2))
                .cornerRadius(10)
                .padding()
                .padding(.bottom, 20)
            
            
            ScrollView {
                Text("\(downloadingProcesses.count)")
                ForEach(downloadingProcesses) { process in
                    VStack(alignment: .leading, spacing: 20) {
                        Text(process.fileName)
                            .font(.headline)
                        HStack {
                            ProgressView(value: process.progress)
                            Text("\(process.progress * 100, specifier: "%.1f") %")
                        }
//                        let text = "\(process.expectedByte/1024, specifier: "%.1f")mb"
                        Text("\(process.finishedByte/102400 , specifier: "%.1f")mb")
                        Text("\(process.expectedByte/102400 , specifier: "%.1f")mb")

                    }
                    
                    .frame(minHeight: 55)
                    .padding()
                    
                    Divider()
                }
            }
            
            Spacer()
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showFileNameInputAlert.toggle()
                }
            } label: {
                Text("Download")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .frame(height: 55)
                    .background(.blue)
                    .cornerRadius(10)
                    .padding()
                    .foregroundStyle(.white)
            }
            
        }
        .overlay(alignment: .center) {
            if showFileNameInputAlert {
                fileNameInputView
            }
        }
    }

}


extension SearchAndDownloadView {
    private var fileNameInputView: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text(NSLocalizedString("File Name", comment: ""))
                    .font(.title2.bold())
                Spacer()
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showFileNameInputAlert = false
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.gray)
                        .contentTransition(.symbolEffect(.replace))
                }
            }
            .padding(.horizontal)
            
            // Input Section
            VStack(alignment: .leading, spacing: 8) {
                Text(NSLocalizedString("Input the file name to save", comment: ""))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                HStack {
                    TextField(NSLocalizedString("Enter file name", comment: ""), text: $fileName)
                    .font(.title2.bold())
                    .textFieldStyle(.plain)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .padding(.horizontal)
            
            // Action Buttons
            HStack(spacing: 16) {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showFileNameInputAlert = false
                    }
                } label: {
                    Text(NSLocalizedString("Cancel", comment: ""))
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundStyle(.red)
                        .cornerRadius(12)
                }
                
                Button {
                    download(fileName)
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showFileNameInputAlert = false
                    }
                } label: {
                    Text(NSLocalizedString("Save", comment: ""))
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
        )
        .padding(.horizontal, 24)
        .transition(.scale.combined(with: .opacity))

    }
    
}

#Preview {
    SearchAndDownloadView(youtubeURL: .constant(""), downloadingProcesses: .constant(DownloadingProcess.dummyData()), download: {fileName in })
}
