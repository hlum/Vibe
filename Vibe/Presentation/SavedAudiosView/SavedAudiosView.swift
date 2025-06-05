//
//  SavedAudiosView.swift
//  Vibe
//
//  Created by cmStudent on 2025/05/28.
//

import SwiftUI
import SwiftData
import AVFoundation

struct SavedAudiosView: View {
    @Query private var savedAudios: [DownloadedAudio]
    @StateObject private var vm: SavedAudiosViewModel
    
    @Binding var downloadingProcesses: [DownloadingProcess]
    @State private var showPlaylistAddAlert: Bool = false
    
    private let savedAudioUseCase: SavedAudioUseCase
    private let audioPlayerUseCase: AudioPlayerUseCase
    private let playlistUseCase: PlaylistUseCase
    
    @Binding var floatingPlayerIsPresented: Bool
    
    init(
        savedAudioUseCase: SavedAudioUseCase,
        audioPlayerUseCase: AudioPlayerUseCase,
        playlistUseCase: PlaylistUseCase,
        downloadingProcesses: Binding<[DownloadingProcess]>,
        floatingPlayerIsPresented: Binding<Bool>
    ) {
        _vm = .init(wrappedValue: SavedAudiosViewModel(
            savedAudioUseCase: savedAudioUseCase,
            audioPlayerUseCase: audioPlayerUseCase,
            playlistUseCase: playlistUseCase
        ))
        self.savedAudioUseCase = savedAudioUseCase
        self.audioPlayerUseCase = audioPlayerUseCase
        self.playlistUseCase = playlistUseCase
        
        _downloadingProcesses = downloadingProcesses
        _floatingPlayerIsPresented = floatingPlayerIsPresented
    }
    
    var body: some View {
        List {
            
            if !downloadingProcesses.isEmpty {
                DownloadingProcessView(downloadingProcesses: $downloadingProcesses)
            }
            
            PlaylistItemView(
                playlistType: .all,
                savedAudioUseCase: savedAudioUseCase,
                audioPlayerUseCase: audioPlayerUseCase,
                playlistUseCase: playlistUseCase,
                floatingViewShowing: $floatingPlayerIsPresented
            )
            
            ForEach(vm.playlists) { playlist in
                PlaylistItemView(
                    playlistType: .playlist(playlist),
                    savedAudioUseCase: savedAudioUseCase,
                    audioPlayerUseCase: audioPlayerUseCase,
                    playlistUseCase: playlistUseCase,
                    floatingViewShowing: $floatingPlayerIsPresented
                )
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button {
                        Task {
                            await vm.deletePlaylist(playlist)
                        }
                    } label: {
                        Text("Delete")
                    }
                    .tint(.red)
                }
            }
            
        }
        .navigationTitle("Saved Audios")
        .navigationBarTitleDisplayMode(.large)
        
        .toolbar(content: {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showPlaylistAddAlert.toggle()
                } label: {
                    HStack {
                        Image(systemName:"plus.circle")
                        Text("Add Playlist")
                    }
                    .font(.headline)
                }
                
            }
        })
        .overlay(alignment: .center) {
            if showPlaylistAddAlert {
                CustomAlertView(present: $showPlaylistAddAlert, inputText: $vm.playlistName,title: "Enter playlist name" , placeholder: "Playlist name", confirmAction: {
                    Task {
                        await vm.addPlaylist()
                    }
                })
            }
        }
        .padding(.bottom, floatingPlayerIsPresented ? 100 : 0)
        .task {
            await vm.getPlaylists()
        }
        .listStyle(.plain)
        
    }
}




#Preview {
    @Previewable
    @Environment(\.container) var container
    NavigationStack {
        SavedAudiosView(
            savedAudioUseCase: container.savedAudioUseCase,
            audioPlayerUseCase: container.audioPlayerUseCase, playlistUseCase: container.playlistUseCase,
            downloadingProcesses: .constant(DownloadingProcess.dummyData()), floatingPlayerIsPresented: .constant(false)
        )
    }
}
