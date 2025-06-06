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
//    @Published var isLooping: Bool = false
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
            
//        audioPlayerUseCase.isLoopingPublisher
//            .assign(to: &$isLooping)
    }
    
    func seekToTime(_ seconds: Double) {
        audioPlayerUseCase.seek(to: seconds)
    }
    
    func playAudio(_ audio: DownloadedAudio) async {
        await audioPlayerUseCase.updateCurrentPlaylistSongs(playlistType: playlistType)
        
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
    
//    func toggleLoop() {
//        audioPlayerUseCase.toggleLoop()
//    }
    
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
    @Binding private var floatingPlayerIsPresented: Bool
    init(
        playListType: PlaylistType,
        selectedSongToAddToPlaylist: DownloadedAudio? = nil,
        savedAudioUseCase: SavedAudioUseCase,
        audioPlayerUseCase: AudioPlayerUseCase,
        playlistUseCase: PlaylistUseCase,
        floatingPlayerIsPresented: Binding<Bool>
    ) {
        self.selectedSongToAddToPlaylist = selectedSongToAddToPlaylist
        _floatingPlayerIsPresented = floatingPlayerIsPresented
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
                    Task {
                        await vm.playAudio(audio)
                    }
                } label: {
                    AudioItemRow(
                        currentPlaybackTime: $vm.currentPlaybackTime,
                        audio: audio,
                        isPlaying: vm.currentAudio?.id == audio.id && vm.isPlaying
                    )
                }
                .swipeActions(edge: .leading, allowsFullSwipe: true, content: {
                    Button {
                        selectedSongToAddToPlaylist = audio
                    } label: {
                        Image(systemName: "text.badge.plus")
                    }
                    .tint(.green)
                })
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button {
                        Task {
                            await vm.delete(audio)
                            await vm.loadSongsFromPlaylist()
                        }
                    } label: {
                        Text("Delete")
                    }
                    .tint(.red)
                }
            }
        }
        .padding(.bottom, floatingPlayerIsPresented ? 100 : 0)
        .listStyle(.plain)
        .sheet(item: $selectedSongToAddToPlaylist) { song in
            playListSelectionSheet(song: song)
        }
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
                            playlistUseCase: vm.playlistUseCase,
                            floatingViewShowing: $floatingPlayerIsPresented
                        )
                    }
                    
                }
                
            }
            .listStyle(.plain)
            .navigationTitle("Add to playlist")
            .padding(.bottom, floatingPlayerIsPresented ? 100 : 0)
            
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
        playlistUseCase: container.playlistUseCase, floatingPlayerIsPresented: .constant(false)
    )
}
