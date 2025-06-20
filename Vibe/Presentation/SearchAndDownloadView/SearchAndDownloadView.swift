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
    @State private var imgURLOfSelectedVideo: String = ""
    @Binding var keyWord: String
    @Binding var searchResults: [YoutubeSearchItem]
    
    
    let download: (_ fileName: String, _ imgURL: String) -> Void
    let search: () -> Void
    let loadMore: () -> Void
    
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
                .onSubmit {
                    if !keyWord.isEmpty {
                        search()
                    }
                }
                .padding()
                    
            ScrollView {
                LazyVStack {
                    ForEach(searchResults, id: \.id.uniqueID) { result in
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
                                imgURLOfSelectedVideo = result.snippet.thumbnail.medium.url
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
                        .onAppear {
                            if result.id.videoId == searchResults.last?.id.videoId {
                                loadMore()
                            }
                        }
                        Divider()
                    }
                }
            }
            .padding(.bottom,showingFloatingPanel ? 100 : 0)

        }
        .overlay(alignment: .center) {
            if showFileNameInputAlert {
                CustomAlertView(present: $showFileNameInputAlert, inputText: $fileName) {
                    download(fileName, imgURLOfSelectedVideo)
                }
            }
        }
    }

}

#Preview {
    SearchAndDownloadView(keyWord: .constant("asd"), searchResults: .constant(YoutubeSearchItem.getDummyItems()), download: {fileName, imgURL in },search: {},loadMore:{}, showingFloatingPanel: false)
}
