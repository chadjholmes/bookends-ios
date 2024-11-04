import SwiftUI

struct LandingView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                        .environment(\.symbolVariants, selectedTab == 0 ? .fill : .none)
                    Text("Home")
                }
                .tag(0)
            
            BookshelfView()
                .tabItem {
                    Image(systemName: "books.vertical.fill")
                        .environment(\.symbolVariants, selectedTab == 1 ? .fill : .none)
                    Text("Bookshelf")
                }
                .tag(1)
            
            InsightsView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                        .environment(\.symbolVariants, selectedTab == 2 ? .fill : .none)
                    Text("Insights")
                }
                .tag(2)
                
            GoalsView()
                .tabItem {
                    Image(systemName: "target")
                        .environment(\.symbolVariants, selectedTab == 3 ? .fill : .none)
                    Text("Goals")
                }
                .tag(3)
        }
        .tint(.purple)
        .edgesIgnoringSafeArea(.bottom)
    }
}

struct LandingView_Previews: PreviewProvider {
    static var previews: some View {
        LandingView()
    }
}
