//
//  PlaylistListView.swift
//  Vibe
//
//  Created by cmStudent on 2025/06/02.
//

import SwiftUI

@MainActor
final class PlaylistItemViewModel: ObservableObject {
    @Published var allSongs: [DownloadedAudio] = []
    
    private let savedAudioUseCase: SavedAudioUseCase
    private let audioPlayerUseCase: AudioPlayerUseCase
    private let playlistUseCase: PlaylistUseCase
    
    
    init(
         savedAudioUseCase: SavedAudioUseCase,
         audioPlayerUseCase: AudioPlayerUseCase,
         playlistUseCase: PlaylistUseCase
    ) {

        self.savedAudioUseCase = savedAudioUseCase
        self.audioPlayerUseCase = audioPlayerUseCase
        self.playlistUseCase = playlistUseCase
    }
    
    func fetchAllSongs() async {
        do {
            self.allSongs = try await savedAudioUseCase.getSavedAudios()
        } catch {
            print("Error fetching all songs: \(error)")
        }
    }
    
}


struct PlaylistItemView: View {
    @StateObject private var vm: PlaylistItemViewModel
    var playlist: Playlist?
    var isNavigationLinkActive: Bool
    
    private var savedAudioUseCase: SavedAudioUseCase
    private var audioPlayerUseCase: AudioPlayerUseCase
    private var playlistUseCase: PlaylistUseCase
    
    init(
        playlist: Playlist? = nil,
        isNavigationLinkActive: Bool = true,
        savedAudioUseCase: SavedAudioUseCase,
        audioPlayerUseCase: AudioPlayerUseCase,
        playlistUseCase: PlaylistUseCase
    ) {
        self.playlist = playlist
        self.isNavigationLinkActive = isNavigationLinkActive
        
        self.savedAudioUseCase = savedAudioUseCase
        self.audioPlayerUseCase = audioPlayerUseCase
        self.playlistUseCase = playlistUseCase
        
        _vm = .init(wrappedValue: .init(
            savedAudioUseCase: savedAudioUseCase,
            audioPlayerUseCase: audioPlayerUseCase,
            playlistUseCase: playlistUseCase
        ))
    }


    var body: some View {
        ZStack {
            if isNavigationLinkActive {
                NavigationLink {
                    SongListView(
                        songs: playlist?.songs ?? vm.allSongs,
                        savedAudioUseCase: savedAudioUseCase,
                        audioPlayerUseCase: audioPlayerUseCase,
                        playlistUseCase: playlistUseCase
                    )
                } label: {
                    itemView
                }
            } else {
                itemView
            }
        }
        .task {
            await vm.fetchAllSongs()
        }
   
    }
    
    private var itemView: some View {
        HStack {
            Image(systemName: "music.note.list")
            VStack(alignment: .leading, spacing: 4) {
                Text(playlist?.name ?? "All songs")
                    .font(.headline)
                    .foregroundStyle(.black)
            }
            
            Spacer()
            
        }
        .padding(.horizontal)
    }
}

