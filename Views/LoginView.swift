//
//  LoginView.swift
//  music
//
//  Created by Anel Torić on 24. 4. 2026.
//

import SwiftUI

struct LoginView: View {

    @EnvironmentObject var auth: AuthManager
    @Environment(\.modelContext) private var context
    @State var user = ""
    @State var pass = ""

    var body: some View {
        NavigationStack{
            ZStack{
                ZStack {
                            LinearGradient(
                                colors: [
                                    .black,
                                    Color(red: 0.08, green: 0.05, blue: 0.15),
                                    Color(red: 0.02, green: 0.02, blue: 0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .ignoresSafeArea()

                            Circle()
                                .fill(.purple.opacity(0.25))
                                .frame(width: 300)
                                .blur(radius: 100)
                                .offset(x: -120, y: -250)

                            Circle()
                                .fill(.cyan.opacity(0.18))
                                .frame(width: 250)
                                .blur(radius: 100)
                                .offset(x: 140, y: 250)
                        }
                VStack(spacing: 30) {

                                   Spacer()

                                   VStack(spacing: 14) {

                        Image(systemName: "music.note.list")
                                    .font(.system(size: 70))
                                    .foregroundStyle(
                                LinearGradient(
                                            colors: [.purple, .pink],
                                                   startPoint: .topLeading,
                                                   endPoint: .bottomTrailing
                                               )
                                           )

                        Text("Music")
                                           .font(.system(size: 42, weight: .bold))
                                           .foregroundStyle(.white)

                    Text("Stream your favorite songs")
                                           .foregroundStyle(.gray)
                                   }
                    
                    
                    VStack(spacing: 18) {
                        
                        HStack(spacing: 14) {
                        Image(systemName: "person.fill")
                            .foregroundStyle(.gray)

                        TextField("Username", text: $user)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .foregroundStyle(.white)
                    }
                    .padding()
                    .background(.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(.white.opacity(0.08), lineWidth: 1)
                    )
                        HStack(spacing: 14) {
                                    Image(systemName: "lock.fill")
                                        .foregroundStyle(.gray)

                                    SecureField("Password", text: $pass)
                                        .textInputAutocapitalization(.never)
                                        .autocorrectionDisabled()
                                        .foregroundStyle(.white)
                                }
                                .padding()
                                .background(.white.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18)
                                        .stroke(.white.opacity(0.08), lineWidth: 1)
                                )

                                            
                                        }
                                        .padding(.horizontal)

                    
                    Button {
                                            auth.login(
                                                username: user,
                                                password: pass
                                            )
                                        } label: {
                                            Text("Login")
                                                .font(.headline)
                                                .foregroundStyle(.black)
                                                .frame(maxWidth: .infinity)
                                                .padding()
                                                .background(
                                                    LinearGradient(
                                                        colors: [.green, .mint],
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    )
                                                )
                                                .clipShape(RoundedRectangle(cornerRadius: 18))
                                                .shadow(color: .green.opacity(0.4), radius: 10)
                                        }
                                        .padding(.horizontal)
                    NavigationLink {
                                            RegisterView()
                                        } label: {
                                            HStack(spacing: 8) {
                                                Image(systemName: "plus.circle.fill")
                                                Text("Create Account")
                                            }
                                            .foregroundStyle(.white)
                                            .padding()
                                            .frame(maxWidth: .infinity)
                                            .background(.white.opacity(0.08))
                                            .clipShape(RoundedRectangle(cornerRadius: 18))
                                        }
                                        .padding(.horizontal)

                                        Spacer()
                }
            }
            
        }
    }
}
