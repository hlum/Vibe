//
//  CustomAlertView.swift
//  Vibe
//
//  Created by cmStudent on 2025/06/02.
//

import SwiftUI

struct CustomAlertView: View {
    @Binding var present: Bool
    @Binding var inputText: String
    
    var title: String = "Input the file name to save"
    var placeholder: String = "Enter the file name"
    var confirmAction: (() -> Void)
    
    var body: some View {
        
        VStack(spacing: 20) {
            // Header
            HStack {
                Text(NSLocalizedString("File Name", comment: ""))
                    .font(.title2.bold())
                Spacer()
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        present = false
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
                Text(NSLocalizedString(title, comment: ""))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                HStack {
                    TextField(NSLocalizedString(placeholder, comment: ""), text: $inputText)
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
                        present = false
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
                    confirmAction()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        present = false
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
    CustomAlertView(present: .constant(true), inputText: .constant(""), confirmAction: {})
}
