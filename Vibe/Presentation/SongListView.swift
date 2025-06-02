//
//  SongListView.swift
//  Vibe
//
//  Created by cmStudent on 2025/06/02.
//

import SwiftUI
import Combine

@MainActor
final class SongListViewModel: ObservableObject {
    @Published var currentPlaybackTime: Double = 0
    @Published var isPlaying: Bool = false
    @Published var currentAudio: DownloadedAudio?
    @Published var isLooping: Bool = false
    @Published var playlists: [Playlist] = []

    
    let savedAudioUseCase: SavedAudioUseCase
    let audioPlayerUseCase: AudioPlayerUseCase
    let playlistUseCase: PlaylistUseCase
    
    private var cancellables = Set<AnyCancellable>()
    
    init(
        savedAudioUseCase: SavedAudioUseCase,
        audioPlayerUseCase: AudioPlayerUseCase,
        playlistUseCase: PlaylistUseCase
    ) {
        self.savedAudioUseCase = savedAudioUseCase
        self.audioPlayerUseCase = audioPlayerUseCase
        self.playlistUseCase = playlistUseCase
        
        setupBindings()
    }
    
    private func setupBindings() {
        // Bind to audio player use case publishers
        audioPlayerUseCase.currentPlaybackTimePublisher
            .assign(to: &$currentPlaybackTime)
        
        audioPlayerUseCase.isPlayingPublisher
            .assign(to: &$isPlaying)
        
        audioPlayerUseCase.currentAudioPublisher
            .assign(to: &$currentAudio)
            
        audioPlayerUseCase.isLoopingPublisher
            .assign(to: &$isLooping)
    }
    
    func seekToTime(_ seconds: Double) {
        audioPlayerUseCase.seek(to: seconds)
    }
    
    func playAudio(_ audio: DownloadedAudio) {
        if currentAudio?.id == audio.id {
            if isPlaying {
                pauseAudio()
            } else {
                resumeAudio()
            }
        } else {
            audioPlayerUseCase.play(audio)
        }
    }
    
    func pauseAudio() {
        print("ViewModel: Pausing audio")
        audioPlayerUseCase.pause()
    }
    
    func resumeAudio() {
        print("ViewModel: Resuming audio")
        audioPlayerUseCase.resume()
    }
    
    func playNext() {
        audioPlayerUseCase.playNext()
    }
    
    func playPrevious() {
        audioPlayerUseCase.playPrevious()
    }
    
    func toggleLoop() {
        audioPlayerUseCase.toggleLoop()
    }
    
    func delete(_ audio: DownloadedAudio) async {
        do {
            if currentAudio?.id == audio.id {
                audioPlayerUseCase.stop()
            }
            try await savedAudioUseCase.deleteAudio(audio)
            audioPlayerUseCase.updatePlaylist()
        } catch {
            print("Error deleting audio: \(error.localizedDescription)")
        }
    }
}


// MARK: Playlist stuffs
extension SongListViewModel {
    
    
    func getPlaylists() async {
        self.playlists = await playlistUseCase.getAllPlaylists()
    }
    
    func deletePlaylist(_ playlist: Playlist) async {
        await playlistUseCase.deletePlaylist(playlist)
        await self.getPlaylists()
    }
    
    
    func addSongToPlaylist(_ song: DownloadedAudio, _ playlist: Playlist) async {
        await playlistUseCase.addSong(song, to: playlist)
        await savedAudioUseCase.addToPlaylist(song, to: playlist)
    }
}

struct SongListView: View {
    var songs: [DownloadedAudio]

    @State private var selectedSongToAddToPlaylist: DownloadedAudio?
    @StateObject private var vm: SongListViewModel
    
    init(
        songs: [DownloadedAudio],
        selectedSongToAddToPlaylist: DownloadedAudio? = nil,
        savedAudioUseCase: SavedAudioUseCase,
        audioPlayerUseCase: AudioPlayerUseCase,
        playlistUseCase: PlaylistUseCase
    ) {
        self.songs = songs
        self.selectedSongToAddToPlaylist = selectedSongToAddToPlaylist
        _vm = .init(
            wrappedValue: .init(
                savedAudioUseCase: savedAudioUseCase,
                audioPlayerUseCase: audioPlayerUseCase,
                playlistUseCase: playlistUseCase
            )
        )
    }
    
    var body: some View {
        List {
            ForEach(songs) { audio in
                Button {
                    if vm.currentAudio?.id == audio.id {
                        if vm.isPlaying {
                            vm.pauseAudio()
                        } else {
                            vm.resumeAudio()
                        }
                    } else {
                        vm.playAudio(audio)
                    }
                    
                } label: {
                    AudioItemRow(
                        currentPlaybackTime: $vm.currentPlaybackTime,
                        audio: audio,
                        isPlaying: vm.currentAudio?.id == audio.id && vm.isPlaying
                    )
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    
                    Button {
                        Task {
                            await vm.delete(audio)
                        }
                    } label: {
                        Text("Delete")
                    }
                    .tint(.red)
                    
                    
                    Button {
                        selectedSongToAddToPlaylist = audio
                    } label: {
                        Image(systemName: "text.badge.plus")
                    }
                    .tint(.green)

                }
            }
            .sheet(
                item: $selectedSongToAddToPlaylist,
                content: { song in
                    NavigationStack {
                        List {
                            ForEach(vm.playlists) { playlist in
                                Button {
                                    Task {
                                        await vm.addSongToPlaylist(song, playlist)
                                        selectedSongToAddToPlaylist = nil
                                    }
                                }label: {
                                    PlaylistItemView(
                                        playlist: playlist,
                                        isNavigationLinkActive: false,
                                        savedAudioUseCase: vm.savedAudioUseCase,
                                        audioPlayerUseCase: vm.audioPlayerUseCase,
                                        playlistUseCase: vm.playlistUseCase
                                    )
                                }
                                .buttonStyle(.plain)
                                
                            }
                            
                        }
                        .listStyle(.plain)
                        .navigationTitle("Add to playlist")
                        
                    }
                    
                Spacer()
                
            })
        }
        .listStyle(.plain)
                    
                    
        .task {
            await vm.getPlaylists()
        }
        

    }
}


#Preview {
    @Previewable
    @Environment(\.container) var container
    SongListView(
        songs: [],
        savedAudioUseCase: container.savedAudioUseCase,
        audioPlayerUseCase: container.audioPlayerUseCase,
        playlistUseCase: container.playlistUseCase
    )
}
