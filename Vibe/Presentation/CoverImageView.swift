//
//  CoverImageView.swift
//  Vibe
//
//  Created by cmStudent on 2025/06/06.
//

import SwiftUI

struct CoverImageView: View {
    var imgURL: String
    var body: some View {
        if imgURL.starts(with: "http") {
            imgWithAsyncImage(imgURL)
        } else {
            imgFromLocal(imgURL)
        }
    }
    
    @ViewBuilder
    private func imgFromLocal(_ url: String) -> some View {
        if let uiImage = UIImage(contentsOfFile: url) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 50, height: 50)
                .cornerRadius(10)
        } else {
            placeHolderImageView
        }
    }
    
    private func imgWithAsyncImage(_ url: String) -> some View {
        AsyncImage(url: URL(string: url)) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 50, height: 50)
                .cornerRadius(10)
        } placeholder: {
            placeHolderImageView
        }

    }
    
    private var placeHolderImageView: some View  {
        Image(systemName: "music.note")
            .foregroundStyle(.dartkModeBlack)
            .font(.system(size: 30))
            .foregroundColor(.black)
            .frame(width: 50, height: 50)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(10)
    }
}

#Preview {
    CoverImageView(imgURL: "")
}
