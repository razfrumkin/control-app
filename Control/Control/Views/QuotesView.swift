//
//  QuotesView.swift
//  Control
//
//  Created by Raz Frumkin on 04/10/2022.
//

import SwiftUI

// renders a given quote (usually used in .sheet)
struct DetailedQuoteView: View {
    @Binding var quote: Quote?
    var contentColor: Color
    var authorColor: Color
    
    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 10) {
                Text("\"\(quote!.content ?? "Unresolved quote")\"")
                    .font(.title.weight(.semibold))
                    .foregroundColor(contentColor)
                     Text("- \(quote!.author ?? "Unknown")")
                    .foregroundColor(authorColor)
                    .font(.body.italic()).bold()
            }
            .frame(width: 350)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// this view shows every quote liked by the user
struct LikedQuotesView: View {
    @StateObject var viewRouter: ViewRouter
    
    @Environment(\.managedObjectContext) private var context
    @State var quotes: FetchedResults<Quote>
    
    @State private var showDetailedLikedQuote: Bool = false
    @State private var detailedQuote: Quote?
        
    var body: some View {
        VStack {
            if quotes.atLeastOneLikedQuote {
                List {
                    ForEach(quotes) { quote in
                        if quote.isLiked {
                            Text("\"\(quote.content ?? "Unresolved quote")\"")
                                .lineLimit(1)
                                .onTapGesture {
                                    detailedQuote = quote
                                    showDetailedLikedQuote.toggle()
                                }
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            withAnimation {
                                quotes[index].isLiked = false
                            }
                        }
                    }
                }
            } else {
                Text("You haven't liked any quotes yet")
            }
        }
        .sheet(isPresented: $showDetailedLikedQuote, content: {
            DetailedQuoteView(quote: $detailedQuote, contentColor: .pink.opacity(0.9), authorColor: .pink.opacity(0.6))
        })
    }
}

// this view renders a random quote and allows the user to like it and view the LikedQuotesView
struct QuotesView: View {
    @StateObject var viewRouter: ViewRouter
    
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(sortDescriptors: []) private var quotes: FetchedResults<Quote>
    
    private let maximumLikedQuotes: Int = 10
    
    @State private var quoteIndex: Int = 0
    @State private var likedQuotesCount: Int = 0
    @State private var showMaximumLikedQuotesAlert = false
            
    var body: some View {
        NavigationView {
            VStack {
                /*Button("PREPOPULATE | (\(quotes.count) quote(s))") {
                    for quote in quotes {
                        context.delete(quote)
                    }
                    try? context.save()
                    UserDefaults.standard.set(true, forKey: "firstLaunch")
                    context.prepopulateQuotesData()
                }*/

                VStack(alignment: .leading, spacing: 10) {
                    Text("\"\(quotes[quoteIndex].content ?? "Unresolved quote")\"")
                        .font(.title.weight(.semibold))
                        .foregroundColor(.pink.opacity(0.9))
                    Text("- \(quotes[quoteIndex].author ?? "Unknown")")
                        .foregroundColor(.pink.opacity(0.6))
                        .font(.body.italic().bold())
                }
                .frame(width: 350, height: 400)
                .padding()
                
                HStack {
                    Button(action: {
                        withAnimation {
                            quoteIndex = randomQuoteIndex()
                        }
                    }, label: {
                        Image(systemName: "gobackward")
                            .foregroundColor(.pink)
                            .padding()
                    })
                    .background(.pink.opacity(0.1))
                    .cornerRadius(15)
                    
                    NavigationLink(destination: LikedQuotesView(viewRouter: viewRouter, quotes: quotes)
                        .environment(\.managedObjectContext, context)) {
                        HStack {
                            Image(systemName: "heart.square")
                            Text("Liked Quotes")
                        }
                        .foregroundColor(.pink)
                    }
                    .padding()
                    .background(.pink.opacity(0.1))
                    .cornerRadius(15)
                    
                    Button(action: {
                        if quotes[quoteIndex].isLiked {
                            withAnimation {
                                quotes[quoteIndex].isLiked.toggle()
                                
                                do {
                                    try context.save()
                                    likedQuotesCount -= 1
                                } catch {
                                    fatalError("Unresolved CoreData error: Could not unlike the quote")
                                }
                            }
                        } else if likedQuotesCount + 1 > maximumLikedQuotes {
                            showMaximumLikedQuotesAlert = true
                        } else {
                            withAnimation {
                                quotes[quoteIndex].isLiked.toggle()
                                
                                do {
                                    try context.save()
                                    likedQuotesCount += 1
                                } catch {
                                    fatalError("Unresolved CoreData error: Could not like the quote")
                                }
                            }
                        }
                    }, label: {
                        Image(systemName: quotes[quoteIndex].isLiked ? "heart.fill" : "heart")
                            .foregroundColor(.pink)
                            .padding()
                    })
                    .alert("You've hit the limit of liked quotes. (\(maximumLikedQuotes) quotes)", isPresented: $showMaximumLikedQuotesAlert) {
                        Button("Ok", role: .cancel) {
                            
                        }
                    }
                    .background(.pink.opacity(0.1))
                    .cornerRadius(15)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.theme.background)
            .onAppear {
                likedQuotesCount = 0
                for quote in quotes {
                    if quote.isLiked {
                        likedQuotesCount += 1
                    }
                }
            }
        }
        .onAppear {
            quoteIndex = .random(in: quotes.startIndex..<quotes.endIndex)
        }
    }
    
    // this function returns a random quote index that does not repeat itself
    private func randomQuoteIndex() -> Int {
        var randomInt = Int.random(in: quotes.startIndex..<(quotes.endIndex - 1))
        if randomInt == quoteIndex {
            randomInt = quotes.endIndex - 1
        }
        return randomInt
    }
}

struct QuotesView_Previews: PreviewProvider {
    static var previews: some View {
        let persistenceContainer = PersistenceController.shared
        
        QuotesView(viewRouter: ViewRouter())
            .environment(\.managedObjectContext, persistenceContainer.container.viewContext)
    }
}
