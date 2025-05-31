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
    @Binding var keyWord: String
    @Binding var searchResults: [YoutubeSearchItem]
    
    
    let download: (_ fileName: String) -> Void
    let search: () -> Void
    
    let showingFloatingPanel: Bool

    
    var body: some View {
        VStack {
            let keyWordIsURL = URL(string: keyWord.trimmingCharacters(in: .whitespacesAndNewlines))?.scheme?.hasPrefix("http") == true

            TextField("Input keyword or url", text: $keyWord)
                .padding()
                .frame(maxWidth: .infinity)
                .frame(height: 55)
                .background(.gray.opacity(0.2))
                .cornerRadius(10)
                .overlay(alignment: .trailing) {
                    if keyWordIsURL {
                        ZStack {
                            Button {
                                showFileNameInputAlert = true
                            } label: {
                                Image(systemName: "arrow.down.circle.fill")
                                    .font(.title)
                                    .tint(.white)
                            }
                        }
                        .frame(width: 40, height: 40)
                        .background(.blue)
                        .cornerRadius(30)
                        .shadow(color: .gray.opacity(0.9), radius: 4, x: 0, y: 0)
                        .padding(.trailing)
                        
                    } else {
                        if !keyWord.isEmpty {
                            Button {
                                keyWord = ""
                            } label: {
                                Image(systemName: "x.circle")
                                    .font(.headline)
                                    .tint(.red)
                                    .padding(.trailing)
                                    .frame(width: 50, height: 50)
                            }

                        }
                    }
                }
                .onSubmit {
                    search()
                }
                .padding()
                    
            ScrollView {
                ForEach(searchResults, id: \.id.videoId) { result in
                    HStack {
                        AsyncImage(url: URL(string: result.snippet.thumbnail.medium.url), content: { image in
                            image
                                .resizable()
                                .scaledToFit()
                        }, placeholder: {
                            ProgressView()
                                .progressViewStyle(.circular)
                        })
                        .frame(width: 80, height: 80)
                        .cornerRadius(10)
                        .padding(.horizontal)
                        VStack {
                            Text(result.snippet.title)
                        }
                        
                        Spacer()
                        
                        Button {
                            fileName = result.snippet.title
                            showFileNameInputAlert.toggle()
                            keyWord = result.id.getYoutubeURL()
                        } label: {
                            ZStack {
                                Image(systemName: "arrow.down.circle.fill")
                                    .font(.title)
                                    .tint(.white)
                            }
                            .frame(width: 40, height: 40)
                            .background(.blue)
                            .cornerRadius(30)
                            .shadow(color: .gray.opacity(0.9), radius: 4, x: 0, y: 0)
                            .padding(.trailing, 20)
                        }
                        
                    }
                    Divider()
                }
            }
            .padding(.bottom,showingFloatingPanel ? 100 : 0)

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
    SearchAndDownloadView(keyWord: .constant("asd"), searchResults: .constant(YoutubeSearchItem.getDummyItems()), download: {fileName in },search: {}, showingFloatingPanel: false)
}
