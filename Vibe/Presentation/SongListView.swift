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
    @Published var songsInPlaylist: [DownloadedAudio] = []
    var playlistType: PlaylistType
    
    let savedAudioUseCase: SavedAudioUseCase
    let audioPlayerUseCase: AudioPlayerUseCase
    let playlistUseCase: PlaylistUseCase
    
    private var cancellables = Set<AnyCancellable>()
    
    init(
        playlistType: PlaylistType = .all,
        savedAudioUseCase: SavedAudioUseCase,
        audioPlayerUseCase: AudioPlayerUseCase,
        playlistUseCase: PlaylistUseCase
    ) {
        self.playlistType = playlistType
        
        self.savedAudioUseCase = savedAudioUseCase
        self.audioPlayerUseCase = audioPlayerUseCase
        self.playlistUseCase = playlistUseCase

        setupBindings()
        Task {
            await getPlaylists()
            await loadSongsFromPlaylist()
        }

    }
    
    
    func loadSongsFromPlaylist() async {
        do {
            self.songsInPlaylist = try await savedAudioUseCase.getSavedAudios(playlistType: self.playlistType)
        } catch {
            print("Error loading songs from playlist: \(error.localizedDescription)")
        }
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
        audioPlayerUseCase.updateCurrentPlaylistSongs(playlistType: playlistType)
        
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
            audioPlayerUseCase.updateAllSongsList()
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
        await savedAudioUseCase.addToPlaylist(song, to: playlist)
    }
}

struct SongListView: View {

    @State private var selectedSongToAddToPlaylist: DownloadedAudio? = nil
    @StateObject private var vm: SongListViewModel
    
    init(
        playListType: PlaylistType,
        selectedSongToAddToPlaylist: DownloadedAudio? = nil,
        savedAudioUseCase: SavedAudioUseCase,
        audioPlayerUseCase: AudioPlayerUseCase,
        playlistUseCase: PlaylistUseCase
    ) {
        self.selectedSongToAddToPlaylist = selectedSongToAddToPlaylist
        _vm = .init(
            wrappedValue: .init(
                playlistType: playListType,
                savedAudioUseCase: savedAudioUseCase,
                audioPlayerUseCase: audioPlayerUseCase,
                playlistUseCase: playlistUseCase
            )
        )
    }
    
    var body: some View {
        List {
            ForEach(vm.songsInPlaylist) { audio in
                Button {
                    vm.playAudio(audio)
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
                item: $selectedSongToAddToPlaylist,content: { song in
                    playListSelectionSheet(song: song)
                })
        }
        .listStyle(.plain)
                    
                    
        
        
        

    }
}


extension SongListView {
    
    @ViewBuilder
    private func playListSelectionSheet(song: DownloadedAudio) -> some View {
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
                            playlistType: .playlist(playlist),
                            isNavigationLinkActive: false,
                            savedAudioUseCase: vm.savedAudioUseCase,
                            audioPlayerUseCase: vm.audioPlayerUseCase,
                            playlistUseCase: vm.playlistUseCase
                        )
                    }
                    
                }
                
            }
            .listStyle(.plain)
            .navigationTitle("Add to playlist")
            
        }
        Spacer()
    }
}

#Preview {
    @Previewable
    @Environment(\.container) var container
    SongListView(
        playListType: .all,
        savedAudioUseCase: container.savedAudioUseCase,
        audioPlayerUseCase: container.audioPlayerUseCase,
        playlistUseCase: container.playlistUseCase
    )
}
